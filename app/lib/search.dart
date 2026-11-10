import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Rebuilt after every data load by the "Load data" workflow.
const _indexUrl = 'https://raw.githubusercontent.com/m4roon3d/nelabele/main/data/search/index.json';
const _cacheKey = 'search_index';
const _cacheAtKey = 'search_index_at';

/// Lower-case, letters and digits only, with common spelling variants made equal:
/// "J.P. Nagar" = "jp nagara", "Marathahalli" ≈ "Marthahally", "Bengaluru" = "Bengalooru".
String searchKey(String s) {
  var t = ' ${s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ')} ';
  const words = [
    (r'(hally|halli|hali|hal)\b', 'halli'),
    (r'puram\b', 'pur'),
    (r'pura\b', 'pur'),
    (r'palaya\b', 'palya'),
    (r'nagara\b', 'nagar'),
    (r'agrahara\b', 'agrahar'),
    (r'(ooru|uru)\b', 'ur'),
    (r'\blayout\b', 'layout'),
  ];
  for (final (pattern, to) in words) {
    t = t.replaceAll(RegExp(pattern), to);
  }
  const letters = [
    ('aa', 'a'), ('ee', 'i'), ('oo', 'u'), ('ou', 'u'),
    ('th', 't'), ('dh', 'd'), ('bh', 'b'), ('kh', 'k'), ('gh', 'g'), ('sh', 's'), ('ph', 'p'),
    ('w', 'v'), ('z', 'j'),
  ];
  for (final (from, to) in letters) {
    t = t.replaceAll(from, to);
  }
  t = t.replaceAll(' ', '');
  return t.replaceAllMapped(RegExp(r'(.)\1+'), (m) => m[1]!);
}

/// Old and new spellings of the same town, as search keys.
const _aliases = {
  'tumkur': 'tumakur',
  'bangalore': 'bengalur',
  'bangalur': 'bengalur',
  'chikbalapur': 'chikabalapur',
  'mysore': 'mysur',
  'ramnagar': 'ramanagar',
  'dodbalapur': 'dodabalapur',
};

Set<String> _trigrams(String s) => {for (var i = 0; i + 3 <= s.length; i++) s.substring(i, i + 3)};

/// 0..1: how alike two keys are, by shared three-letter pieces.
double _alike(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) return 0;
  final common = a.where(b.contains).length;
  return 2 * common / (a.length + b.length);
}

final _kannada = RegExp(r'[ಀ-೿]');

class IndexPlace {
  IndexPlace(this.id, this.name, this.nameKn, this.parent, this.district, this.lat, this.lon)
      : key = searchKey(name),
        kn = nameKn.replaceAll(' ', '');
  final int id;
  final String name;
  final String nameKn;
  final int parent;
  final String district;
  final double? lat;
  final double? lon;
  final String key;
  final String kn;
  Set<String>? _tri;
  Set<String> get tri => _tri ??= _trigrams(key);
}

/// An area (taluk or city zone) whose name matched.
class AreaHit {
  AreaHit(this.name, this.district, this.places);
  final String name;
  final String district;
  final int places;
}

class SearchResult {
  SearchResult({required this.areas, required this.places, this.nearLabel, this.near = const []});
  final List<AreaHit> areas;
  final List<int> places;                 // best matches first
  final String? nearLabel;                // "Electronic City", "Sarjapura Road"
  final List<(int, double)> near;         // places near that, with km
}

/// All place names, searched on the device: instant, offline and forgiving.
class SearchIndex {
  SearchIndex._(this.places, this.parents, this._osm, this._roads);

  final List<IndexPlace> places;
  final List<(String, String)> parents; // name, district
  final List<(String, String, double, double, Set<String>)> _osm; // name, key, lat, lon, trigrams
  final List<(String, String, List<double>, Set<String>)> _roads; // name, key, lat/lon pairs, trigrams

  static final ValueNotifier<SearchIndex?> current = ValueNotifier<SearchIndex?>(null);

  /// Loads the cached index straight away, then refreshes it if it is a day old.
  static Future<void> load() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) current.value = _parse(cached);
      final at = DateTime.tryParse(prefs.getString(_cacheAtKey) ?? '');
      if (cached != null && at != null && DateTime.now().difference(at).inHours < 24) return;
    } catch (_) {}
    try {
      final res = await http.get(Uri.parse(_indexUrl)).timeout(const Duration(seconds: 40));
      if (res.statusCode != 200) return;
      final body = utf8.decode(res.bodyBytes);
      current.value = _parse(body);
      try {
        await prefs?.setString(_cacheKey, body);
        await prefs?.setString(_cacheAtKey, DateTime.now().toIso8601String());
      } catch (_) {} // too big for this browser's storage: fine, it is fetched again next time
    } catch (_) {}
  }

  static SearchIndex _parse(String body) {
    final j = jsonDecode(body) as Map<String, dynamic>;
    final districts = (j['districts'] as List).cast<String>();
    final parents = [for (final p in j['parents'] as List) ((p as List)[0] as String, districts[p[1] as int])];
    double? d(Object? v) => (v as num?)?.toDouble();
    final places = [
      for (final p in j['places'] as List)
        IndexPlace((p as List)[0] as int, p[1] as String, p[2] as String, p[3] as int, districts[p[4] as int],
            d(p[5]), d(p[6])),
    ];
    final osm = [
      for (final o in j['osm'] as List)
        ((o as List)[0] as String, searchKey(o[0] as String), d(o[1])!, d(o[2])!, _trigrams(searchKey(o[0] as String))),
    ];
    final roads = <(String, String, List<double>, Set<String>)>[];
    for (final r in j['roads'] as List) {
      final name = (r as List)[0] as String;
      final k = searchKey(name.replaceAll(RegExp(r'\bmain\b', caseSensitive: false), ''));
      roads.add((name, k, [for (final v in r[1] as List) (v as num).toDouble()], _trigrams(k)));
    }
    return SearchIndex._(places, parents, osm, roads);
  }

  static double km(double lat1, double lon1, double lat2, double lon2) {
    final x = (lon2 - lon1) * cos((lat1 + lat2) / 2 * pi / 180);
    final y = lat2 - lat1;
    return sqrt(x * x + y * y) * 111.2;
  }

  /// How well a name key matches the query key: 0 (no) .. 100 (exact).
  static double _score(String q, Set<String> qTri, String key, Set<String> Function() tri) {
    if (key == q) return 100;
    if (key.startsWith(q)) return 92 - min(10, (key.length - q.length) / 4);
    if (key.contains(q)) return 80 - min(10, (key.length - q.length) / 6);
    if (q.length >= 5) {
      final a = _alike(qTri, tri());
      if (a >= 0.55) return 40 + a * 30;
    }
    return 0;
  }

  SearchResult search(String query, {String? district}) {
    final raw = query.trim();
    if (raw.isEmpty) return SearchResult(areas: const [], places: const []);
    bool inDistrict(String d) => district == null || d == district;

    // Kannada: plain substring on the Kannada name
    if (_kannada.hasMatch(raw)) {
      final q = raw.replaceAll(' ', '');
      final hits = [for (final p in places) if (inDistrict(p.district) && p.kn.contains(q)) p];
      hits.sort((a, b) => a.kn.length.compareTo(b.kn.length));
      return SearchResult(areas: const [], places: [for (final p in hits.take(80)) p.id]);
    }

    var q = searchKey(raw);
    q = _aliases[q] ?? q;
    if (q.length < 2) return SearchResult(areas: const [], places: const []);
    final qTri = _trigrams(q);

    // areas: taluks and city zones
    final counts = <int, int>{};
    for (final p in places) {
      counts[p.parent] = (counts[p.parent] ?? 0) + 1;
    }
    final areas = <(double, AreaHit)>[];
    for (var i = 0; i < parents.length; i++) {
      final (name, d) = parents[i];
      if (!inDistrict(d) || name.isEmpty) continue;
      final k = searchKey(name);
      final s = _score(q, qTri, k, () => _trigrams(k));
      if (s >= 70) areas.add((s, AreaHit(name, d, counts[i] ?? 0)));
    }
    areas.sort((a, b) => b.$1.compareTo(a.$1));

    // places
    final scored = <(double, IndexPlace)>[];
    for (final p in places) {
      if (!inDistrict(p.district)) continue;
      final s = _score(q, qTri, p.key, () => p.tri);
      if (s > 0) scored.add((s, p));
    }
    scored.sort((a, b) => b.$1 != a.$1 ? b.$1.compareTo(a.$1) : a.$2.name.length.compareTo(b.$2.name.length));
    final strong = scored.isNotEmpty && scored.first.$1 >= 80;

    // a popular name the gazettes don't use: places near it (neighbourhood) or along it (road)
    String? nearLabel;
    var near = <(int, double)>[];
    var bestOsm = (0.0, -1);
    for (var i = 0; i < _osm.length; i++) {
      final s = _score(q, qTri, _osm[i].$2, () => _osm[i].$5);
      if (s > bestOsm.$1) bestOsm = (s, i);
    }
    // roads are keyed without "main": "Bagalur Main Road" = "Bagalur Road"
    final qRoad = searchKey(raw.replaceAll(RegExp(r'\bmain\b', caseSensitive: false), ''));
    final qRoadTri = _trigrams(qRoad);
    var bestRoad = (0.0, -1);
    for (var i = 0; i < _roads.length; i++) {
      final s = _score(qRoad, qRoadTri, _roads[i].$2, () => _roads[i].$4);
      if (s > bestRoad.$1) bestRoad = (s, i);
    }
    final roadWins = bestRoad.$1 >= 80 && bestRoad.$1 >= bestOsm.$1;
    if (roadWins) {
      final (name, _, pts, _) = _roads[bestRoad.$2];
      nearLabel = name;
      for (final p in places) {
        if (p.lat == null || !inDistrict(p.district)) continue;
        var bestKm = double.infinity;
        for (var j = 0; j + 1 < pts.length; j += 2) {
          final k = km(p.lat!, p.lon!, pts[j], pts[j + 1]);
          if (k < bestKm) bestKm = k;
        }
        if (bestKm <= 0.8) near.add((p.id, bestKm));
      }
    } else if (bestOsm.$1 >= (strong ? 90 : 75)) {
      final (name, _, lat, lon, _) = _osm[bestOsm.$2];
      nearLabel = name;
      final all = <(int, double)>[
        for (final p in places)
          if (p.lat != null && inDistrict(p.district)) (p.id, km(lat, lon, p.lat!, p.lon!)),
      ];
      // widen the circle until enough places turn up
      for (final radius in const [2.5, 4.0, 6.0]) {
        near = [for (final h in all) if (h.$2 <= radius) h];
        if (near.length >= 10) break;
      }
    }
    near.sort((a, b) => a.$2.compareTo(b.$2));
    near = near.take(60).toList();
    if (near.isEmpty) nearLabel = null;

    final placeIds = [for (final (s, p) in scored) if (s >= (strong ? 60 : 40)) p.id];
    return SearchResult(
      areas: [for (final (_, a) in areas.take(3)) a],
      places: placeIds.take(80).toList(),
      nearLabel: nearLabel,
      near: near,
    );
  }
}
