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
CITY_ZONE_KM = 15   # an outer city zone spans about 10 km


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

    # City zones. Their villages were matched to census boundaries across all three
    # city taluks, so the boundary points are trusted only through their median:
    # an outer zone's own villages show where it is (Tavarekere SRO is out on Magadi
    # Road, not the Tavarekere by BTM Layout), and anything far from that is a namesake.
    zone_pts = defaultdict(list)
    for r in rows:
        if r["district"] == CITY and r["match"] == "village boundary":
            zone_pts[r["parent_name"]].append((float(r["lat"]), float(r["lon"])))
    zone_centre = {z: (statistics.median(a for a, _ in v), statistics.median(b for _, b in v))
                   for z, v in zone_pts.items() if len(v) >= 10}
    kept = [r for r in rows if not (
        r["district"] == CITY and r["parent_name"] in zone_centre
        and km((float(r["lat"]), float(r["lon"])), zone_centre[r["parent_name"]]) > CITY_ZONE_KM)]
    print(f"Took {len(rows) - len(kept)} city points off the map that sat far outside their zone")
    rows[:] = kept

    # One point claimed by same-named places in different city zones (three "RBI
    # Layout"s on the one in JP Nagar): the zone nearest the point keeps it; the
    # others go to the locality they're listed under, if that's on the map, else off it.
    centre_all = defaultdict(list)
    for r in rows:
        if r["district"] == CITY:
            centre_all[r["parent_name"]].append((float(r["lat"]), float(r["lon"])))
    # where the zone's places mostly are (its census villages alone can lean to one edge)
    zc = {z: (statistics.median(a for a, _ in v), statistics.median(b for _, b in v))
          for z, v in centre_all.items()}
    ctx = {}
    for path in sorted(glob.glob("data/guidance/bengaluru_urban_*_2023.csv")):
        for g in csv.DictReader(open(path, encoding="utf-8")):
            if g.get("context"):
                ctx[(g["parent_name"], g["area_name"])] = g["context"]
    pos = {(r["district"], r["parent_name"], r["area_name"]): r for r in rows}
    groups = defaultdict(list)
    for r in rows:
        if r["district"] == CITY:
            groups[(r["lat"], r["lon"], r["area_name"].lower())].append(r)
    moved = dropped = 0
    drop_ids = set()
    for (lat, lon, _), grp in groups.items():
        zones = {r["parent_name"] for r in grp}
        if len(zones) < 2:
            continue
        pt = (float(lat), float(lon))
        best = min(zones, key=lambda z: km(pt, zc[z]))
        for r in grp:
            if r["parent_name"] == best:
                continue
            host = pos.get((CITY, r["parent_name"], ctx.get((r["parent_name"], r["area_name"]), "")))
            if host and (host["lat"], host["lon"]) != (lat, lon):
                r.update(lat=host["lat"], lon=host["lon"], match="at the place it's listed under",
                         osm_name=host["area_name"])
                moved += 1
            else:
                drop_ids.add(id(r))
                dropped += 1
    rows[:] = [r for r in rows if id(r) not in drop_ids]
    print(f"Same-named city places sharing a point: {moved} moved to their listed locality, {dropped} taken off")

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
