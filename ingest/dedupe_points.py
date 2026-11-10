"""
NelaBele – drop map points that landed on a same-named village in another taluk.

Village names repeat across taluks (there are Sulakuntes in Devanahalli,
Nelamangala and Chikkaballapura), and a fuzzy match can pull a village onto
its near-namesake (Hoskote's Nagarenahalli onto Doddaballapur's
Nagadenahalli). When one point is claimed by places from different
taluks/offices, only the office(s) whose centre is nearest keep it; the rest
are left off the map (they still show in the list). City zones, which sit
side by side, are left alone.

Run after geocode.py (which also calls it):
  python ingest/dedupe_points.py data/geo/area_points.csv
"""

import csv
import math
import statistics
import sys
from collections import defaultdict

SLACK_KM = 8          # offices this much farther than the nearest one lose the point
CITY = "Bangalore Urban"  # city zones are small and side by side: left alone
TRUSTED = {"exact", "kannada"}


def km(a, b):
    return math.hypot((a[0] - b[0]) * 111.0, (a[1] - b[1]) * 111.0 * math.cos(math.radians(a[0])))


def dedupe(rows):
    """rows: dicts with district, parent_name, lat, lon, match. Returns (kept, dropped)."""
    # each office's centre: the median of its exactly matched places
    pts = defaultdict(list)
    for r in rows:
        if r["match"] in TRUSTED:
            pts[(r["district"], r["parent_name"])].append((float(r["lat"]), float(r["lon"])))
    centre = {k: (statistics.median(p[0] for p in v), statistics.median(p[1] for p in v))
              for k, v in pts.items() if len(v) >= 5}

    by_point = defaultdict(list)
    for r in rows:
        if r["district"] != CITY:
            by_point[(r["lat"], r["lon"])].append(r)
    drop = set()
    for (lat, lon), group in by_point.items():
        offices = {(r["district"], r["parent_name"]) for r in group}
        if len(offices) < 2 or any(o not in centre for o in offices):
            continue
        pt = (float(lat), float(lon))
        dist = {o: km(pt, centre[o]) for o in offices}
        best = min(dist.values())
        for r in group:
            if dist[(r["district"], r["parent_name"])] > best + SLACK_KM:
                drop.add(id(r))
    return [r for r in rows if id(r) not in drop], [r for r in rows if id(r) in drop]


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    path = sys.argv[1]
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        fields, rows = reader.fieldnames, list(reader)
    kept, dropped = dedupe(rows)
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(kept)
    print(f"Dropped {len(dropped)} point(s) claimed by a nearer office's place of the same name")
    for r in dropped[:15]:
        print(f"  {r['parent_name']}: {r['area_name']} (sat on {r['osm_name']})")


if __name__ == "__main__":
    main()
