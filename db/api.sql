-- =====================================================================
-- NelaBele – what the Neon Data API exposes
--
-- Lives in the public schema, which the Data API exposes by default.
-- The data itself stays in the private nelabele schema; these views and
-- functions are the only way in.
--
--   anonymous      (the app's public token)   read the views and lookups
--   authenticated  (the owner's editor token) also log market rates
--
-- Safe to run any number of times. Run it after nelabele_schema.sql and
-- migrate.sql, and again after enabling the Data API (which creates the
-- anonymous and authenticated roles).
-- =====================================================================

-- Remove older versions, including the ones that used to live in nelabele
DROP FUNCTION IF EXISTS nelabele.area_at(double precision, double precision);
DROP FUNCTION IF EXISTS nelabele.search_area(text);
DROP VIEW IF EXISTS nelabele.api_rate;
DROP VIEW IF EXISTS nelabele.api_area;
DROP FUNCTION IF EXISTS public.add_market_rate(bigint, text, numeric, text, date, text, text, text);
DROP FUNCTION IF EXISTS public.add_market_rate(bigint, text, numeric, text, date, text, text, text, double precision, double precision);
DROP FUNCTION IF EXISTS public.area_at(double precision, double precision);
DROP FUNCTION IF EXISTS public.search_area(text);
DROP FUNCTION IF EXISTS public.nearby_areas(double precision, double precision, integer);
DROP VIEW IF EXISTS public.api_rate;
DROP VIEW IF EXISTS public.api_area_shape;
DROP VIEW IF EXISTS public.api_city_trend;
DROP VIEW IF EXISTS public.api_area;
DROP MATERIALIZED VIEW IF EXISTS nelabele.local_estimate;

-- Areas for the map: name, level, a map point and boundary as GeoJSON
CREATE VIEW public.api_area AS
SELECT id, name, name_kn, level, parent_id, district, aliases,
       ST_Y(coalesce(point, centroid)) AS lat,
       ST_X(coalesce(point, centroid)) AS lon,
       ST_AsGeoJSON(boundary)::json AS boundary
FROM nelabele.geo_area;

-- How far above guidance market prices run, learnt from places that have both.
-- A place's own guidance value is compared, or else the median for its
-- taluk/zone. Shared by the local and the city-wide estimates below.
CREATE MATERIALIZED VIEW nelabele.local_estimate AS
-- MATERIALIZED: work out the ratios once, not again for every place below
WITH compared AS MATERIALIZED (
  SELECT r.property_type,
         coalesce(a.point, a.centroid) AS pt,
         coalesce(r.guidance_rate, z.zone_guidance) AS ref,
         r.market_mid / coalesce(r.guidance_rate, z.zone_guidance) AS ratio
  FROM nelabele.rate_summary r
  JOIN nelabele.geo_area a ON a.id = r.geo_area_id
  LEFT JOIN LATERAL (
    SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY s.guidance_rate) AS zone_guidance
    FROM nelabele.rate_summary s
    JOIN nelabele.geo_area b ON b.id = s.geo_area_id
    WHERE b.parent_id = a.parent_id
      AND s.property_type = r.property_type
      AND s.guidance_rate IS NOT NULL
  ) z ON r.guidance_rate IS NULL
  WHERE r.market_mid IS NOT NULL
),
usable AS MATERIALIZED (
  SELECT * FROM compared WHERE ratio > 0 AND pt IS NOT NULL
),
targets AS (
  SELECT r.geo_area_id, r.property_type, r.approval_status, r.guidance_rate,
         coalesce(a.point, a.centroid) AS pt
  FROM nelabele.rate_summary r
  JOIN nelabele.geo_area a ON a.id = r.geo_area_id
  WHERE r.market_mid IS NULL AND r.guidance_rate IS NOT NULL
    AND coalesce(a.point, a.centroid) IS NOT NULL
)
-- Local: the up-to-5 nearest places of the same type with market prices,
-- within 12 km; needs at least 2, and this place's guidance value within
-- 0.5×–2× of theirs, so a pricey street isn't priced off a village nearby.
SELECT t.geo_area_id, t.property_type, t.approval_status,
       n.places, n.lo, n.mid, n.hi, n.km
FROM targets t
CROSS JOIN LATERAL (
  SELECT count(*) AS places,
         min(k.ratio) AS lo,
         percentile_cont(0.5) WITHIN GROUP (ORDER BY k.ratio) AS mid,
         max(k.ratio) AS hi,
         percentile_cont(0.5) WITHIN GROUP (ORDER BY k.km) AS km,
         min(k.ref) AS min_ref,
         max(k.ref) AS max_ref
  FROM (
    SELECT u.ratio, u.ref, ST_DistanceSphere(u.pt, t.pt) / 1000 AS km
    FROM usable u
    WHERE u.property_type = t.property_type
    ORDER BY u.pt <-> t.pt
    LIMIT 5
  ) k
  WHERE k.km <= 12
) n
WHERE n.places >= 2
  AND t.guidance_rate BETWEEN n.min_ref * 0.5 AND n.max_ref * 2;

CREATE UNIQUE INDEX local_estimate_pk ON nelabele.local_estimate (geo_area_id, property_type, approval_status);

-- Indicative rates with area names, the taluk/zone they sit in and a map point.
--
-- Estimated market range (est_*): where a place has no market data of its own,
-- its guidance value × how far above guidance market prices run nearby
-- (est_basis 'nearby': the nearest places with market prices, see
-- local_estimate), or else across all places of that type (est_basis 'city').
-- The city-wide multiplier needs at least 3 places and is only applied to
-- places whose guidance value is within the range it was learnt from (0.6×
-- lowest to 1.5× highest); both widen by themselves as market data comes in.
CREATE VIEW public.api_rate AS
WITH compared AS (
  SELECT r.property_type,
         coalesce(r.guidance_rate, z.zone_guidance) AS ref,
         r.market_mid / coalesce(r.guidance_rate, z.zone_guidance) AS ratio
  FROM nelabele.rate_summary r
  JOIN nelabele.geo_area a ON a.id = r.geo_area_id
  LEFT JOIN LATERAL (
    SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY s.guidance_rate) AS zone_guidance
    FROM nelabele.rate_summary s
    JOIN nelabele.geo_area b ON b.id = s.geo_area_id
    WHERE b.parent_id = a.parent_id
      AND s.property_type = r.property_type
      AND s.guidance_rate IS NOT NULL
  ) z ON r.guidance_rate IS NULL
  WHERE r.market_mid IS NOT NULL
),
-- Guidance history: each area's values by the date they took effect, newest first
guidance_history AS (
  SELECT o.geo_area_id, o.property_type, o.observed_on, max(o.rate_per_sqft) AS rate,
         dense_rank() OVER (PARTITION BY o.geo_area_id, o.property_type ORDER BY o.observed_on DESC) AS rn
  FROM nelabele.rate_observation o
  JOIN nelabele.source s ON s.id = o.source_id AND s.code = 'guidance'
  GROUP BY o.geo_area_id, o.property_type, o.observed_on
),
calibration AS (
  SELECT property_type,
         count(*) AS places,
         percentile_cont(0.25) WITHIN GROUP (ORDER BY ratio) AS lo,
         percentile_cont(0.50) WITHIN GROUP (ORDER BY ratio) AS mid,
         percentile_cont(0.75) WITHIN GROUP (ORDER BY ratio) AS hi,
         min(ref) AS min_ref,
         max(ref) AS max_ref
  FROM compared
  WHERE ratio IS NOT NULL AND ratio > 0
  GROUP BY property_type
  HAVING count(*) >= 3
)
SELECT r.*, a.name AS area_name, a.name_kn, a.level, a.district,
       a.boundary IS NOT NULL AS has_boundary,
       p.name AS parent_name, p.level AS parent_level,
       ST_Y(coalesce(a.point, a.centroid)) AS lat,
       ST_X(coalesce(a.point, a.centroid)) AS lon,
       -- the range is at least ±15% around the mid: places differ more than the sample shows
       round(r.guidance_rate * CASE WHEN l.mid IS NOT NULL THEN least(l.lo, l.mid * 0.85)
                                    ELSE least(c.lo, c.mid * 0.85) END)      AS est_low,
       round(r.guidance_rate * coalesce(l.mid, c.mid))                       AS est_mid,
       round(r.guidance_rate * CASE WHEN l.mid IS NOT NULL THEN greatest(l.hi, l.mid * 1.15)
                                    ELSE greatest(c.hi, c.mid * 1.15) END)   AS est_high,
       round(coalesce(l.mid, c.mid)::numeric, 2)                             AS est_ratio,
       coalesce(l.places, c.places)                                          AS est_places,
       CASE WHEN l.mid IS NOT NULL THEN 'nearby' WHEN c.mid IS NOT NULL THEN 'city' END AS est_basis,
       round(l.km::numeric, 1)                                               AS est_km,
       -- the guidance value before the latest revision, and the change
       prev.rate                                             AS prev_guidance_rate,
       prev.observed_on                                      AS prev_guidance_effective,
       round((r.guidance_rate / nullif(prev.rate, 0) - 1) * 100, 1) AS guidance_change_pct
FROM nelabele.rate_summary r
JOIN nelabele.geo_area a ON a.id = r.geo_area_id
LEFT JOIN nelabele.geo_area p ON p.id = a.parent_id
LEFT JOIN guidance_history prev
  ON prev.geo_area_id = r.geo_area_id AND prev.property_type = r.property_type AND prev.rn = 2
LEFT JOIN nelabele.local_estimate l
  ON l.geo_area_id = r.geo_area_id AND l.property_type = r.property_type
 AND l.approval_status = r.approval_status
LEFT JOIN calibration c
  ON c.property_type = r.property_type
 AND r.market_mid IS NULL
 AND l.mid IS NULL
 AND r.guidance_rate BETWEEN c.min_ref * 0.6 AND c.max_ref * 1.5;

-- Village outlines for the map, simplified to about 15 m, as GeoJSON
CREATE VIEW public.api_area_shape AS
SELECT id, ST_AsGeoJSON(ST_SimplifyPreserveTopology(boundary, 0.00015), 5)::json AS shape
FROM nelabele.geo_area
WHERE boundary IS NOT NULL;

-- Latest city-wide price change (NHB RESIDEX)
CREATE VIEW public.api_city_trend AS
SELECT city, period, yoy_pct, measure, source_url, updated_on FROM nelabele.city_trend;

-- Which area is this point in? (GET /rpc/area_at?lon=..&lat=..)
CREATE FUNCTION public.area_at(lon double precision, lat double precision)
RETURNS SETOF public.api_area
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = nelabele, public AS $$
  SELECT v.*
  FROM nelabele.geo_area g
  JOIN public.api_area v ON v.id = g.id
  WHERE ST_Contains(g.boundary, ST_SetSRID(ST_MakePoint(lon, lat), 4326))
  ORDER BY g.level DESC          -- most specific level first
$$;

-- Fuzzy search by name or alias (GET /rpc/search_area?q=..)
CREATE FUNCTION public.search_area(q text)
RETURNS SETOF public.api_area
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = nelabele, public AS $$
  SELECT v.*
  FROM nelabele.geo_area g
  JOIN public.api_area v ON v.id = g.id
  WHERE g.name % q OR q ILIKE ANY (g.aliases)
  ORDER BY similarity(g.name, q) DESC
  LIMIT 20
$$;

-- Places with rates closest to a point, for "Near me" (GET /rpc/nearby_areas?lat=..&lon=..).
-- The place whose outline contains the point comes first.
CREATE FUNCTION public.nearby_areas(lat double precision, lon double precision, lim integer DEFAULT 15)
RETURNS TABLE (id bigint, name text, km double precision, inside boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = nelabele, public AS $$
  WITH here AS (SELECT ST_SetSRID(ST_MakePoint(lon, lat), 4326) AS pt)
  SELECT g.id, g.name,
         round((ST_DistanceSphere(coalesce(g.point, g.centroid), here.pt) / 1000)::numeric, 2)::double precision,
         coalesce(ST_Contains(g.boundary, here.pt), false)
  FROM nelabele.geo_area g, here
  WHERE coalesce(g.point, g.centroid) IS NOT NULL
    AND EXISTS (SELECT 1 FROM nelabele.rate_summary r WHERE r.geo_area_id = g.id)
  ORDER BY coalesce(ST_Contains(g.boundary, here.pt), false) DESC,
           coalesce(g.point, g.centroid) <-> here.pt
  LIMIT least(greatest(lim, 1), 50)
$$;

-- Log a market rate seen for an area (POST /rpc/add_market_rate).
-- Editor token only. Checks every value, records who entered it, and
-- refreshes the rate summary so the new range shows straight away.
-- An optional lat/lon (a pin dropped in the app) puts the area on the map.
CREATE FUNCTION public.add_market_rate(
  area_id bigint,
  property_type text,
  rate numeric,
  unit text,
  observed_on date DEFAULT current_date,
  approval_status text DEFAULT 'unknown',
  source text DEFAULT 'manual',
  note text DEFAULT NULL,
  lat double precision DEFAULT NULL,
  lon double precision DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = nelabele, public AS $$
DECLARE
  src smallint;
  new_id bigint;
  who text := coalesce(nullif(current_setting('request.jwt.claims', true), '')::json ->> 'sub', current_user);
BEGIN
  IF NOT EXISTS (SELECT 1 FROM geo_area WHERE id = area_id) THEN
    RAISE EXCEPTION 'Unknown area %', area_id USING ERRCODE = '22023';
  END IF;
  IF rate IS NULL OR rate <= 0 THEN
    RAISE EXCEPTION 'Rate must be a positive number' USING ERRCODE = '22023';
  END IF;
  IF observed_on > current_date OR observed_on < current_date - 3650 THEN
    RAISE EXCEPTION 'Date must be within the last ten years and not in the future' USING ERRCODE = '22023';
  END IF;
  IF source NOT IN ('manual', 'listing') THEN
    RAISE EXCEPTION 'Source must be manual or listing' USING ERRCODE = '22023';
  END IF;
  SELECT id INTO src FROM nelabele.source s WHERE s.code = add_market_rate.source;
  IF (lat IS NULL) <> (lon IS NULL) OR lat NOT BETWEEN 11.5 AND 14.5 OR lon NOT BETWEEN 76 AND 79 THEN
    RAISE EXCEPTION 'Location must be a point in or around Bengaluru' USING ERRCODE = '22023';
  END IF;
  IF lat IS NOT NULL THEN
    UPDATE geo_area
       SET point = ST_SetSRID(ST_MakePoint(add_market_rate.lon, add_market_rate.lat), 4326),
           point_source = 'pin:' || who
     WHERE id = area_id;
  END IF;

  INSERT INTO rate_observation (geo_area_id, property_type, approval_status, source_id,
                                raw_rate, raw_unit, observed_on, source_ref, batch_id, entered_by)
  VALUES (area_id, property_type::property_type, approval_status::approval_status, src,
          rate, unit::area_unit, observed_on, left(note, 500), 'app-entry', who)
  RETURNING id INTO new_id;

  REFRESH MATERIALIZED VIEW nelabele.rate_summary;
  REFRESH MATERIALIZED VIEW nelabele.local_estimate;
  RETURN json_build_object('id', new_id, 'area_id', area_id, 'property_type', property_type,
                           'located', lat IS NOT NULL);
EXCEPTION
  WHEN invalid_text_representation THEN
    RAISE EXCEPTION 'Unknown property type, unit or approval status' USING ERRCODE = '22023';
END $$;

-- Functions are executable by everyone by default; limit them to the API roles

-- ---------------------------------------------------------------------
-- Market prices over time for one place: every non-guidance observation,
-- newest first, with where it came from (for the price-history chart)
CREATE OR REPLACE VIEW public.api_market_history AS
SELECT o.geo_area_id,
       o.property_type::text AS property_type,
       o.observed_on,
       o.rate_per_sqft::double precision AS rate_per_sqft,
       s.code AS source,
       -- the report and link for published prices; notes on logged rates stay private
       CASE WHEN s.code = 'published' THEN o.source_ref END AS source_ref
  FROM nelabele.rate_observation o
  JOIN nelabele.source s ON s.id = o.source_id
 WHERE s.code <> 'guidance';

-- Latest asking rent per place and type (₹ per sq ft per month), with its source
CREATE OR REPLACE VIEW public.api_rent AS
SELECT DISTINCT ON (r.geo_area_id, r.property_type)
       r.geo_area_id,
       r.property_type::text AS property_type,
       r.rent_per_sqft::double precision AS rent_per_sqft,
       r.observed_on,
       r.label,
       r.report,
       r.source_url
  FROM nelabele.rent_observation r
 ORDER BY r.geo_area_id, r.property_type, r.observed_on DESC;

REVOKE EXECUTE ON FUNCTION public.area_at(double precision, double precision),
                           public.search_area(text),
                           public.nearby_areas(double precision, double precision, integer),
                           public.add_market_rate(bigint, text, numeric, text, date, text, text, text, double precision, double precision)
  FROM PUBLIC;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anonymous') THEN
    GRANT USAGE ON SCHEMA public TO anonymous;
    GRANT SELECT ON public.api_area, public.api_rate, public.api_area_shape, public.api_city_trend,
                     public.api_market_history, public.api_rent TO anonymous;
    GRANT EXECUTE ON FUNCTION public.area_at(double precision, double precision),
                              public.search_area(text),
                              public.nearby_areas(double precision, double precision, integer) TO anonymous;
    REVOKE ALL ON ALL TABLES IN SCHEMA nelabele FROM anonymous;
    REVOKE USAGE ON SCHEMA nelabele FROM anonymous;
    RAISE NOTICE 'Read-only API access granted to anonymous';
  ELSE
    RAISE NOTICE 'Role anonymous not found – enable the Data API, then run this file again';
  END IF;

  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    GRANT USAGE ON SCHEMA public TO authenticated;
    GRANT SELECT ON public.api_area, public.api_rate, public.api_area_shape, public.api_city_trend,
                     public.api_market_history, public.api_rent TO authenticated;
    GRANT EXECUTE ON FUNCTION public.area_at(double precision, double precision),
                              public.search_area(text),
                              public.nearby_areas(double precision, double precision, integer),
                              public.add_market_rate(bigint, text, numeric, text, date, text, text, text, double precision, double precision)
      TO authenticated;
    REVOKE ALL ON ALL TABLES IN SCHEMA nelabele FROM authenticated;
    REVOKE USAGE ON SCHEMA nelabele FROM authenticated;
    RAISE NOTICE 'Read and market-rate entry granted to authenticated';
  END IF;
END $$;

-- Ask the Data API to pick up the changes
NOTIFY pgrst, 'reload schema';
