"""Build the app's search index: every place with rates, plus OpenStreetMap
neighbourhood names and main roads to find places near them.

The app downloads this once and searches it on the phone, forgiving spelling
("JP Nagar" / "J.P.Nagar", "Marthahalli") and finding popular names that the
gazettes don't use ("Electronic City" -> places within 2 km).

  export DATABASE_URL=...
  python ingest/search_index.py places.json roads.json data/search/index.json

Format (compact JSON, arrays to keep it small):
  places:  [id, name, name_kn, parent index, district index, lat, lon]
  parents: [name, district index]
  osm:     [name, lat, lon]            neighbourhoods, suburbs, villages, layouts
  roads:   [name, [lat, lon, lat, lon, ...]]   main roads, one point per stretch
(c) OpenStreetMap contributors (osm, roads), ODbL.
"""
import json
import os
import re
import sys
from datetime import date

import psycopg

PLACE_TYPES = {"city", "town", "suburb", "neighbourhood", "quarter", "locality", "village", "hamlet"}
MAIN_ROADS = re.compile(r"^(motorway|trunk|primary|secondary|tertiary)$")


def key(s):
    return re.sub(r"[^a-z0-9]", "", s.lower())


def main(places_path, roads_path, out_path):
    url = os.environ.get("DATABASE_URL") or sys.exit("Set DATABASE_URL")
    with psycopg.connect(url) as conn, conn.cursor() as cur:
        cur.execute("""
            SELECT g.id, g.name, coalesce(g.name_kn, ''), coalesce(p.name, ''), g.district,
                   ST_Y(coalesce(g.centroid, g.point)), ST_X(coalesce(g.centroid, g.point))
            FROM nelabele.geo_area g
            LEFT JOIN nelabele.geo_area p ON p.id = g.parent_id
            WHERE EXISTS (SELECT 1 FROM nelabele.rate_summary r WHERE r.geo_area_id = g.id)
            ORDER BY g.district, p.name, g.name""")
        rows = cur.fetchall()

    districts, parents, parent_idx, places, known = [], [], {}, [], set()
    for gid, name, kn, parent, district, lat, lon in rows:
        if district not in districts:
            districts.append(district)
        d = districts.index(district)
        if (parent, d) not in parent_idx:
            parent_idx[(parent, d)] = len(parents)
            parents.append([parent, d])
        places.append([gid, name, kn, parent_idx[(parent, d)], d,
                       round(lat, 4) if lat is not None else None,
                       round(lon, 4) if lon is not None else None])
        known.add(key(name))

    osm, seen = [], set()
    for e in json.load(open(places_path))["elements"]:
        t = e.get("tags", {})
        if t.get("place") not in PLACE_TYPES:
            continue
        lat = e.get("lat") or e.get("center", {}).get("lat")
        lon = e.get("lon") or e.get("center", {}).get("lon")
        for n in {t.get("name"), t.get("name:en"), t.get("alt_name")} - {None}:
            k = key(n)
            if lat is None or not k or k in known or (k, round(lat, 2), round(lon, 2)) in seen:
                continue
            seen.add((k, round(lat, 2), round(lon, 2)))
            osm.append([n, round(lat, 4), round(lon, 4)])

    roads = {}
    for e in json.load(open(roads_path))["elements"]:
        t = e.get("tags", {})
        name = t.get("name:en") or t.get("name")
        c = e.get("center")
        if e.get("type") != "way" or not name or not c or not MAIN_ROADS.match(t.get("highway", "")):
            continue
        if re.match(r"^\d|^(cross|main) road", name, re.I) or re.search(r"flyover|underpass|service road", name, re.I):
            continue   # "1st Main Road", flyovers: too generic to search by
        roads.setdefault(name, []).extend([round(c["lat"], 4), round(c["lon"], 4)])
    road_list = [[n, pts] for n, pts in sorted(roads.items()) if len(pts) >= 4]

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump({"version": str(date.today()), "attribution": "Places and roads (c) OpenStreetMap contributors, ODbL",
                   "districts": districts, "parents": parents, "places": places,
                   "osm": osm, "roads": road_list},
                  f, ensure_ascii=False, separators=(",", ":"))
    print(f"{out_path}: {len(places)} places, {len(parents)} areas, {len(osm)} OSM names, "
          f"{len(road_list)} roads, {os.path.getsize(out_path) // 1024} KB")


if __name__ == "__main__":
    main(*sys.argv[1:4])
