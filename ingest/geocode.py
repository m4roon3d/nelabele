"""
NelaBele – find map points for villages and localities.

Matches area names from data/guidance/*.csv to OpenStreetMap places
(osm/places.json on the `sources` branch, fetched by the "Fetch sources"
workflow) and writes data/geo/area_points.csv.

Gazette spellings drift from OSM's ("Kdigenahalli", "Hally", "Doddaballapur"),
so names are normalised for common transliteration variants, then matched
exactly, then fuzzily, always near the area's own taluk or sub-registrar
office so a common name like "Kodihalli" isn't put in the wrong place.

Usage:
  python ingest/geocode.py ../nb-sources/osm/places.json data/geo/area_points.csv
"""

import csv
import glob
import json
import math
import re
import sys
from collections import Counter, defaultdict

from rapidfuzz import fuzz, process

BANGALORE = (12.9716, 77.5946)
RADIUS_KM = {"taluk": 32, "zone": 14}
FUZZY_MIN = 90


def km(a, b):
    lat1, lon1, lat2, lon2 = map(math.radians, (*a, *b))
    h = (math.sin((lat2 - lat1) / 2) ** 2
         + math.cos(lat1) * math.cos(lat2) * math.sin((lon2 - lon1) / 2) ** 2)
    return 6371 * 2 * math.asin(math.sqrt(h))


_RULES = [
    (r"\b(hally|halli|halli|hali)\b", "halli"), (r"hally\b", "halli"),
    (r"pura\b", "pur"), (r"puram\b", "pur"), (r"palya\b", "palya"), (r"palaya\b", "palya"),
    (r"nagara\b", "nagar"), (r"\bnagara\b", "nagar"), (r"agrahara\b", "agrahar"),
    (r"aa", "a"), (r"ee", "i"), (r"oo", "u"), (r"ou", "u"),
    (r"th", "t"), (r"dh", "d"), (r"bh", "b"), (r"kh", "k"), (r"gh", "g"), (r"sh", "s"), (r"ph", "p"),
    (r"w", "v"), (r"z", "j"),
    (r"(.)\1+", r"\1"),
]


def norm(name):
    s = name.lower()
    s = re.sub(r"\(.*?(\)|$)", " ", s)
    s = re.sub(r"^\s*\d+\s*[.)]\s*", " ", s)
    s = re.sub(r"\b(village|grama|gramatana|gramathana|extension|extn|layout)\b", " ", s)
    s = re.sub(r"[^a-z0-9 ]", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    for pat, rep in _RULES:
        s = re.sub(pat, rep, s)
    return s.replace(" ", "")


def load_places(path):
    places = []
    for e in json.load(open(path))["elements"]:
        t = e.get("tags", {})
        lat = e.get("lat") or e.get("center", {}).get("lat")
        lon = e.get("lon") or e.get("center", {}).get("lon")
        if lat is None:
            continue
        names = {t.get(k) for k in ("name", "name:en", "alt_name", "old_name", "official_name")} - {None}
        for alt in list(names):
            names.update(a.strip() for a in alt.split(";"))
        places.append({"name": t.get("name"), "names": names, "place": t.get("place"),
                       "pt": (float(lat), float(lon)),
                       "keys": {norm(n) for n in names if n}})
    return places


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    places = load_places(sys.argv[1])
    by_key = defaultdict(list)
    for p in places:
        for k in p["keys"]:
            by_key[k].append(p)

    areas = {}
    for f in sorted(glob.glob("data/guidance/*.csv")):
        for r in csv.DictReader(open(f, encoding="utf-8")):
            areas[(r["district"], r["parent_name"], r["parent_level"], r["area_name"])] = r["area_level"]

    # Centre of each taluk / sub-registrar office: the OSM place of that name
    centres = {}
    for district, parent, plevel, _ in areas:
        if parent in centres:
            continue
        hits = by_key.get(norm(parent), [])
        if not hits:
            k = norm(parent)
            hits = [p for p in places if any(fuzz.ratio(k, pk) >= 85 for pk in p["keys"])]
        hits = sorted(hits, key=lambda p: (p["place"] not in ("town", "city", "suburb", "quarter"),
                                           km(p["pt"], BANGALORE)))
        centres[parent] = hits[0]["pt"] if hits else BANGALORE
    missing_centres = [p for p, c in centres.items() if c == BANGALORE]

    out, how = [], Counter()
    nearby = {}
    for (district, parent, plevel, name), level in sorted(areas.items()):
        centre = centres[parent]
        radius = RADIUS_KM.get(plevel, 25) * (2 if centre == BANGALORE else 1)
        if parent not in nearby:
            near = [p for p in places if km(p["pt"], centre) <= radius]
            pairs = [(k, i) for i, p in enumerate(near) for k in p["keys"]]
            nearby[parent] = (near, [k for k, _ in pairs], [i for _, i in pairs])
        near, cand_keys, cand_idx = nearby[parent]
        key = norm(name)

        pick, method = None, None
        exact = [p for p in by_key.get(key, []) if km(p["pt"], centre) <= radius]
        if exact:
            pick, method = min(exact, key=lambda p: km(p["pt"], centre)), "exact"
        else:
            best = process.extractOne(key, cand_keys, scorer=fuzz.ratio, score_cutoff=FUZZY_MIN) if key else None
            # spelling drift keeps the first letter: Kasuvanahalli/Kasavanahalli, not Alanayakana/Madanayakana
            if best and best[0][:1] != key[:1]:
                best = None
            if best:
                pick, method = near[cand_idx[best[2]]], "fuzzy"
            else:
                # A place named inside the area's name: "Jayanagar 4th Block Others Road",
                # "Mylasandra Varsha Greens", "Artha Developers Bagalur". Longest wins.
                words = re.sub(r"\(.*?(\)|$)", " ", name)
                words = re.sub(r"[^A-Za-z0-9 ]", " ", words).split()
                found = None
                for n in range(min(4, len(words)), 0, -1):
                    for i in range(len(words) - n + 1):
                        k = norm(" ".join(words[i:i + n]))
                        if len(k) < 6:
                            continue
                        hits = [p for p in by_key.get(k, []) if km(p["pt"], centre) <= radius]
                        if hits:
                            found = min(hits, key=lambda p: km(p["pt"], centre))
                            break
                    if found:
                        break
                if found:
                    pick, method = found, "contains"
        how[method or "not found"] += 1
        if pick:
            out.append({"district": district, "parent_name": parent, "area_name": name,
                        "lat": f"{pick['pt'][0]:.6f}", "lon": f"{pick['pt'][1]:.6f}",
                        "match": method, "osm_name": pick["name"]})

    with open(sys.argv[2], "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["district", "parent_name", "area_name", "lat", "lon", "match", "osm_name"])
        w.writeheader()
        w.writerows(out)
    total = len(areas)
    print(f"{len(out)} of {total} areas located ({len(out) / total:.0%}): "
          + ", ".join(f"{k} {v}" for k, v in how.most_common()))
    if missing_centres:
        print("No OSM place for these offices (searched around central Bangalore):", ", ".join(missing_centres))


if __name__ == "__main__":
    main()
