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
DROP FUNCTION IF EXISTS public.area_at(double precision, double precision);
DROP FUNCTION IF EXISTS public.search_area(text);
DROP VIEW IF EXISTS public.api_rate;
DROP VIEW IF EXISTS public.api_area;

-- Areas for the map: name, level, a map point and boundary as GeoJSON
CREATE VIEW public.api_area AS
SELECT id, name, name_kn, level, parent_id, district, aliases,
       ST_Y(coalesce(centroid, point)) AS lat,
       ST_X(coalesce(centroid, point)) AS lon,
       ST_AsGeoJSON(boundary)::json AS boundary
FROM nelabele.geo_area;

-- Indicative rates with area names, the taluk/zone they sit in and a map point
CREATE VIEW public.api_rate AS
SELECT r.*, a.name AS area_name, a.level, a.district,
       p.name AS parent_name, p.level AS parent_level,
       ST_Y(coalesce(a.centroid, a.point)) AS lat,
       ST_X(coalesce(a.centroid, a.point)) AS lon
FROM nelabele.rate_summary r
JOIN nelabele.geo_area a ON a.id = r.geo_area_id
LEFT JOIN nelabele.geo_area p ON p.id = a.parent_id;

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

-- Log a market rate seen for an area (POST /rpc/add_market_rate).
-- Editor token only. Checks every value, records who entered it, and
-- refreshes the rate summary so the new range shows straight away.
CREATE FUNCTION public.add_market_rate(
  area_id bigint,
  property_type text,
  rate numeric,
  unit text,
  observed_on date DEFAULT current_date,
  approval_status text DEFAULT 'unknown',
  source text DEFAULT 'manual',
  note text DEFAULT NULL
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

  INSERT INTO rate_observation (geo_area_id, property_type, approval_status, source_id,
                                raw_rate, raw_unit, observed_on, source_ref, batch_id, entered_by)
  VALUES (area_id, property_type::property_type, approval_status::approval_status, src,
          rate, unit::area_unit, observed_on, left(note, 500), 'app-entry', who)
  RETURNING id INTO new_id;

  REFRESH MATERIALIZED VIEW nelabele.rate_summary;
  RETURN json_build_object('id', new_id, 'area_id', area_id, 'property_type', property_type);
EXCEPTION
  WHEN invalid_text_representation THEN
    RAISE EXCEPTION 'Unknown property type, unit or approval status' USING ERRCODE = '22023';
END $$;

-- Functions are executable by everyone by default; limit them to the API roles
REVOKE EXECUTE ON FUNCTION public.area_at(double precision, double precision),
                           public.search_area(text),
                           public.add_market_rate(bigint, text, numeric, text, date, text, text, text)
  FROM PUBLIC;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anonymous') THEN
    GRANT USAGE ON SCHEMA public TO anonymous;
    GRANT SELECT ON public.api_area, public.api_rate TO anonymous;
    GRANT EXECUTE ON FUNCTION public.area_at(double precision, double precision),
                              public.search_area(text) TO anonymous;
    REVOKE ALL ON ALL TABLES IN SCHEMA nelabele FROM anonymous;
    REVOKE USAGE ON SCHEMA nelabele FROM anonymous;
    RAISE NOTICE 'Read-only API access granted to anonymous';
  ELSE
    RAISE NOTICE 'Role anonymous not found – enable the Data API, then run this file again';
  END IF;

  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    GRANT USAGE ON SCHEMA public TO authenticated;
    GRANT SELECT ON public.api_area, public.api_rate TO authenticated;
    GRANT EXECUTE ON FUNCTION public.area_at(double precision, double precision),
                              public.search_area(text),
                              public.add_market_rate(bigint, text, numeric, text, date, text, text, text)
      TO authenticated;
    REVOKE ALL ON ALL TABLES IN SCHEMA nelabele FROM authenticated;
    REVOKE USAGE ON SCHEMA nelabele FROM authenticated;
    RAISE NOTICE 'Read and market-rate entry granted to authenticated';
  END IF;
END $$;

-- Ask the Data API to pick up the changes
NOTIFY pgrst, 'reload schema';
