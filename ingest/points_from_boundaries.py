"""
NelaBele – put villages on the map from their census boundary.

geocode.py places areas by matching names to OpenStreetMap; many villages
have no OSM place node but did match a 2011 Census boundary
(boundaries.py). Those get a point inside their boundary, marked
match = "village boundary". Re-run after geocode.py and boundaries.py:

  python ingest/points_from_boundaries.py data/geo/village_boundaries.geojson data/geo/area_points.csv
"""

import csv
import glob
import json
import sys

import math
import statistics
from collections import defaultdict

from shapely.geometry import shape

FAR_KM = 10     # an OSM point this far from the village's boundary is the wrong place
TALUK_KM = 45   # a point this far from its taluk's villages is the wrong place
CITY = "Bangalore Urban"


def km(a, b):
    return math.hypot((a[0] - b[0]) * 111.0, (a[1] - b[1]) * 111.0 * math.cos(math.radians(a[0])))


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    bpath, ppath = sys.argv[1:]
    with open(ppath, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        fields, rows = reader.fieldnames, list(reader)
    have = {(r["district"], r["parent_name"], r["area_name"]): r for r in rows}
    added = moved = 0
    feats = json.load(open(bpath, encoding="utf-8"))["features"]
    for feat in feats:
        p = feat["properties"]
        key = (p["district"], p["parent_name"], p["area_name"])
        geom = shape(feat["geometry"])
        if key in have:
            # an OSM name match far outside the village's own boundary is a namesake
            # elsewhere (Chikkanayakanahalli villages matched to places in Bangalore)
            r = have[key]
            if key[0] == CITY:   # city villages matched across all three city taluks: keep OSM
                continue
            here = (float(r["lat"]), float(r["lon"]))
            c = geom.representative_point()
            if km(here, (c.y, c.x)) > FAR_KM:
                r.update(lat=f"{c.y:.6f}", lon=f"{c.x:.6f}", match="village boundary", osm_name=p.get("census_name", ""))
                moved += 1
            continue
        pt = geom.representative_point()
        rows.append({"district": key[0], "parent_name": key[1], "area_name": key[2],
                     "lat": f"{pt.y:.6f}", "lon": f"{pt.x:.6f}", "match": "village boundary",
                     "osm_name": p.get("census_name", ""), "osm_name_kn": ""})
        have[key] = rows[-1]
        added += 1
    print(f"Placed {added} more villages at their census boundary; moved {moved} that sat far outside it")

    # anything else that sits far from where its taluk's villages are is a namesake too
    centre = defaultdict(list)
    for r in rows:
        if r["match"] == "village boundary":
            centre[(r["district"], r["parent_name"])].append((float(r["lat"]), float(r["lon"])))
    centre = {k: (statistics.median(a for a, _ in v), statistics.median(b for _, b in v))
              for k, v in centre.items() if len(v) >= 10}
    kept = []
    for r in rows:
        c = centre.get((r["district"], r["parent_name"]))
        if c and r["district"] != CITY and r["match"] != "village boundary" and km((float(r["lat"]), float(r["lon"])), c) > TALUK_KM:
            continue
        kept.append(r)
    print(f"Took {len(rows) - len(kept)} points off the map that sat far outside their taluk")
    rows[:] = kept

    # layouts and roads still off the map go where the place they're listed
    # under is: the village (rural gazettes) or locality heading (city ones)
    pts = {(r["district"], r["parent_name"], r["area_name"]): r for r in rows}
    near = 0
    for path in sorted(glob.glob("data/guidance/*_2023.csv")):
        for r in csv.DictReader(open(path, encoding="utf-8")):
            key = (r["district"], r["parent_name"], r["area_name"])
            ctx = (r.get("context") or "").strip()
            if key in pts or not ctx:
                continue
            host = pts.get((key[0], key[1], ctx))
            if host:
                new = dict(host, area_name=key[2], match="at the place it's listed under", osm_name=ctx, osm_name_kn="")
                rows.append(new)
                pts[key] = new
                near += 1
    with open(ppath, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(rows)
    print(f"Placed {near} more at the village or locality they're listed under ({len(rows)} points in all)")


if __name__ == "__main__":
    main()
