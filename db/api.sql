-- =====================================================================
-- NelaBele – what the Neon Data API exposes
--
-- Lives in the public schema, which the Data API exposes by default.
-- The data itself stays in the private nelabele schema; these views and
-- functions are the only way in, read-only, for the 'anonymous' role.
--
-- Safe to run any number of times. Run it after nelabele_schema.sql and
-- again after enabling the Data API (which creates the 'anonymous' role).
-- =====================================================================

-- Remove older versions, including the ones that used to live in nelabele
DROP FUNCTION IF EXISTS nelabele.area_at(double precision, double precision);
DROP FUNCTION IF EXISTS nelabele.search_area(text);
DROP VIEW IF EXISTS nelabele.api_rate;
DROP VIEW IF EXISTS nelabele.api_area;
DROP FUNCTION IF EXISTS public.area_at(double precision, double precision);
DROP FUNCTION IF EXISTS public.search_area(text);
DROP VIEW IF EXISTS public.api_rate;
DROP VIEW IF EXISTS public.api_area;

-- Areas for the map: name, level, boundary as GeoJSON
CREATE VIEW public.api_area AS
SELECT id, name, name_kn, level, parent_id, district, aliases,
       ST_AsGeoJSON(boundary)::json AS boundary,
       ST_AsGeoJSON(centroid)::json AS centroid
FROM nelabele.geo_area;

-- Indicative rates with area names and the taluk/zone they sit in
CREATE VIEW public.api_rate AS
SELECT r.*, a.name AS area_name, a.level, a.district, p.name AS parent_name
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

-- Functions are executable by everyone by default; limit them to the API role
REVOKE EXECUTE ON FUNCTION public.area_at(double precision, double precision),
                           public.search_area(text) FROM PUBLIC;

-- Read-only access for the Data API's anonymous role, once it exists
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
END $$;

-- Ask the Data API to pick up the changes
NOTIFY pgrst, 'reload schema';
