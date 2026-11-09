-- Latest NHB RESIDEX change for Bengaluru. Update when NHB publishes a new
-- quarter (https://www.nhb.org.in/media-corner/media-press-releases/);
-- the load workflow runs this file every time.
INSERT INTO nelabele.city_trend (city, period, yoy_pct, measure, source_url, updated_on)
VALUES ('Bengaluru', 'Jul–Sep 2025', 11.3, 'NHB RESIDEX, prices at assessment',
        'https://www.nhb.org.in/wp-content/uploads/2025/12/National-Press-Release-RESIDEX-Sep-25.pdf',
        '2026-11-10')
ON CONFLICT (city) DO UPDATE
  SET period = EXCLUDED.period, yoy_pct = EXCLUDED.yoy_pct, measure = EXCLUDED.measure,
      source_url = EXCLUDED.source_url, updated_on = EXCLUDED.updated_on;
