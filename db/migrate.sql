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

-- Ramanagara (now Bengaluru South) district
ALTER TABLE nelabele.geo_area DROP CONSTRAINT IF EXISTS geo_area_district_check;
ALTER TABLE nelabele.geo_area ADD CONSTRAINT geo_area_district_check
  CHECK (district IN ('Bangalore Urban', 'Bangalore Rural', 'Ramanagara'));

-- City-wide price trend (NHB RESIDEX), shown beside guidance values
CREATE TABLE IF NOT EXISTS nelabele.city_trend (
  city        text PRIMARY KEY,
  period      text NOT NULL,          -- e.g. 'Jul–Sep 2025'
  yoy_pct     numeric(5,1) NOT NULL,  -- change over the same quarter a year earlier
  measure     text NOT NULL,          -- e.g. 'NHB RESIDEX, assessment prices'
  source_url  text NOT NULL,
  updated_on  date NOT NULL DEFAULT current_date
);
ALTER TABLE nelabele.city_trend ENABLE ROW LEVEL SECURITY;

-- Prices quoted in published market reports (e.g. ANAROCK), kept apart from listings
INSERT INTO nelabele.source (code, name, notes)
VALUES ('published', 'Published market reports', 'Average quoted prices from research reports; figure and link only')
ON CONFLICT (code) DO NOTHING;
