"""
NelaBele – load guidance values into Neon.

Reads a standardised CSV (see guidance_template.csv), matches or creates
areas in nelabele.geo_area, writes the rates to nelabele.rate_observation
as source 'guidance', then refreshes the rate summary.

Re-running with the same --batch-id replaces that batch, so loads are safe
to repeat.

Usage:
  export DATABASE_URL="postgresql://user:pass@host/db?sslmode=require"
  python load_guidance.py rates.csv --effective-date 2023-10-01
  python load_guidance.py rates.csv --effective-date 2023-10-01 --dry-run
"""

import argparse
import csv
import difflib
import os
import sys
from datetime import date
from pathlib import Path

import psycopg

REQUIRED = ["district", "area_name", "area_level", "property_type", "rate", "unit"]
OPTIONAL = ["parent_name", "parent_level", "approval_status", "source_ref", "name_kn"]
DISTRICTS = {"Bangalore Urban", "Bangalore Rural", "Ramanagara", "Tumakuru", "Kolar", "Chikkaballapura"}
SIMILAR = 0.85  # name similarity above which a new area looks like an existing one


def enum_values(cur, name):
    cur.execute(
        """SELECT e.enumlabel FROM pg_enum e
           JOIN pg_type t ON t.oid = e.enumtypid
           JOIN pg_namespace n ON n.oid = t.typnamespace
           WHERE n.nspname = 'nelabele' AND t.typname = %s""",
        (name,),
    )
    return {r[0] for r in cur.fetchall()}


def read_rows(path, enums):
    rows, errors = [], []
    with open(path, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        missing = [c for c in REQUIRED if c not in (reader.fieldnames or [])]
        if missing:
            sys.exit(f"CSV is missing columns: {', '.join(missing)}")
        for n, raw in enumerate(reader, start=2):
            r = {k: (raw.get(k) or "").strip() for k in REQUIRED + OPTIONAL}
            if not any(r.values()):
                continue
            problems = []
            for c in REQUIRED:
                if not r[c]:
                    problems.append(f"{c} is empty")
            if r["district"] and r["district"] not in DISTRICTS:
                problems.append(f"district '{r['district']}' must be one of {sorted(DISTRICTS)}")
            for col, enum in [("area_level", "geo_level"), ("parent_level", "geo_level"),
                              ("property_type", "property_type"), ("unit", "area_unit"),
                              ("approval_status", "approval_status")]:
                if r[col] and r[col] not in enums[enum]:
                    problems.append(f"{col} '{r[col]}' is not one of {sorted(enums[enum])}")
            if r["parent_name"] and not r["parent_level"]:
                problems.append("parent_level is needed when parent_name is given")
            try:
                r["rate"] = float(r["rate"].replace(",", "")) if r["rate"] else None
                if r["rate"] is not None and r["rate"] <= 0:
                    problems.append("rate must be positive")
            except ValueError:
                problems.append(f"rate '{r['rate']}' is not a number")
            if not r["approval_status"]:
                r["approval_status"] = (
                    "agricultural" if r["property_type"] == "agricultural_land" else "unknown"
                )
            if problems:
                errors.append(f"line {n}: " + "; ".join(problems))
            else:
                r["line"] = n
                rows.append(r)
    return rows, errors


class AreaResolver:
    """Matches area names to geo_area ids with a handful of queries in total,
    so loads stay fast even when the database is far away."""

    def __init__(self, cur):
        self.cur = cur
        self.index = {}       # (district, level, parent_id, lower name/alias) -> id
        self.existing = {}    # (district, level) -> names already in the database
        self.created = []
        self.warnings = []
        cur.execute("SELECT id, district, level::text, parent_id, name, aliases FROM nelabele.geo_area")
        for area_id, district, level, parent_id, name, aliases in cur.fetchall():
            for n in [name, *aliases]:
                self.index[(district, level, parent_id, n.lower())] = area_id
            self.existing.setdefault((district, level), []).append(name)

    def get(self, district, level, name, parent_id=None):
        return self.index[(district, level, parent_id, name.lower())]

    def ensure(self, wanted, kannada=None):
        """Create any of (district, level, name, parent_id) that don't exist yet."""
        kannada = kannada or {}
        missing = {}
        for district, level, name, parent_id in wanted:
            key = (district, level, parent_id, name.lower())
            if key not in self.index and key not in missing:
                missing[key] = (district, level, name, parent_id)
        if not missing:
            return
        for district, level, name, parent_id in missing.values():
            near = difflib.get_close_matches(name, self.existing.get((district, level), []),
                                             n=1, cutoff=SIMILAR)
            if near:
                self.warnings.append(
                    f"new {level} '{name}' looks like existing '{near[0]}' "
                    f"– if same place, add '{name}' to that area's aliases and re-run"
                )
        cols = [list(c) for c in zip(*missing.values())]
        cols.append([kannada.get(k) or None for k in missing])
        self.cur.execute(
            """INSERT INTO nelabele.geo_area (district, level, name, parent_id, name_kn)
               SELECT * FROM unnest(%s::text[], %s::nelabele.geo_level[], %s::text[], %s::bigint[], %s::text[])
               RETURNING id, district, level::text, parent_id, name""",
            cols,
        )
        for area_id, district, level, parent_id, name in self.cur.fetchall():
            self.index[(district, level, parent_id, name.lower())] = area_id
            self.created.append(f"{level} '{name}' ({district})")


def main():
    ap = argparse.ArgumentParser(description="Load guidance values into NelaBele")
    ap.add_argument("csv", type=Path)
    ap.add_argument("--effective-date", required=True, type=date.fromisoformat,
                    help="date the guidance values took effect, e.g. 2023-10-01")
    ap.add_argument("--batch-id", help="defaults to guidance-<date>-<file name>")
    ap.add_argument("--dry-run", action="store_true", help="validate and roll back")
    args = ap.parse_args()

    url = os.environ.get("DATABASE_URL")
    if not url:
        sys.exit("Set DATABASE_URL to your Neon connection string")
    batch = args.batch_id or f"guidance-{args.effective_date}-{args.csv.stem}"

    with psycopg.connect(url) as conn:
        with conn.cursor() as cur:
            enums = {e: enum_values(cur, e)
                     for e in ["geo_level", "property_type", "area_unit", "approval_status"]}
            rows, errors = read_rows(args.csv, enums)
            if errors:
                print(f"{len(errors)} bad row(s), nothing loaded:")
                print("\n".join("  " + e for e in errors[:50]))
                sys.exit(1)
            if not rows:
                sys.exit("No rows to load")

            cur.execute("SELECT id FROM nelabele.source WHERE code = 'guidance'")
            source_id = cur.fetchone()[0]

            areas = AreaResolver(cur)
            cur.execute("DELETE FROM nelabele.rate_observation WHERE batch_id = %s", (batch,))
            replaced = cur.rowcount

            areas.ensure({(r["district"], r["parent_level"], r["parent_name"], None)
                          for r in rows if r["parent_name"]})
            for r in rows:
                r["parent_id"] = (areas.get(r["district"], r["parent_level"], r["parent_name"])
                                  if r["parent_name"] else None)
            areas.ensure({(r["district"], r["area_level"], r["area_name"], r["parent_id"])
                          for r in rows},
                         kannada={(r["district"], r["area_level"], r["parent_id"], r["area_name"].lower()): r["name_kn"]
                                  for r in rows if r.get("name_kn")})

            data = []
            for r in rows:
                area_id = areas.get(r["district"], r["area_level"], r["area_name"], r["parent_id"])
                data.append((area_id, r["property_type"], r["approval_status"], source_id,
                             r["rate"], r["unit"], args.effective_date,
                             r["source_ref"] or f"{args.csv.name}:{r['line']}", batch))
            cur.executemany(
                """INSERT INTO nelabele.rate_observation
                   (geo_area_id, property_type, approval_status, source_id,
                    raw_rate, raw_unit, observed_on, source_ref, batch_id)
                   VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""",
                data,
            )

        print(f"Batch {batch}: {len(data)} rate(s)"
              + (f", replacing {replaced} from an earlier run" if replaced else ""))
        print(f"New areas: {len(areas.created)}")
        for w in areas.warnings[:20]:
            print("  check:", w)
        if len(areas.warnings) > 20:
            print(f"  ...and {len(areas.warnings) - 20} more possible duplicates")

        if args.dry_run:
            conn.rollback()
            print("Dry run – rolled back, nothing saved")
            return
        conn.commit()

    with psycopg.connect(url, autocommit=True) as conn:
        conn.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY nelabele.rate_summary")
    print("Saved and rate summary refreshed")


if __name__ == "__main__":
    main()
