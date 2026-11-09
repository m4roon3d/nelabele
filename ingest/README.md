# NelaBele – guidance value ingest

Gets Karnataka guidance values into Neon in three steps.

## Setup

```bash
pip install -r requirements.txt
export DATABASE_URL="<your Neon connection string>"
```

Run `db/nelabele_schema.sql` in the Neon SQL editor first.

## 1. Extract tables from the PDFs

Download the SRO guidance value PDFs for Bangalore Urban and Rural from the
Stamps & Registration site, put them in one folder, then:

```bash
python extract_pdf_tables.py pdfs/ raw/
```

You get one raw CSV per PDF with every table row tagged by page. A warning
means the PDF uses old Kannada fonts and the text came out garbled.

## 2. Map to the standard format

Shape the raw rows into the columns of `guidance_template.csv`
(the sample rows in it are made-up examples – replace them):

| Column | Values |
|---|---|
| district | `Bangalore Urban` or `Bangalore Rural` |
| area_name, area_level | e.g. `Kundana`, `village` |
| parent_name, parent_level | optional, e.g. `Devanahalli`, `taluk` |
| property_type | `plot`, `agricultural_land`, `independent_house`, `apartment` |
| approval_status | optional; defaults to `agricultural` for farm land, else `unknown` |
| rate, unit | rate as printed, unit `sqft`, `sqm`, `sqyd`, `guntha` or `acre` |
| source_ref | optional, e.g. `Devanahalli SRO p.12` |

Levels: `district`, `taluk`, `hobli`, `village`, `zone`, `ward`, `locality`.

## 3. Load

```bash
python load_guidance.py rates.csv --effective-date 2023-10-01 --dry-run
python load_guidance.py rates.csv --effective-date 2023-10-01
```

- Bad rows are listed with line numbers and nothing is loaded.
- Areas are matched by name or alias; new ones are created. If a new name
  looks like an existing one (a likely misspelling), you get a warning.
- Re-running the same file replaces that batch, so it's safe to repeat.
- Rates are converted to ₹/sq ft and the rate summary is refreshed.
