"""
NelaBele – put map points on areas.

Reads data/geo/area_points.csv (made by geocode.py) and sets each matching
area's point, matched on district, parent (taluk / sub-registrar office)
and area name. Areas with a real boundary keep using its centre, and
places someone pinned in the app keep their pin.

Usage:
  export DATABASE_URL=...
  python ingest/load_points.py data/geo/area_points.csv
"""

import csv
import os
import sys

import psycopg


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    url = os.environ.get("DATABASE_URL") or sys.exit("Set DATABASE_URL to your Neon connection string")
    rows = list(csv.DictReader(open(sys.argv[1], encoding="utf-8")))

    with psycopg.connect(url) as conn, conn.cursor() as cur:
        cur.execute("""CREATE TEMP TABLE pts (district text, parent_name text, area_name text,
                                              lat float8, lon float8, match text) ON COMMIT DROP""")
        with cur.copy("COPY pts FROM STDIN") as cp:
            for r in rows:
                cp.write_row((r["district"], r["parent_name"], r["area_name"],
                              float(r["lat"]), float(r["lon"]), r["match"]))
        cur.execute("""
            UPDATE nelabele.geo_area a
               SET point = ST_SetSRID(ST_MakePoint(t.lon, t.lat), 4326),
                   point_source = 'osm:' || t.match
              FROM pts t, nelabele.geo_area p
             WHERE p.id = a.parent_id
               AND a.district = t.district
               AND lower(p.name) = lower(t.parent_name)
               AND lower(a.name) = lower(t.area_name)
               AND a.point_source IS DISTINCT FROM 'pin'
               AND coalesce(a.point_source, '') NOT LIKE 'pin:%'""")
        updated = cur.rowcount
        cur.execute("SELECT count(*) FROM nelabele.geo_area WHERE coalesce(centroid, point) IS NOT NULL")
        located = cur.fetchone()[0]
        conn.commit()
    print(f"{len(rows)} points in file, {updated} areas updated, {located} areas now on the map")


if __name__ == "__main__":
    main()
