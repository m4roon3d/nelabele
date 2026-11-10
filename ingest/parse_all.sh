#!/usr/bin/env bash
# Rebuild data/guidance/*.csv from the 2023 gazettes.
# Needs the PDFs from the `sources` branch (git worktree or clone) in $SRC,
# and the Nudi converter for Kannada-only rows (see ingest/nudi.py).
# Page ranges per sub-registrar office come from each gazette's index page.
set -euo pipefail
cd "$(dirname "$0")/.."
SRC=${SRC:-../nb-sources/gazettes}
mkdir -p raw

python ingest/extract_pdf_tables.py "$SRC/bengaluru_rural_2023.pdf" raw/ 2>/dev/null || true
if [ -f raw/bengaluru_rural_2023.csv ]; then
  python ingest/parse_gazette.py raw/bengaluru_rural_2023.csv data/guidance/bengaluru_rural_2023.csv \
    --district "Bangalore Rural" --town-rollup \
    --section 12-68:Nelamangala --section 69-101:Doddaballapur \
    --section 102-168:Devanahalli --section 169-234:Hoskote
fi

declare -A SEC
SEC[basavanagudi]="12-21:Basavanagudi 22-29:Chamarajpet 30-63:Banashankari 64-97:Anekal 98-122:Attibele 123-186:Sarjapura 187-233:Jigani"
SEC[gandhinagar]="12-36:Gandhinagar 37-51:Malleshwaram 52-75:Gangenahalli 76-137:Hebbal 138-165:Kacharakanahalli 166-187:Yelahanka 188-224:Byatarayanapura 225-238:Jala 239-249:Hesaraghatta"
SEC[jayanagar]="12-33:Jayanagar 34-45:Shantinagar 46-53:BTM_Layout 54-68:Kengeri 69-90:Rajarajeshwarinagar 91-127:JP_Nagar 128-152:Bommanahalli 153-170:Begur 171-176:Tavarekere"
SEC[rajajinagar]="12-25:Rajajinagar 26-39:Yeshwanthpur 40-51:Peenya 52-58:Srirampura 59-68:Laggere 69-83:Nagarbhavi 84-93:Madanayakanahalli 94-103:Dasanapura 104-112:Vijayanagar"
SEC[shivajinagar]="12-35:Shivajinagar 36-44:Indiranagar 45-59:Halasuru 60-105:Banaswadi 106-130:KR_Puram 131-186:Mahadevapura 187-236:Bidarahalli 237-314:Varthur"

python ingest/extract_pdf_tables.py "$SRC/ramanagara_2023.pdf" raw/
python ingest/parse_gazette.py raw/ramanagara_2023.csv data/guidance/ramanagara_2023.csv \
  --district Ramanagara --town-rollup \
  --section 12-264:Ramanagara --section 265-404:Channapatna \
  --section 405-586:Kanakapura --section 587-654:Magadi

for f in "${!SEC[@]}"; do
  python ingest/extract_pdf_tables.py "$SRC/${f}_2023.pdf" raw/
  args=(); for s in ${SEC[$f]}; do args+=(--section "${s//_/ }"); done
  python ingest/parse_gazette.py "raw/${f}_2023.csv" "data/guidance/bengaluru_urban_${f}_2023.csv" \
    --district "Bangalore Urban" --parent-level zone --mode city "${args[@]}"
done
# Neighbouring districts: one gazette per sub-registrar office, from the IGR site
# (igr.karnataka.gov.in, "Revised Guidelines Value"; reachable only from India),
# saved in $IGR as <file>.pdf. Land rates there are printed in ₹ per acre.
IGR=${IGR:-../igr}
OFFICES="Tumkuru:Tumakuru:Tumakuru thipaturu:Tiptur:Tumakuru Gubbi:Gubbi:Tumakuru Kunigal:Kunigal:Tumakuru
Huliyadurga:Huliyurdurga:Tumakuru Sira:Sira:Tumakuru Madhugiri:Madhugiri:Tumakuru Koratagere:Koratagere:Tumakuru
Chikkanayakanahalli:Chikkanayakanahalli:Tumakuru Pavagada:Pavagada:Tumakuru Turuvekere:Turuvekere:Tumakuru
Kolara:Kolar:Kolar Bangarapete:Bangarapet:Kolar Malur:Malur:Kolar Srinivasapura:Srinivaspur:Kolar
Mulabagilu:Mulbagal:Kolar KGF:KGF:Kolar Chikkaballapura:Chikkaballapura:Chikkaballapura
Gudibande:Gudibande:Chikkaballapura Bagepalli:Bagepalli:Chikkaballapura Gowribidanuru:Gauribidanur:Chikkaballapura
Chinthamani:Chintamani:Chikkaballapura Shidlagatta:Sidlaghatta:Chikkaballapura"
if [ -d "$IGR" ]; then
  mkdir -p raw/igr raw/igr_out
  for o in $OFFICES; do
    IFS=: read -r f office dist <<< "$o"
    python ingest/extract_pdf_tables.py "$IGR/$f.pdf" raw/igr/
    pages=$(python -c "import pdfplumber,sys; print(len(pdfplumber.open(sys.argv[1]).pages))" "$IGR/$f.pdf")
    python ingest/parse_gazette.py "raw/igr/$f.csv" "raw/igr_out/$f.csv" --district "$dist" \
      --town-rollup --acre-rupees --section "1-$pages:$office"
  done
  # one file per district, office by office
  python - <<'PY'
import csv, glob, collections
rows, fields = collections.defaultdict(list), None
for path in sorted(glob.glob("raw/igr_out/*.csv")):
    for r in csv.DictReader(open(path, encoding="utf-8")):
        fields = fields or list(r)
        if not (r["property_type"] in ("plot", "apartment") and float(r["rate"]) > 60000):
            rows[r["district"]].append(r)
for district, rs in rows.items():
    with open(f"data/guidance/{district.lower()}_2023.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(rs)
PY
fi
python3 ingest/clean_names.py data/guidance/*.csv
