"""Metro, ring roads and airports for the map, from OpenStreetMap.

Reads osm/infra.json (fetched by the "Fetch sources" workflow) and writes a
small GeoJSON for the app: lines simplified to ~10 m, each feature tagged
with `kind` (metro, metro_planned, ring, ring_planned, station, airport).
(c) OpenStreetMap contributors, ODbL.

  python ingest/infra.py infra.json app/assets/infra.geojson
"""
import json
import re
import sys

from shapely.geometry import LineString, Polygon, mapping
from shapely.ops import linemerge, unary_union

RINGS = {
    "Outer Ring Road": "Outer Ring Road",
    "Satellite Town Ring Road": "STRR",
    "Satellite Towns Ring Road": "STRR",
    "Bengaluru Business Corridor": "Business Corridor (PRR)",
    "Peripheral Ring Road": "Business Corridor (PRR)",
}


def main(src, dst):
    els = json.load(open(src))["elements"]
    lines = {}       # (kind, name) -> [LineString]
    points = []
    for e in els:
        t = e.get("tags", {})
        if e["type"] == "node":
            name = t.get("name:en") or t.get("name")
            if name:
                planned = t.get("railway") != "station" or "construction" in t
                points.append({"type": "Feature",
                               "geometry": {"type": "Point", "coordinates": [round(e["lon"], 5), round(e["lat"], 5)]},
                               "properties": {"kind": "station", "name": re.sub(r"\s*metro station$", "", name, flags=re.I),
                                              "planned": planned}})
            continue
        geom = [(p["lon"], p["lat"]) for p in e.get("geometry", [])]
        if len(geom) < 2:
            continue
        if t.get("aeroway") == "aerodrome":
            c = Polygon(geom).centroid if len(geom) >= 4 else LineString(geom).centroid
            points.append({"type": "Feature",
                           "geometry": {"type": "Point", "coordinates": [round(c.x, 5), round(c.y, 5)]},
                           "properties": {"kind": "airport", "name": t.get("name:en") or t.get("name")}})
            continue
        rail = t.get("railway")
        if re.search(r"depot|test track|yard", t.get("name") or "", re.I) or t.get("service") in ("yard", "siding"):
            continue
        if rail in ("subway", "light_rail"):
            kind, name = "metro", t.get("name") or "Namma Metro"
        elif rail in ("construction", "proposed"):
            kind, name = "metro_planned", t.get("name") or "Metro (under construction)"
        elif "highway" in t:
            ring = next((v for k, v in RINGS.items() if (t.get("name") or "").lower().startswith(k.lower())), None)
            if not ring:
                continue
            planned = t["highway"] in ("construction", "proposed")
            kind, name = ("ring_planned" if planned else "ring"), ring
        else:
            continue
        lines.setdefault((kind, name), []).append(LineString(geom))

    features = []
    for (kind, name), ls in sorted(lines.items()):
        u = unary_union(ls)
        merged = (linemerge(u) if u.geom_type == "MultiLineString" else u).simplify(0.0001, preserve_topology=False)
        g = mapping(merged)
        def rnd(c):
            return [rnd(x) for x in c] if isinstance(c[0], (list, tuple)) else [round(c[0], 5), round(c[1], 5)]
        g = {"type": g["type"], "coordinates": rnd(g["coordinates"])}
        features.append({"type": "Feature", "geometry": g, "properties": {"kind": kind, "name": name}})
    # one marker per station name
    seen = set()
    for p in points:
        key = (p["properties"]["kind"], p["properties"]["name"])
        if key not in seen:
            seen.add(key)
            features.append(p)
    out = {"type": "FeatureCollection",
           "attribution": "© OpenStreetMap contributors, ODbL",
           "features": features}
    json.dump(out, open(dst, "w"), separators=(",", ":"))
    kinds = {}
    for f in features:
        kinds[f["properties"]["kind"]] = kinds.get(f["properties"]["kind"], 0) + 1
    print(f"{dst}: {kinds}")


if __name__ == "__main__":
    main(*sys.argv[1:3])
