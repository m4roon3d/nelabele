"""
NelaBele – put village boundaries on areas.

Reads data/geo/village_boundaries.geojson (made by boundaries.py) and sets
each matching area's boundary. The area's map point then comes from the
boundary's centre, and the map can shade the whole village.

Usage:
  export DATABASE_URL=...
  python ingest/load_boundaries.py data/geo/village_boundaries.geojson
"""

import json
import os
import sys

import psycopg


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    url = os.environ.get("DATABASE_URL") or sys.exit("Set DATABASE_URL to your Neon connection string")
    features = json.load(open(sys.argv[1], encoding="utf-8"))["features"]

    with psycopg.connect(url) as conn, conn.cursor() as cur:
        cur.execute("""CREATE TEMP TABLE shapes (district text, parent_name text, area_name text,
                                                 geojson text) ON COMMIT DROP""")
        with cur.copy("COPY shapes FROM STDIN") as cp:
            for f in features:
                p = f["properties"]
                cp.write_row((p["district"], p["parent_name"], p["area_name"], json.dumps(f["geometry"])))
        cur.execute("""
            UPDATE nelabele.geo_area a
               SET boundary = ST_Multi(ST_CollectionExtract(ST_MakeValid(
                                ST_SetSRID(ST_GeomFromGeoJSON(t.geojson), 4326)), 3))
              FROM shapes t, nelabele.geo_area p
             WHERE p.id = a.parent_id
               AND a.district = t.district
               AND lower(p.name) = lower(t.parent_name)
               AND lower(a.name) = lower(t.area_name)
               AND a.level = 'village'""")
        updated = cur.rowcount
        cur.execute("SELECT count(*) FROM nelabele.geo_area WHERE boundary IS NOT NULL")
        total = cur.fetchone()[0]
        conn.commit()
    print(f"{len(features)} boundaries in file, {updated} villages updated, {total} areas with a boundary")


if __name__ == "__main__":
    main()
