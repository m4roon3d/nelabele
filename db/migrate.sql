-- =====================================================================
-- NelaBele – schema changes since the first version.
-- Safe to run any number of times; the load workflow runs it every time,
-- after nelabele_schema.sql (first run only) and before api.sql.
-- =====================================================================

-- Map points for areas that have no boundary yet (from OpenStreetMap)
ALTER TABLE nelabele.geo_area ADD COLUMN IF NOT EXISTS point geometry(Point, 4326);
ALTER TABLE nelabele.geo_area ADD COLUMN IF NOT EXISTS point_source text;
CREATE INDEX IF NOT EXISTS geo_area_point_gix ON nelabele.geo_area USING gist (point);

-- Who logged a market rate (the token's subject), for manual entries
ALTER TABLE nelabele.rate_observation ADD COLUMN IF NOT EXISTS entered_by text;
