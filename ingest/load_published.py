"""Load market prices quoted in published reports (data/market/published.csv).

Each row names a place by its gazette name and taluk/zone, so it lands on the
same area as the guidance value. The whole file replaces the previous load
(batch 'published'), so edit the CSV and re-run to correct anything.

  export DATABASE_URL=...
  python ingest/load_published.py data/market/published.csv
"""
import csv
import os
import sys

import psycopg

BATCH = "published"


def main(path: str) -> None:
    url = os.environ.get("DATABASE_URL") or sys.exit("Set DATABASE_URL to your Neon connection string")
    rows = list(csv.DictReader(open(path, encoding="utf-8")))
    with psycopg.connect(url) as conn, conn.cursor() as cur:
        cur.execute("SELECT id FROM nelabele.source WHERE code = 'published'")
        src = cur.fetchone() or sys.exit("Source 'published' missing – run db/migrate.sql first")
        cur.execute("DELETE FROM nelabele.rate_observation WHERE batch_id = %s", (BATCH,))
        loaded, missing = 0, []
        for r in rows:
            cur.execute(
                """SELECT a.id,
                          EXISTS (SELECT 1 FROM nelabele.rate_observation o
                                  WHERE o.geo_area_id = a.id AND o.batch_id IS DISTINCT FROM %s)
                   FROM nelabele.geo_area a
                   LEFT JOIN nelabele.geo_area p ON p.id = a.parent_id
                   WHERE a.district = %s AND lower(a.name) = lower(%s) AND lower(p.name) = lower(%s)""",
                (BATCH, r["district"], r["area_name"], r["parent_name"]),
            )
            found = cur.fetchall()
            ids = [x[0] for x in found]
            if len(ids) > 1:
                # the same name at two levels (a leftover from an older parse):
                # use the one that carries the guidance value
                ids = [x[0] for x in found if x[1]] or ids
            if len(ids) != 1:
                missing.append(f'{r["label"]} → {r["area_name"]} ({len(ids)} matches)')
                continue
            cur.execute(
                """INSERT INTO nelabele.rate_observation
                     (geo_area_id, property_type, approval_status, source_id, raw_rate, raw_unit,
                      observed_on, source_ref, batch_id, entered_by)
                   VALUES (%s, %s::nelabele.property_type, 'unknown', %s, %s, %s::nelabele.area_unit, %s::date, %s, %s, 'published')""",
                (ids[0], r["property_type"], src[0], r["rate"], r["unit"], r["observed_on"],
                 f'{r["report"]}: {r["label"]} · {r["source_url"]}', BATCH),
            )
            loaded += 1
        cur.execute("REFRESH MATERIALIZED VIEW nelabele.rate_summary")
        conn.commit()
    print(f"Loaded {loaded} published prices")
    for m in missing:
        print(f"::warning::Not matched: {m}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "data/market/published.csv")
