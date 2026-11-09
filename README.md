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
db/nelabele_schema.sql   tables, rate engine, read-only API views
ingest/                  guidance value extract and load scripts
```

## Getting started

1. Create a Neon project and run `db/nelabele_schema.sql` in its SQL editor.
2. Enable the Data API in the Neon console and check the read-only role name
   matches the grants at the end of the schema (`anonymous`).
3. Load guidance values – see [`ingest/README.md`](ingest/README.md).
