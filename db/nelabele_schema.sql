-- =====================================================================
-- NelaBele – indicative property rates, Bangalore Urban & Rural
-- Target: Neon Postgres + PostGIS, exposed read-only via Neon Data API
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;   -- fuzzy name search

CREATE SCHEMA IF NOT EXISTS nelabele;
SET search_path = nelabele, public;

-- ---------------------------------------------------------------------
-- 1. Reference types
-- ---------------------------------------------------------------------
CREATE TYPE geo_level AS ENUM (
  'district', 'taluk', 'hobli', 'village',   -- revenue hierarchy (rural)
  'zone', 'ward', 'locality'                 -- urban hierarchy
);

CREATE TYPE property_type AS ENUM (
  'plot', 'agricultural_land', 'independent_house', 'apartment'
);

CREATE TYPE approval_status AS ENUM (
  'a_khata', 'b_khata', 'e_khata',
  'dc_converted', 'bda_approved', 'bmrda_approved', 'biaapa_approved',
  'agricultural', 'unknown'
);

CREATE TYPE area_unit AS ENUM ('sqft', 'sqm', 'sqyd', 'guntha', 'acre');

-- ---------------------------------------------------------------------
-- 2. Geo model – one tree, every rate hangs off a node
-- ---------------------------------------------------------------------
CREATE TABLE geo_area (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name        text        NOT NULL,
  name_kn     text,                              -- Kannada name
  level       geo_level   NOT NULL,
  parent_id   bigint REFERENCES geo_area(id),
  district    text        NOT NULL CHECK (district IN ('Bangalore Urban', 'Bangalore Rural')),
  aliases     text[]      NOT NULL DEFAULT '{}', -- spellings: "Yelahanka", "Yalahanka"
  boundary    geometry(MultiPolygon, 4326),
  centroid    geometry(Point, 4326)
              GENERATED ALWAYS AS (ST_PointOnSurface(boundary)) STORED,
  UNIQUE (name, level, parent_id)
);

CREATE INDEX geo_area_boundary_gix ON geo_area USING gist (boundary);
CREATE INDEX geo_area_parent_idx   ON geo_area (parent_id);
CREATE INDEX geo_area_name_trgm    ON geo_area USING gin (name gin_trgm_ops);

-- ---------------------------------------------------------------------
-- 3. Sources
-- ---------------------------------------------------------------------
CREATE TABLE source (
  id     smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code   text UNIQUE NOT NULL,       -- 'guidance', 'listing', 'manual'
  name   text NOT NULL,
  url    text,
  notes  text
);

INSERT INTO source (code, name) VALUES
  ('guidance', 'Karnataka guidance values'),
  ('listing',  'Listing asking prices'),
  ('manual',   'Manual entries');

-- ---------------------------------------------------------------------
-- 4. Raw observations – every rate seen, normalised to ₹/sq ft
-- ---------------------------------------------------------------------
CREATE TABLE rate_observation (
  id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  geo_area_id     bigint          NOT NULL REFERENCES geo_area(id),
  property_type   property_type   NOT NULL,
  approval_status approval_status NOT NULL DEFAULT 'unknown',
  source_id       smallint        NOT NULL REFERENCES source(id),

  raw_rate        numeric(14,2)   NOT NULL CHECK (raw_rate > 0),  -- ₹ per raw_unit
  raw_unit        area_unit       NOT NULL,
  rate_per_sqft   numeric(12,2) GENERATED ALWAYS AS (
                    raw_rate / CASE raw_unit
                      WHEN 'sqft'   THEN 1
                      WHEN 'sqm'    THEN 10.7639
                      WHEN 'sqyd'   THEN 9
                      WHEN 'guntha' THEN 1089
                      WHEN 'acre'   THEN 43560
                    END) STORED,

  observed_on     date            NOT NULL,
  location        geometry(Point, 4326),        -- optional exact point
  source_ref      text,                         -- listing id / PDF page / note
  batch_id        text,                         -- pipeline run id
  ingested_at     timestamptz     NOT NULL DEFAULT now()
);

CREATE INDEX rate_obs_lookup_idx ON rate_observation (geo_area_id, property_type, approval_status, observed_on);
CREATE INDEX rate_obs_location_gix ON rate_observation USING gist (location);

-- ---------------------------------------------------------------------
-- 5. Rate engine – indicative ranges
--    Market range: listings + manual entries from the last 12 months,
--    per area, property type and approval status.
--    Guidance value: the latest one per area and property type, whatever
--    its age (revisions are years apart) and whatever the approval status.
--    Refresh at the end of each pipeline run:
--    REFRESH MATERIALIZED VIEW CONCURRENTLY nelabele.rate_summary;
-- ---------------------------------------------------------------------
CREATE MATERIALIZED VIEW rate_summary AS
WITH market AS (
  SELECT
    o.geo_area_id, o.property_type, o.approval_status,
    percentile_cont(0.25) WITHIN GROUP (ORDER BY o.rate_per_sqft) AS market_low,
    percentile_cont(0.50) WITHIN GROUP (ORDER BY o.rate_per_sqft) AS market_mid,
    percentile_cont(0.75) WITHIN GROUP (ORDER BY o.rate_per_sqft) AS market_high,
    count(*)                                                      AS market_obs,
    array_agg(DISTINCT s.code)                                    AS market_sources,
    max(o.observed_on)                                            AS last_observed
  FROM rate_observation o
  JOIN source s ON s.id = o.source_id
  WHERE s.code <> 'guidance'
    AND o.observed_on >= current_date - INTERVAL '12 months'
  GROUP BY o.geo_area_id, o.property_type, o.approval_status
),
guidance AS (
  SELECT DISTINCT ON (o.geo_area_id, o.property_type)
    o.geo_area_id, o.property_type, o.approval_status,
    o.rate_per_sqft AS guidance_rate,
    o.observed_on   AS guidance_effective
  FROM rate_observation o
  JOIN source s ON s.id = o.source_id
  WHERE s.code = 'guidance'
  ORDER BY o.geo_area_id, o.property_type, o.observed_on DESC, o.rate_per_sqft DESC
)
SELECT
  coalesce(m.geo_area_id, g.geo_area_id)         AS geo_area_id,
  coalesce(m.property_type, g.property_type)     AS property_type,
  coalesce(m.approval_status, g.approval_status) AS approval_status,
  m.market_low, m.market_mid, m.market_high,
  g.guidance_rate, g.guidance_effective,
  coalesce(m.market_obs, 0)                      AS market_obs,
  coalesce(m.market_sources, '{}')
    || CASE WHEN g.guidance_rate IS NOT NULL THEN '{guidance}'::text[] ELSE '{}' END
                                                 AS sources,
  m.last_observed,
  CASE
    WHEN coalesce(m.market_obs, 0) >= 10 THEN 'high'
    WHEN coalesce(m.market_obs, 0) >= 3  THEN 'medium'
    ELSE 'low'
  END                                            AS confidence
FROM market m
FULL OUTER JOIN guidance g
  ON g.geo_area_id = m.geo_area_id AND g.property_type = m.property_type;

CREATE UNIQUE INDEX rate_summary_pk
  ON rate_summary (geo_area_id, property_type, approval_status);

-- ---------------------------------------------------------------------
-- 6. Lock down the base tables
--    The app never reads these directly. What the Data API exposes is
--    defined in db/api.sql, which lives in the public schema.
-- ---------------------------------------------------------------------
ALTER TABLE geo_area         ENABLE ROW LEVEL SECURITY;
ALTER TABLE rate_observation ENABLE ROW LEVEL SECURITY;
ALTER TABLE source           ENABLE ROW LEVEL SECURITY;
