"""
NelaBele – find map points for villages and localities.

Matches area names from data/guidance/*.csv to OpenStreetMap places
(osm/places.json on the `sources` branch, fetched by the "Fetch sources"
workflow) and writes data/geo/area_points.csv.

Gazette spellings drift from OSM's ("Kdigenahalli", "Hally", "Doddaballapur"),
so names are normalised for common transliteration variants, then matched
exactly, then fuzzily, always near the area's own taluk or sub-registrar
office so a common name like "Kodihalli" isn't put in the wrong place.

Streets and layouts that aren't places ("Whitefield Main Road", "12th Cross
Road", "Brigade Meadows") are then matched to OSM roads and named residential
areas (osm/roads.json): the piece of road nearest the zone's centre wins, and
generic numbered streets must be close to it.

Usage:
  python ingest/geocode.py places.json data/geo/area_points.csv [roads.json]
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


ROAD_WORDS = re.compile(r"\b(road|rd|street|st|main|cross|lane|highway|avenue|circle|marga|ring)\b", re.I)
GENERIC_STREET = re.compile(r"^\s*\d+\s*(st|nd|rd|th)?\s*(main|cross|a|b|c|d)?\s*(main|cross)?\s*(road|street|lane)?\s*$", re.I)
ROAD_RADIUS_GENERIC = 4
# Town streets and extensions under a taluk: put them in the taluk town when nothing better is found
TOWN_STREET = re.compile(
    r"\b(road|rd|street|beedi|beedhi|badavane|extension|extention|ward|colony|nagar|nagara|layout|circle|"
    r"galli|bazaar|bazar|pete|pet|block|cross|main|lane|mohalla|halli)\b", re.I)


def spread(centre, i):
    """The i-th point of a small sunflower spiral around a town centre (100–700 m out)."""
    angle = i * 2.39996
    r_km = 0.1 + 0.6 * math.sqrt((i % 60) / 60)
    dlat = r_km / 111.0 * math.cos(angle)
    dlon = r_km / (111.0 * math.cos(math.radians(centre[0]))) * math.sin(angle)
    return (centre[0] + dlat, centre[1] + dlon)


def road_variants(name):
    """Normalised keys to look a street name up by, most specific first."""
    s = re.sub(r"\(.*?(\)|$)", " ", name)
    s = re.split(r"\b(from|between|upto|up to|till)\b", s, flags=re.I)[0]
    s = re.sub(r"^\s*(adjacent to|attached to|towards|near|behind|opp(osite)?\.?)\s+", "", s, flags=re.I)
    s = re.sub(r"\brd\b\.?", "road", s, flags=re.I)
    s = re.sub(r"\bmn\b", "main", s, flags=re.I)
    s = re.sub(r"\bft\b\.?", "feet", s, flags=re.I)
    s = re.sub(r"\bst\b\.?$", "street", s, flags=re.I)
    s = s.strip(" ,.-")
    keys = [norm(s)]
    no_main = re.sub(r"\bmain\b", " ", s, flags=re.I)
    keys.append(norm(no_main))
    if not re.search(r"\b(road|street|lane|cross|main)\b", s, re.I):
        keys.append(norm(s + " road"))
    return [k for i, k in enumerate(keys) if k and len(k) >= 5 and k not in keys[:i]], s


def load_roads(path):
    """Named roads and residential areas: one point per OSM way (its centre)."""
    by_key = defaultdict(list)
    for e in json.load(open(path))["elements"]:
        t = e.get("tags", {})
        c = e.get("center") or ({"lat": e.get("lat"), "lon": e.get("lon")} if "lat" in e else None)
        if not c:
            continue
        pt = (float(c["lat"]), float(c["lon"]))
        names = {t.get(k) for k in ("name", "name:en", "alt_name", "old_name")} - {None}
        for n in names:
            for v in road_variants(n)[0]:
                by_key[v].append((pt, n))
    return by_key


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
        kn = (t.get("name:kn") or "").replace(" ", "")
        places.append({"name": t.get("name"), "names": names, "place": t.get("place"), "kn": kn,
                       "name_kn": t.get("name:kn") or "",
                       "pt": (float(lat), float(lon)),
                       "keys": {norm(n) for n in names if n}})
    return places


def main():
    if len(sys.argv) not in (3, 4):
        sys.exit(__doc__)
    places = load_places(sys.argv[1])
    roads = load_roads(sys.argv[3]) if len(sys.argv) == 4 else {}
    by_key = defaultdict(list)
    for p in places:
        for k in p["keys"]:
            by_key[k].append(p)

    areas = {}
    for f in sorted(glob.glob("data/guidance/*.csv")):
        for r in csv.DictReader(open(f, encoding="utf-8")):
            key = (r["district"], r["parent_name"], r["parent_level"], r["area_name"])
            prev = areas.get(key, ("", "", ""))
            areas[key] = (r["area_level"], (r.get("name_kn") or "").replace(" ", ""),
                          r.get("context") or prev[2])

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
    town_count = Counter()
    nearby = {}
    by_kn = defaultdict(list)
    for p in places:
        if p["kn"]:
            by_kn[p["kn"]].append(p)

    def find(name, near, cand_keys, cand_idx, centre, radius):
        """Exact, then fuzzy, then a place named inside the name. Returns (place, method)."""
        key = norm(name)
        exact = [p for p in by_key.get(key, []) if km(p["pt"], centre) <= radius]
        if exact:
            return min(exact, key=lambda p: km(p["pt"], centre)), "exact"
        best = process.extractOne(key, cand_keys, scorer=fuzz.ratio, score_cutoff=FUZZY_MIN) if key else None
        if best and best[0][:1] == key[:1]:
            return near[cand_idx[best[2]]], "fuzzy"
        words = re.sub(r"\(.*?(\)|$)", " ", name)
        words = re.sub(r"[^A-Za-z0-9 ]", " ", words).split()
        for n in range(min(4, len(words)), 0, -1):
            for i in range(len(words) - n + 1):
                k = norm(" ".join(words[i:i + n]))
                if len(k) < 6:
                    continue
                hits = [p for p in by_key.get(k, []) if km(p["pt"], centre) <= radius]
                if hits:
                    return min(hits, key=lambda p: km(p["pt"], centre)), "contains"
        return None, None

    for (district, parent, plevel, name), (level, name_kn, ctx) in sorted(areas.items()):
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
        kn_hits = [p for p in by_kn.get(name_kn, []) if km(p["pt"], centre) <= radius] if name_kn else []
        if kn_hits:
            pick, method = min(kn_hits, key=lambda p: km(p["pt"], centre)), "kannada"
        elif exact:
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
        if not pick and roads:
            keys, cleaned = road_variants(name)
            generic = bool(GENERIC_STREET.match(cleaned))
            limit = ROAD_RADIUS_GENERIC if generic else radius
            for k in keys:
                hits = [h for h in roads.get(k, []) if km(h[0], centre) <= limit]
                if hits:
                    pt, osm = min(hits, key=lambda h: km(h[0], centre))
                    pick = {"pt": pt, "name": osm, "name_kn": ""}
                    method = "street (generic)" if generic else "street"
                    break
        if not pick and ctx and ctx != name:
            # listed under a locality heading: put it at that locality
            pick, m = find(ctx, near, cand_keys, cand_idx, centre, radius)
            if pick:
                method = "near " + m
        if (not pick and plevel == "taluk" and level == "locality" and centre != BANGALORE
                and TOWN_STREET.search(name)):
            town_count[parent] += 1
            pick = {"pt": spread(centre, town_count[parent]), "name": parent, "name_kn": ""}
            method = "in town (approximate)"
        how[method or "not found"] += 1
        if pick:
            out.append({"district": district, "parent_name": parent, "area_name": name,
                        "lat": f"{pick['pt'][0]:.6f}", "lon": f"{pick['pt'][1]:.6f}",
                        "match": method, "osm_name": pick["name"],
                        # a Kannada name only when it's this place's own, not a nearby one's
                        "osm_name_kn": pick["name_kn"] if method in ("exact", "fuzzy", "kannada") else ""})

    with open(sys.argv[2], "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["district", "parent_name", "area_name", "lat", "lon", "match",
                                           "osm_name", "osm_name_kn"])
        w.writeheader()
        w.writerows(out)
    total = len(areas)
    print(f"{len(out)} of {total} areas located ({len(out) / total:.0%}): "
          + ", ".join(f"{k} {v}" for k, v in how.most_common()))
    if missing_centres:
        print("No OSM place for these offices (searched around central Bangalore):", ", ".join(missing_centres))


if __name__ == "__main__":
    main()
