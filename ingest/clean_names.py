"""Tidy place names left messy by PDF extraction, in parsed guidance CSVs.

Strips list numbering ("1. K R Road No" -> "K R Road"), survey-number and
building-spec tails, and broken brackets; drops rows whose name is only a
fragment ("B+G+4Uf)", "Appartment", "Area)"), and layout site rates a quarter
or less of their own village's, which are misprints (Elite Woods,
Doddacheemanahalli: 1,400 against the village's 8,500). Rewrites the files in place and
reports what changed, so it can be re-run safely.

  python ingest/clean_names.py data/guidance/*.csv
"""
import csv
import re
import sys

GENERIC = re.compile(
    r"^(app?artments?|flats?|sites?|layouts?|roads?|cross|main|blocks?|stages?|phases?|village|others?|"
    r"remaining|all|addition|areas?|agrahara|extension|extention|new addition|residential|commercial|"
    r"property|survey|nos?|ward|street|lane)\.?$",
    re.I,
)
FRAGMENT = re.compile(
    r"^(temple|side|mill|berry|row house|near slum|new list|commercial|measuring\b.*|house|part|bearing|"
    r"charted|society|adjacent|kote|to to to)$",
    re.I,
)
BUILDING_SPEC = re.compile(r"\b[BSG](?:\s*\+\s*[BSGU0-9]+)+\s*U\s*F\b|\bB\+G\b|\bS\+G\b", re.I)


def clean(name: str) -> str | None:
    n = " ".join(name.split())
    n = re.sub(r"\(\s*rate fixed by cvc\s*\)", "", n, flags=re.I)
    n = re.sub(r",?\s*RERA\b.*$", "", n, flags=re.I)
    n = re.sub(r"(.)\1{4,}", r"\1", n)                       # "sssssss"
    if BUILDING_SPEC.search(n) and len(re.findall(r"[A-Za-z]", BUILDING_SPEC.sub("", n))) < 4:
        return None
    n = re.sub(r"^[A-Za-z]\)\s*", "", n)                       # "A) Nithesh"
    n = re.sub(r"\s+no\.?(?=\s*\()", "", n, flags=re.I)        # "Road No (west)"
    n = re.sub(r"^\d{1,2}\s*[.)]\s*(?=[A-Za-z])", "", n)       # "1. K R Road", "4.JCRoad"
    n = re.sub(r"^\d{1,2}\s*[.)]\s*(?=\d)", "", n)            # "2.9 Main Road" -> "9 Main Road"
    # survey numbers / plot numbers at the end: "Bellandur Sy No", "Belmar layout Sy no 12/3"
    n = re.sub(r"[\s,(]*\b(adjacent\s+)?(sy|survey|s)\.?\s*n(o|os|umbers?)\b.*$", "", n, flags=re.I)
    # trailing "No", "Road No", "ward No", "(west) No"
    for _ in range(3):
        n = re.sub(r"\s+(ward\s+)?no\.?$", "", n, flags=re.I).strip()
    n = re.sub(r"\(\s*\)", "", n)
    # a bracketed list of survey numbers: "Eco Springs Layout (33/2 (P), 34/2 (P), ..."
    m = re.search(r"\(\s*\d+/\d", n)
    if m and len(re.findall(r"[A-Za-z]", n[: m.start()])) >= 4:
        n = n[: m.start()]
    # unbalanced brackets: cut an unclosed "(" tail, drop a stray ")"
    if n.count("(") > n.count(")"):
        head = n[: n.rfind("(")].strip(" ,-:&")
        n = head if len(re.findall(r"[A-Za-z]", head)) >= 4 else n.replace("(", "")
    if n.count(")") > n.count("("):
        # tail of a bracket that started on the line before: "Bhoopasandra)" -> "Bhoopasandra"
        n = n.replace(")", "", n.count(")") - n.count("("))
    # RERA / plan-approval numbers left as the whole name: "No.PRM/KA", "Prm/Ka"
    if re.fullmatch(r"(no\.?\s*)?prm\s*/\s*ka\b.*", n, flags=re.I):
        return None
    # an approval reference in front of the developer: "BBMP/Addl.Dir/JD NORTH/0318/11-12 M/s X"
    n = re.sub(r"^[A-Z]{2,}/\S*(\s+[A-Z]+)?/[\w/.-]*\s+(?=M/s)", "", n, flags=re.I)
    # developer prefix: "M/s Union Holdings", "M/S. D.X Max properties"
    n = re.sub(r"^M\s*/\s*s\.?\s+", "", n, flags=re.I)
    # survey rows: "Dombarahalli Sy" -> "Dombarahalli (survey nos.)"; "...NagaraPID Nos" -> "...Nagara"
    n = re.sub(r"\s*PID\s*Nos?\.?$", "", n)
    n = re.sub(r"\s+Sy\.?$", " (survey nos.)", n, flags=re.I)
    n = re.sub(r"\bAparment\b", "Apartment", n, flags=re.I)
    # words run together by the PDF reader: "JaimaruthiNagara" -> "Jaimaruthi Nagara"
    n = re.sub(r"(?<=[a-z]{3})(?=(Nagara?|Layout|Road|Palya|Halli|Pura|Block|Stage|Colony|Extension|Gardens?)\b)", " ", n)
    n = re.sub(r"(?<=[a-z]{4})(?=[A-Z][a-z]{3,})", " ", n)
    n = " ".join(n.split()).strip(" ,-:&.;/")
    # the tail of a name that wrapped from the line above
    if re.match(r"^(nagara?|operative|toll gate|than)\b", n, flags=re.I):
        return None
    if n[:1].islower() and re.search(r"[A-Za-z]{3}", n):     # "pride crosswinds layout"
        n = n[:1].upper() + n[1:]
    letters = len(re.findall(r"[A-Za-z]", n))
    if (letters < 4 or GENERIC.match(n) or FRAGMENT.match(n) or re.fullmatch(r"[\W\d]*", n)
            or re.match(r"^(to|and|of)\b", n)):                    # lowercase: a cut-off line
        return None
    if re.fullmatch(r"[a-z]{5,}", n):                          # "sonnapura" -> "Sonnapura"
        n = n.capitalize()
    return n


RENAMES = {}   # (district, parent, old name) -> new name


def follow_renames():
    """Carry renames over to the map points and boundaries, so places stay on the map."""
    import json
    from pathlib import Path
    pts = Path("data/geo/area_points.csv")
    if pts.exists():
        with open(pts, newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            fields, rows = reader.fieldnames, list(reader)
        n = 0
        for r in rows:
            new = RENAMES.get((r["district"], r["parent_name"], r["area_name"]))
            if new:
                r["area_name"], n = new, n + 1
        with open(pts, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=fields)
            w.writeheader()
            w.writerows(rows)
        print(f"{pts}: {n} map points renamed to match")
    b = Path("data/geo/village_boundaries.geojson")
    if b.exists():
        d = json.loads(b.read_text(encoding="utf-8"))
        n = 0
        for feat in d["features"]:
            p = feat["properties"]
            new = RENAMES.get((p["district"], p["parent_name"], p["area_name"]))
            if new:
                p["area_name"], n = new, n + 1
        b.write_text(json.dumps(d, separators=(",", ":")), encoding="utf-8")
        print(f"{b}: {n} boundaries renamed to match")


def main(paths):
    for path in paths:
        if path.endswith("effective_dates.csv"):
            continue
        with open(path, newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            fields, rows = reader.fieldnames, list(reader)
        village_rate = {(r["parent_name"], r["area_name"]): float(r["rate"]) for r in rows
                        if r["area_level"] == "village" and r["property_type"] == "plot"}
        out, changed, dropped = [], 0, 0
        for r in rows:
            v = village_rate.get((r["parent_name"], r.get("context") or ""))
            if (r["area_level"] == "locality" and r["property_type"] == "plot" and v
                    and r["parent_level"] != "zone"   # city slums are rightly cheap
                    and float(r["rate"]) <= v / 4):
                print(f"  misprint? {r['area_name']} {r['rate']} vs village {r['context']} {v:.0f}: dropped")
                dropped += 1
                continue
            new = clean(r["area_name"])
            if new is None:
                dropped += 1
                continue
            if new != r["area_name"]:
                changed += 1
                RENAMES[(r["district"], r["parent_name"], r["area_name"])] = new
                r["area_name"] = new
            out.append(r)
        with open(path, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=fields)
            w.writeheader()
            w.writerows(out)
        print(f"{path}: {changed} renamed, {dropped} dropped, {len(out)} kept")
    if RENAMES:
        follow_renames()


if __name__ == "__main__":
    main(sys.argv[1:])
