"""
NelaBele – shift census village outlines onto the map.

The 2011 Census village boundaries (DataMeet) sit 0.5-1.3 km off true
position in most of our districts: only 15-50% of OpenStreetMap's village
points fell inside their own village's outline (Ramanagara, 83%, was the
exception), and the error is a near-constant shift within each area.

For each taluk/zone, this measures the median offset from a village's
outline centre to its OpenStreetMap point (villages geocode.py matched by
exact name, unambiguous, within 4 km) and moves that taluk's outlines by it.
Taluks with fewer than 8 such villages use their district's offset. Rerun
after boundaries.py; it measures afresh each time, so a second run moves
little.

  python ingest/align_boundaries.py data/geo/village_boundaries.geojson data/geo/area_points.csv
"""

import csv
import json
import math
import statistics
import sys
from collections import defaultdict

from shapely.affinity import translate
from shapely.geometry import Point, mapping, shape

MIN_PAIRS = 8
MAX_KM = 4.0
TRUSTED = {"exact", "kannada"}


def km(a, b):
    return math.hypot((a[0] - b[0]) * 111.0, (a[1] - b[1]) * 111.0 * math.cos(math.radians(a[0])))


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    bpath, ppath = sys.argv[1:]
    data = json.load(open(bpath, encoding="utf-8"))
    osm = {}
    for r in csv.DictReader(open(ppath, encoding="utf-8")):
        if r["match"] in TRUSTED:
            osm[(r["district"], r["parent_name"], r["area_name"])] = (float(r["lat"]), float(r["lon"]))

    pairs = defaultdict(list)          # (district, taluk) -> [(dlat, dlon)]
    feats = []
    for f in data["features"]:
        p = f["properties"]
        g = shape(f["geometry"])
        feats.append((f, g))
        o = osm.get((p["district"], p["parent_name"], p["area_name"]))
        if not o:
            continue
        c = g.centroid
        if km((c.y, c.x), o) <= MAX_KM:
            pairs[(p["district"], p["parent_name"])].append((o[0] - c.y, o[1] - c.x))

    def med(v):
        return statistics.median(a for a, _ in v), statistics.median(b for _, b in v)

    by_district = defaultdict(list)
    for (d, _), v in pairs.items():
        by_district[d].extend(v)
    shift_d = {d: med(v) for d, v in by_district.items() if len(v) >= MIN_PAIRS}
    shift = {k: med(v) for k, v in pairs.items() if len(v) >= MIN_PAIRS}

    before = after = tested = 0
    for f, g in feats:
        p = f["properties"]
        dlat, dlon = shift.get((p["district"], p["parent_name"])) or shift_d.get(p["district"], (0.0, 0.0))
        moved = translate(g, xoff=dlon, yoff=dlat)
        o = osm.get((p["district"], p["parent_name"], p["area_name"]))
        if o:
            pt = Point(o[1], o[0])
            tested += 1
            before += g.contains(pt)
            after += moved.contains(pt)
        f["geometry"] = mapping(moved)
        p["shift_m"] = [round(dlat * 111000), round(dlon * 111000 * math.cos(math.radians(g.centroid.y)))]

    json.dump(data, open(bpath, "w", encoding="utf-8"), separators=(",", ":"))
    print(f"Shifted {len(feats)} outlines using {len(shift)} taluk and {len(shift_d)} district offsets")
    if tested:
        print(f"OSM village points inside their own outline: {before / tested:.0%} before, {after / tested:.0%} after")
    for (d, t), (a, b) in sorted(shift.items(), key=lambda kv: -abs(kv[1][0]) - abs(kv[1][1]))[:8]:
        print(f"  {d} / {t}: {a * 111:+.2f} km N, {b * 108.4:+.2f} km E ({len(pairs[(d, t)])} villages)")


if __name__ == "__main__":
    main()
