"""
NelaBele – village boundaries for the map.

Matches our village-level areas to the 2011 Census village boundaries
published by DataMeet (indian_village_boundaries, ka/ka.geojson, ODbL) and
writes the matched, simplified polygons to data/geo/village_boundaries.geojson.

The census spells taluks its own way ("Nelamagala", "Dod Ballapur",
"Kankapura"), and villages drift ("Kasuvanahalli"/"Kasavanahalli"), so
names are compared after the same normalisation geocode.py uses, within the
matching taluk(s) only.

Usage:
  python ingest/boundaries.py path/to/ka.geojson data/geo/village_boundaries.geojson
"""

import csv
import glob
import json
import sys
from collections import Counter, defaultdict

from rapidfuzz import fuzz, process
from shapely.geometry import mapping, shape

from geocode import norm

# our taluk / sub-registrar office → census taluk(s)
TALUKS = {
    "Nelamangala": ["Nelamagala"], "Doddaballapur": ["Dod Ballapur"],
    "Devanahalli": ["Devanhalli"], "Hoskote": ["Hoskote"],
    "Ramanagara": ["Ramanagaram"], "Channapatna": ["Channapatna"],
    "Kanakapura": ["Kankapura"], "Magadi": ["Magadi"],
}
CITY = ["Anekal", "Bangalore North", "Bangalore South"]   # every Bangalore Urban office
SIMPLIFY = 0.00015      # degrees, about 15 m: plenty for a phone map
FUZZY_MIN = 90


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    census = defaultdict(list)            # census taluk -> [(key, name, geometry)]
    for f in json.load(open(sys.argv[1]))["features"]:
        p = f["properties"]
        if p.get("DISTRICT") in ("Bangalore", "Bangalore Rural") and p.get("NAME"):
            census[p["TALUK"]].append((norm(p["NAME"]), p["NAME"], f["geometry"]))

    areas = {}
    for path in sorted(glob.glob("data/guidance/*.csv")):
        for r in csv.DictReader(open(path, encoding="utf-8")):
            if r["area_level"] == "village":
                areas[(r["district"], r["parent_name"], r["area_name"])] = True

    out, how, used = [], Counter(), set()
    for district, parent, name in sorted(areas):
        taluks = CITY if district == "Bangalore Urban" else TALUKS.get(parent, [])
        cands = [c for t in taluks for c in census.get(t, [])]
        if not cands:
            how["no census taluk"] += 1
            continue
        key = norm(name)
        hit = next((c for c in cands if c[0] == key), None)
        method = "exact"
        if not hit:
            best = process.extractOne(key, [c[0] for c in cands], scorer=fuzz.ratio, score_cutoff=FUZZY_MIN)
            if best and best[0][:1] == key[:1]:
                hit, method = cands[best[2]], "fuzzy"
        if not hit:
            how["not found"] += 1
            continue
        geom = shape(hit[2]).buffer(0).simplify(SIMPLIFY, preserve_topology=True)
        if geom.is_empty:
            how["empty"] += 1
            continue
        how[method] += 1
        used.add((tuple(taluks), hit[1]))
        out.append({
            "type": "Feature",
            "geometry": json.loads(json.dumps(mapping(geom)), parse_float=lambda x: round(float(x), 5)),
            "properties": {"district": district, "parent_name": parent, "area_name": name,
                           "census_name": hit[1], "match": method},
        })

    with open(sys.argv[2], "w", encoding="utf-8") as f:
        json.dump({"type": "FeatureCollection",
                   "attribution": "Village boundaries: 2011 Census via DataMeet, ODbL",
                   "features": out}, f, separators=(",", ":"))
    print(f"{len(out)} of {len(areas)} villages matched to a boundary: "
          + ", ".join(f"{k} {v}" for k, v in how.most_common()))


if __name__ == "__main__":
    main()
