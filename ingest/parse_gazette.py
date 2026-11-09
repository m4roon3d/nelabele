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
import sys
from collections import Counter

NUMBER = re.compile(r"^\d[\d,]*(\.\d+)?$")
ENGLISH_RUN = re.compile(r"[A-Za-z0-9][A-Za-z0-9 .,()/&'+:-]*[A-Za-z)]")
SUB_ROW = re.compile(r"\bSY\.?\s*NOS?\b|ADJACENT|ABBET|ABUTT|RESIDENTIAL OTHER|^[A-C]\)", re.I)
FRONTAGE = re.compile(r"\bNH\b|\bN\.?\s?H\b|\bSH\b|HIGHWAY|\bROAD\b|\bRD\b|\bMAIN\b", re.I)
APARTMENT = re.compile(r"APARTMENT|RESIDENCY|RESIDENCE|HEIGHTS|TOWERS?\b|FLATS?\b", re.I)
HEADER_WORDS = re.compile(r"^(village|area|road|name|hobli|ward|sl|no|property|id|division|block|sy|[/ .])+$", re.I)


def english_name(cells):
    """Longest run of plain English text in the row, ignoring legacy-font junk."""
    best = ""
    for c in cells:
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


def classify(name, nums):
    """Return a list of (property_type, rate, unit, level) or a reason to skip."""
    n = len(nums)
    land = nums[:3]
    if SUB_ROW.search(name):
        return "road-frontage sub-row"
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
    ap.add_argument("--district", required=True, choices=["Bangalore Urban", "Bangalore Rural"])
    ap.add_argument("--section", action="append", required=True,
                    help="page range and taluk/SRO, e.g. 12-68:Nelamangala")
    ap.add_argument("--skipped", help="optional CSV listing skipped rows for review")
    args = ap.parse_args()

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
    with open(args.raw_csv, newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        next(reader)
        for row in reader:
            page = int(row[0])
            taluk = taluk_for(page)
            cells = [c.strip() for c in row[2:]]
            if taluk is None or not cells or not cells[0].isdigit():
                continue
            body = cells[1:]
            name = english_name(body)
            if not name:
                reasons["no English name"] += 1
                skipped.append([page, "no English name"] + body)
                continue
            result = classify(name, numbers(body))
            if isinstance(result, str):
                reasons[result] += 1
                skipped.append([page, result, name] + body)
                continue
            for ptype, rate, unit, level in result:
                key = (taluk, name.lower(), ptype)
                if key in seen:  # repeated listing: keep the first, which is the main row
                    reasons["duplicate"] += 1
                    continue
                seen.add(key)
                out.append({
                    "district": args.district, "area_name": name, "area_level": level,
                    "parent_name": taluk, "parent_level": "taluk",
                    "property_type": ptype, "approval_status": "",
                    "rate": f"{rate:.0f}", "unit": unit,
                    "source_ref": f"{taluk} SRO gazette p.{page}",
                })

    fields = ["district", "area_name", "area_level", "parent_name", "parent_level",
              "property_type", "approval_status", "rate", "unit", "source_ref"]
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
