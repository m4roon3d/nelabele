"""
NelaBele – turn a raw guidance value gazette extract into loader CSV.

Works on the CSV written by extract_pdf_tables.py for the 2023 Karnataka
guidance value gazettes. Kannada text in these PDFs uses legacy fonts and
can't be read, so rows are identified by their English names and the shape
of their numbers:

  5 numbers  village: dry / wet / garden land (₹ lakh per acre),
             then site in gramathana / site in approved layout (₹ per sq m)
  4 numbers  village: 3 land rates + 1 site rate
  3 numbers  village: land rates only (road/highway frontage sub-rows skipped)
  2 numbers  town area: site and apartment (₹ per sq m)
  1 number   town area: site (₹ per sq m), or apartment if the name says so

City gazettes (--mode city) list roads under block or locality headings,
with a site rate and an apartment rate (₹ per sq m) in fixed columns. Road
rows are rolled up into their heading (median), apartment complexes too, so
each locality gets one plot and one apartment rate. Commercial and
industrial rates are skipped. Rows with 3+ numbers are villages, as above.

--town-rollup: town streets printed only in Kannada can't be named, but
their site rates still describe the town, so they become one "<office>
Town" area with the median rate.

Stored per area:
  agricultural_land – dry land rate (the base rate), per acre
  plot              – approved-layout site rate, else gramathana site rate
  apartment         – where given, per sq m of super built-up area

Usage:
  python parse_gazette.py raw/bengaluru_rural_2023.csv rates.csv \\
      --district "Bangalore Rural" \\
      --section 12-68:Nelamangala --section 69-101:Doddaballapur \\
      --section 102-168:Devanahalli --section 169-234:Hoskote
"""

import argparse
import csv
import re
import statistics
import sys

import nudi
from collections import Counter

NUMBER = re.compile(r"^\d[\d,]*(\.\d+)?$")
ENGLISH_RUN = re.compile(r"[A-Za-z0-9][A-Za-z0-9 .,()/&'+:-]*[A-Za-z)]")
SUB_ROW = re.compile(r"\bSY\.?\s*NOS?\b|ADJACENT|ABBET|ABUTT|RESIDENTIAL OTHER|^[A-C]\)", re.I)
FRONTAGE = re.compile(r"\bNH\b|\bN\.?\s?H\b|\bSH\b|HIGHWAY|\bROAD\b|\bRD\b|\bMAIN\b", re.I)
APARTMENT = re.compile(r"APARTMENT|RESIDENCY|RESIDENCE|HEIGHTS|TOWERS?\b|FLATS?\b", re.I)
ROADLIKE = re.compile(r"\b(road|rd|cross|main|street|st|lane|circle|avenue|marg|beedi|others?)\b|^[(\d]", re.I)
PROJECT = re.compile(r"apartment|\bapts?\b|residency|enclave|heights|towers?\b|\bpid\b|khata|katha|villas?\b|"
                     r"projects?\b|infrastructure|developers|builders|\bphase\b|\bsite no|\b0\d\d-|w0\d", re.I)
APT_HINT = re.compile(r"apartment|\bapts?\b|flats?\b|residency|towers?\b|heights", re.I)
VILLAGE_SUB = re.compile(r"survey numbers?|identified|attached|attach to|abutting|pheri|periph|near to|\bland\b$", re.I)
NOT_RESIDENTIAL = re.compile(r"commercial|industrial|kiadb|office space", re.I)
HEADER_WORDS = re.compile(r"^(village|area|road|name|hobli|ward|sl|no|property|id|division|block|sy|[/ .])+$", re.I)


CID = re.compile(r"\(cid:\d+\)")
# Plausible ₹ per sq m for city rows; anything outside is a misread column
CITY_BOUNDS = {"plot": (3000, 600000), "apartment": (15000, 400000)}


def english_name(cells):
    """Longest run of plain English text in the row, ignoring legacy-font junk."""
    best = ""
    for c in cells:
        c = CID.sub(" ", c)
        if NUMBER.match(c):
            continue
        for m in ENGLISH_RUN.finditer(c):
            run = m.group(0).strip(" .,-")
            start, end = m.span()
            # legacy-font Kannada also uses ASCII letters, but always mixed with
            # accented Latin-1 characters right next to them
            neighbours = c[max(0, start - 1):start] + c[end:end + 1]
            if any(ord(ch) > 127 for ch in neighbours) and not re.search(r"[A-Za-z]{3,} [A-Za-z]{3,}", run):
                continue
            letters = sum(ch.isalpha() for ch in run)
            if letters >= 4 and len(run) > len(best):
                best = run
    best = re.sub(r"\s+", " ", best)
    # letter-spaced text ("M a in R o a d", "P r a s h a n t h a N a g a r"): close it up
    toks = best.split()
    if len(toks) >= 4 and sum(bool(re.fullmatch(r"[A-Za-z]{1,2}", t)) for t in toks) >= 0.6 * len(toks):
        best = re.sub(r"(?<=[a-z])(?=[A-Z])", " ", "".join(toks))
    if "cid:" in best:
        return ""
    # "Balaji gold city ( 96/3, 96/7, ..." → "Balaji gold city"; a bare list of
    # property IDs or survey numbers ("16-3-520-19A,16-3-520-23C") is no name
    if sum(ch.isdigit() for ch in best) > sum(ch.isalpha() for ch in best):
        head = re.split(r"\s*(?:\(|,|\b(?:S\.?\s*No|Sy\.?\s*No|Survey|Sserve|Khata)\b)", best, maxsplit=1)[0]
        head = re.sub(r"[\s\d/.-]+$", "", head).strip()
        if sum(ch.isalpha() for ch in head) >= 4 and sum(ch.isdigit() for ch in head) <= sum(ch.isalpha() for ch in head):
            return head.title() if head.isupper() else head
        return ""
    if not best or HEADER_WORDS.match(best):
        return ""
    return best.title() if best.isupper() else best


def numbers(cells):
    out = []
    for c in cells:
        c = c.strip()
        if NUMBER.match(c):
            v = float(c.replace(",", ""))
            if v > 0:
                out.append(v)
    return out


ACRE_RUPEES = False  # --acre-rupees: land rates printed in ₹ per acre, not ₹ lakh per acre


def classify(name, nums):
    """Return a list of (property_type, rate, unit, level) or a reason to skip."""
    n = len(nums)
    land = nums[:3]
    if SUB_ROW.search(name):
        # a layout named with its survey numbers ("Air Port City-1 Sy No. 67, 70") carrying
        # a site rate is a place, not a roadside land sub-row
        layout = (re.search(r"\bSY\.?\s*NOS?\b", name, re.I)
                  and not re.search(r"ADJACENT|ABB?ET|ABUTT|RESIDENTIAL|\bNEAR\b|^ROAD|ATTACHED|LANDS?\b|^\W*SY", name, re.I)
                  and 1 <= n <= 2 and all(v >= 1000 for v in nums))
        if not layout:
            return "road-frontage sub-row"
    if ACRE_RUPEES:
        # 2023 district gazettes (Tumakuru, Kolar, Chikkaballapura): dry / wet / garden
        # land in ₹ per acre (e.g. 400000 500000 600000), then site rates in ₹ per sq m
        if n >= 3 and all(v >= 20000 for v in land) and land[0] <= land[1] <= land[2]:
            sites = [v for v in nums[3:] if 100 <= v < min(land[0] / 10, 60000)]
            if n == 3 and FRONTAGE.search(name):
                return "road-frontage sub-row"
            out = [("agricultural_land", land[0], "acre", "village")]
            if sites:
                out.append(("plot", sites[-1], "sqm", "village"))
            return out
        if n <= 2 and max(nums, default=0) >= 200000:
            return "land along a road (per acre)"
        if n <= 2 and max(nums, default=0) > 60000:
            return "implausible value"   # far above any town site rate here; likely a land rate
        if n == 2 and not 3000 <= nums[1] <= 60000:
            return [("plot", nums[0], "sqm", "locality")]
    if n >= 3 and all(v < 1000 for v in land):
        if n == 3:
            if FRONTAGE.search(name):
                return "road-frontage sub-row"
            return [("agricultural_land", land[0] * 100000, "acre", "village")]
        if n in (4, 5):
            sites = [v for v in nums[3:] if v >= 1000]
            out = [("agricultural_land", land[0] * 100000, "acre", "village")]
            if sites:
                out.append(("plot", sites[-1], "sqm", "village"))
            return out
    if n == 2 and all(v >= 1000 for v in nums):
        return [("plot", nums[0], "sqm", "locality"),
                ("apartment", nums[1], "sqm", "locality")]
    if n == 1 and nums[0] >= 1000:
        kind = "apartment" if APARTMENT.search(name) else "plot"
        return [(kind, nums[0], "sqm", "locality")]
    return f"unrecognised shape ({n} numbers)"


def main():
    ap = argparse.ArgumentParser(description="Gazette extract → loader CSV")
    ap.add_argument("raw_csv")
    ap.add_argument("out_csv")
    ap.add_argument("--district", required=True, choices=["Bangalore Urban", "Bangalore Rural", "Ramanagara", "Tumakuru", "Kolar", "Chikkaballapura"])
    ap.add_argument("--section", action="append", required=True,
                    help="page range and taluk/SRO, e.g. 12-68:Nelamangala")
    ap.add_argument("--parent-level", default="taluk",
                    help="level of the --section areas: taluk (rural SROs) or zone (city SROs)")
    ap.add_argument("--mode", choices=["rural", "city"], default="rural",
                    help="city: roll road rows up into their locality heading")
    ap.add_argument("--town-rollup", action="store_true",
                    help="roll Kannada-only town street rows (one site rate, no English name) "
                         "into a '<office> Town' area")
    ap.add_argument("--acre-rupees", action="store_true",
                    help="land rates are in ₹ per acre (district gazettes), not ₹ lakh per acre")
    ap.add_argument("--skipped", help="optional CSV listing skipped rows for review")
    args = ap.parse_args()
    global ACRE_RUPEES
    ACRE_RUPEES = args.acre_rupees

    sections = []
    for s in args.section:
        pages, taluk = s.split(":", 1)
        first, last = (int(x) for x in pages.split("-"))
        sections.append((first, last, taluk.strip()))

    def taluk_for(page):
        for first, last, taluk in sections:
            if first <= page <= last:
                return taluk
        return None

    out, skipped, reasons = [], [], Counter()
    seen = set()
    groups = {}            # (taluk, locality, type) -> [(rate, page)]
    heading = {}           # taluk -> current locality heading (city mode)
    context = {}           # (taluk, area) -> the heading it was listed under, a map-location hint

    def slot_values(body, name):
        """Site and apartment values from the two columns after the name."""
        key = name.lower()[:12]
        idx = next((i for i, c in enumerate(body) if key and key in c.lower()), None)
        if idx is None:
            return None
        vals = []
        for c in body[idx + 1:idx + 3]:
            c = c.strip()
            vals.append(float(c.replace(",", "")) if NUMBER.match(c) and float(c.replace(",", "")) > 0 else None)
        while len(vals) < 2:
            vals.append(None)
        return vals
    last_village = {}
    with open(args.raw_csv, newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        next(reader)
        for row in reader:
            page = int(row[0])
            taluk = taluk_for(page)
            cells = [c.strip() for c in row[2:]]
            if taluk is None or not cells:
                continue
            if not cells[0]:
                # many gazettes print village serial numbers one column to the right
                i = next((k for k, c in enumerate(cells) if c), None)
                if i is not None and i <= 2 and cells[i].isdigit():
                    cells = cells[i:]
            if args.mode == "city" and not cells[0].isdigit():
                h = english_name(cells[1:])
                if (h and not numbers(cells[1:]) and not PROJECT.search(h) and not ROADLIKE.search(h)
                        and not re.search(r"village|area name|hobli|apt|flat|layout road", h, re.I)):
                    heading[taluk] = h
                continue
            if ACRE_RUPEES:
                # Madhugiri style: "465 | Amaravathi" heading, then "Gramatana and Others Sy.No's"
                # (or "<village> Gramatana & Others") rows carrying that village's rates
                lead = cells[1:] if cells[0].isdigit() else cells
                nm = english_name(lead)
                nums_here = numbers(lead)
                if cells[0].isdigit() and nm and not nums_here:
                    last_village[taluk] = nm
                m = re.match(r"^(.*?)\s*grama?th?ana\s*(and|&)\s*other", nm or "", re.I)
                if m and len(nums_here) >= 3:
                    village = m.group(1).strip(" ,.-") or last_village.get(taluk)
                    if village:
                        cells = ["0", village] + [f"{v:.0f}" for v in nums_here]
                        reasons["village from heading"] += 1
            if not cells[0].isdigit():
                continue
            body = cells[1:]
            name = english_name(body)
            if not name and args.town_rollup:
                nums = numbers(body)
                if len(nums) == 1 and 1000 <= nums[0] <= 600000:
                    groups.setdefault((taluk, f"{taluk} Town", "plot"), []).append((nums[0], page))
                    reasons["rolled into town"] += 1
                    continue
            name_kn = ""
            if not name:
                # Kannada-only row in the old Nudi font: recover the name from Kannada
                for c in body:
                    kn = nudi.to_unicode(c)
                    if kn:
                        if nudi.SUB_ROW_KN.search(kn):
                            kn = None
                        break
                else:
                    kn = None
                if kn and len(numbers(body)) >= 3:
                    name_kn, name = kn, nudi.to_english(kn)
                    reasons["name read from Kannada"] += 1
            if not name:
                reasons["no English name"] += 1
                skipped.append([page, "no English name"] + body)
                continue
            nums = numbers(body)
            if args.mode == "city":
                # peri-urban village rows mix site rates (₹/sq m) with farmland
                # (₹ lakh/acre) in one row: tell them apart by size
                key = name.lower()[:12]
                idx = next((i for i, c in enumerate(body) if key and key in c.lower()), None)
                after = numbers(body[idx + 1:]) if idx is not None else nums
                small = [v for v in after if 5 <= v < 1000]
                large = [v for v in after if v >= 1000]
                if small and not PROJECT.search(name):
                    if NOT_RESIDENTIAL.search(name):
                        reasons["commercial/industrial"] += 1
                        continue
                    if SUB_ROW.search(name) or FRONTAGE.search(name) or VILLAGE_SUB.search(name):
                        reasons["road-frontage sub-row"] += 1
                        continue
                    result = [("agricultural_land", small[0] * 100000, "acre", "village")]
                    if large:
                        result.append(("plot", max(large), "sqm", "village"))
                    for ptype, rate, unit, level in result:
                        key2 = (taluk, name.lower(), ptype)
                        if key2 in seen:
                            reasons["duplicate"] += 1
                            continue
                        if unit == "sqm" and not CITY_BOUNDS["plot"][0] <= rate <= CITY_BOUNDS["plot"][1]:
                            reasons["implausible value"] += 1
                            continue
                        seen.add(key2)
                        out.append({
                            "district": args.district, "area_name": name, "name_kn": "", "area_level": level,
                            "context": "", "parent_name": taluk, "parent_level": args.parent_level,
                            "property_type": ptype, "approval_status": "",
                            "rate": f"{rate:.0f}", "unit": unit,
                            "source_ref": f"{taluk} SRO gazette p.{page}",
                        })
                    reasons["peri-urban village row"] += 1
                    continue
            if args.mode == "city" and len(nums) < 3:
                if NOT_RESIDENTIAL.search(name):
                    reasons["commercial/industrial"] += 1
                    continue
                slots = slot_values(body, name)
                if slots and any(v is not None for v in slots):
                    site, apt = slots
                    group = heading.get(taluk)
                    if PROJECT.search(name):
                        # a named project or a khata/PID entry: only useful rolled into its locality
                        if not group:
                            reasons["project with no locality heading"] += 1
                            continue
                        vals = [v for v in (site, apt) if v is not None and v >= 1000]
                        if vals:
                            ptype = "apartment" if (APT_HINT.search(name) or apt is not None) else "plot"
                            groups.setdefault((taluk, group, ptype), []).append((vals[-1], page))
                        continue
                    if site is not None and site >= 1000:
                        target = group if group and (ROADLIKE.search(name) or SUB_ROW.search(name)) else name
                        if group and target == name:
                            context[(taluk, name)] = group
                        groups.setdefault((taluk, target, "plot"), []).append((site, page))
                    if apt is not None and apt >= 1000:
                        target = group or name
                        groups.setdefault((taluk, target, "apartment"), []).append((apt, page))
                    continue
            result = classify(name, nums)
            if args.mode == "city" and not isinstance(result, str) and PROJECT.search(name):
                group = heading.get(taluk)
                if not group:
                    reasons["project with no locality heading"] += 1
                    continue
                for ptype, rate, unit, _ in result:
                    if unit == "sqm":
                        groups.setdefault((taluk, group, ptype), []).append((rate, page))
                continue
            if isinstance(result, str):
                reasons[result] += 1
                skipped.append([page, result, name] + body)
                continue
            for ptype, rate, unit, level in result:
                if args.mode == "city" and unit == "sqm":
                    lo, hi = CITY_BOUNDS.get(ptype, (0, float("inf")))
                    if not lo <= rate <= hi:
                        reasons["implausible value"] += 1
                        continue
                key = (taluk, name.lower(), ptype)
                if key in seen:  # repeated listing: keep the first, which is the main row
                    reasons["duplicate"] += 1
                    continue
                seen.add(key)
                out.append({
                    "district": args.district, "area_name": name, "name_kn": name_kn, "area_level": level,
                    "context": heading.get(taluk, "") if args.mode == "city" else "",
                    "parent_name": taluk, "parent_level": args.parent_level,
                    "property_type": ptype, "approval_status": "",
                    "rate": f"{rate:.0f}", "unit": unit,
                    "source_ref": f"{taluk} SRO gazette p.{page}",
                })

    for (taluk, area, ptype), vals in groups.items():
        lo, hi = CITY_BOUNDS.get(ptype, (0, float("inf")))
        kept = [(v, p) for v, p in vals if lo <= v <= hi]
        if len(kept) < len(vals):
            reasons["implausible value"] += len(vals) - len(kept)
        if not kept:
            continue
        vals = kept
        key = (taluk, area.lower(), ptype)
        if key in seen:
            reasons["duplicate"] += 1
            continue
        seen.add(key)
        rates = sorted(v for v, _ in vals)
        out.append({
            "district": args.district, "area_name": area, "name_kn": "", "area_level": "locality",
            "context": context.get((taluk, area), ""),
            "parent_name": taluk, "parent_level": args.parent_level,
            "property_type": ptype, "approval_status": "",
            "rate": f"{statistics.median(rates):.0f}", "unit": "sqm",
            "source_ref": f"{taluk} SRO gazette p.{vals[0][1]}"
                          + (f" (median of {len(rates)})" if len(rates) > 1 else ""),
        })

    fields = ["district", "area_name", "name_kn", "area_level", "parent_name", "parent_level",
              "property_type", "approval_status", "rate", "unit", "source_ref", "context"]
    with open(args.out_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(out)
    if args.skipped:
        with open(args.skipped, "w", newline="", encoding="utf-8") as f:
            csv.writer(f).writerows(skipped)

    by_type = Counter(r["property_type"] for r in out)
    by_taluk = Counter(r["parent_name"] for r in out)
    print(f"{len(out)} rates for {len({(r['parent_name'], r['area_name']) for r in out})} areas")
    print("  by type:  " + ", ".join(f"{k} {v}" for k, v in sorted(by_type.items())))
    print("  by taluk: " + ", ".join(f"{k} {v}" for k, v in sorted(by_taluk.items())))
    print("Skipped: " + (", ".join(f"{k} {v}" for k, v in reasons.most_common()) or "none"))


if __name__ == "__main__":
    sys.exit(main())
