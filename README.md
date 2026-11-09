# NelaBele

**ನೆಲ ಬೆಲೆ – "land price".** Indicative property rates for land, independent
houses and apartments across Bangalore Urban and Bangalore Rural.

Rates are shown as ranges, not valuations, with the government guidance
value alongside and a confidence level based on how much data there is.

## Stack

| Layer | Choice |
|---|---|
| Data pipeline | Python scripts, scheduled with GitHub Actions |
| Database | Neon Postgres + PostGIS |
| API | Neon Data API (read-only, PostgREST-compatible) |
| App | Flutter – Android and web |
| Maps | MapLibre + OpenFreeMap (Positron style) |

## Layout

```
app/                     Flutter app (Android + web), built by GitHub Actions
auth/                    signing key for the app's read-only API token
config/data_api.json     Data API URL and the app's public read-only token
db/nelabele_schema.sql   tables and rate engine (private nelabele schema)
db/api.sql               read-only views and lookups the Data API exposes
ingest/                  guidance value extract, parse and load scripts
data/guidance/           parsed guidance values, ready to load
```

## Getting started

1. Create a Neon project and run `db/nelabele_schema.sql` in its SQL editor.
2. Enable the Data API in the Neon console and check the read-only role name
   matches the grants at the end of the schema (`anonymous`).
3. Load guidance values – see [`ingest/README.md`](ingest/README.md).
