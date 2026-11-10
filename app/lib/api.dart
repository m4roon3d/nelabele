import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'models.dart';

/// Talks to the Neon Data API.
///
/// Reads use the app's public, read-only token. Logging a market rate needs
/// the owner's private editor key, which is entered once in Settings.
/// URL and public token come from config/data_api.json at build time
/// (flutter build ... --dart-define-from-file=../config/data_api.json).
class NelaBeleApi {
  static const _baseUrl = String.fromEnvironment('data_api_url');
  static const _token = String.fromEnvironment('app_token');
  static const _rateColumns = 'geo_area_id,area_name,name_kn,has_boundary,level,district,parent_name,parent_level,'
      'lat,lon,property_type,guidance_rate,guidance_effective,market_low,market_mid,'
      'market_high,market_obs,confidence,sources,est_low,est_mid,est_high,est_ratio,est_places,'
      'prev_guidance_rate,prev_guidance_effective,guidance_change_pct';

  static bool get isConfigured => _baseUrl.isNotEmpty && _token.isNotEmpty;

  final http.Client _client = http.Client();

  Future<List<dynamic>> _get(String path, Map<String, String> params) async {
    if (!isConfigured) {
      throw const ApiException('The app was built without its Data API settings.');
    }
    final uri = Uri.parse('$_baseUrl/$path').replace(queryParameters: params);
    final http.Response res;
    try {
      res = await _client
          .get(uri, headers: {'Authorization': 'Bearer $_token', 'Accept': 'application/json'})
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      throw const ApiException("Couldn't reach the server. Check your connection and try again.");
    }
    if (res.statusCode != 200) {
      throw ApiException('The server returned an error (${res.statusCode}). Try again shortly.');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
  }

  static List<Area> _group(List<dynamic> rows) {
    final areas = <int, Area>{};
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final id = (row['geo_area_id'] as num).toInt();
      final area = areas.putIfAbsent(id, () => Area.fromJson(row));
      final rate = Rate.fromJson(row);
      area.rates[rate.propertyType] = rate;
    }
    return areas.values.toList();
  }

  /// Areas matching the filters, with their rates, sorted by name.
  Future<List<Area>> fetchAreas({String query = '', String? district, String? type, String? parent}) async {
    final params = <String, String>{
      'select': _rateColumns,
      'order': 'area_name.asc,property_type.asc',
      'limit': parent != null ? '1500' : '200',
    };
    if (parent != null) params['parent_name'] = 'eq.$parent';
    final q = query.trim().replaceAll(RegExp(r'[*,()"]'), ' ').trim();
    if (q.isNotEmpty) {
      if (RegExp(r'[\u0C80-\u0CFF]').hasMatch(q)) {
        params['name_kn'] = 'ilike.*$q*';
      } else {
        params['or'] = '(area_name.ilike."*$q*",name_kn.ilike."*$q*")';
      }
    }
    if (district != null) params['district'] = 'eq.$district';
    if (type != null) params['property_type'] = 'eq.$type';
    return _group(await _get('api_rate', params));
  }

  /// One area with all its rates, or null if it has none.
  Future<Area?> fetchArea(int id) async {
    final areas = _group(await _get('api_rate', {
      'select': _rateColumns,
      'geo_area_id': 'eq.$id',
    }));
    return areas.isEmpty ? null : areas.first;
  }

  /// Areas by id, with all their rates (saved places, comparison).
  Future<List<Area>> fetchAreasByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final areas = _group(await _get('api_rate', {
      'select': _rateColumns,
      'geo_area_id': 'in.(${ids.join(',')})',
    }));
    final order = {for (var i = 0; i < ids.length; i++) ids[i]: i};
    areas.sort((a, b) => (order[a.id] ?? 0).compareTo(order[b.id] ?? 0));
    return areas;
  }

  /// Exact-name lookup used by bulk import: every area called [name].
  Future<List<Area>> findByName(String name) async {
    final n = name.trim().replaceAll(RegExp(r'[*,()"]'), ' ').trim();
    if (n.isEmpty) return [];
    return _group(await _get('api_rate', {
      'select': _rateColumns,
      'area_name': 'ilike.$n',
    }));
  }

  /// Village outlines (GeoJSON geometry) keyed by area id, fetched in pages.
  Future<Map<int, Map<String, dynamic>>> fetchShapes() async {
    const page = 1000;
    final shapes = <int, Map<String, dynamic>>{};
    for (var offset = 0;; offset += page) {
      final batch = await _get('api_area_shape', {
        'select': 'id,shape',
        'order': 'id.asc',
        'limit': '$page',
        'offset': '$offset',
      });
      for (final row in batch.cast<Map<String, dynamic>>()) {
        shapes[(row['id'] as num).toInt()] = (row['shape'] as Map).cast<String, dynamic>();
      }
      if (batch.length < page) break;
    }
    return shapes;
  }

  /// Places with rates nearest a point, closest first, with distance in km.
  /// Looks in a small box around the point and widens it until enough turn up.
  Future<List<(Area, double)>> nearbyAreas(double lat, double lon, {int limit = 15}) async {
    var found = <Area>[];
    for (final d in const [0.02, 0.05, 0.12]) {
      found = _group(await _get('api_rate', {
        'select': _rateColumns,
        'and': '(lat.gte.${lat - d},lat.lte.${lat + d},lon.gte.${lon - d},lon.lte.${lon + d})',
        'limit': '600',
      }));
      if (found.length >= limit) break;
    }
    final withKm = [for (final a in found) if (a.lat != null && a.lon != null) (a, _km(lat, lon, a.lat!, a.lon!))]
      ..sort((x, y) => x.$2.compareTo(y.$2));
    return withKm.take(limit).toList();
  }

  static double _km(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180, dLon = (lon2 - lon1) * pi / 180;
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    return 2 * r * asin(sqrt(h));
  }

  static CityTrend? _trend;

  /// Latest city-wide price change, cached for the session.
  Future<CityTrend?> cityTrend() async {
    if (_trend != null) return _trend;
    try {
      final rows = await _get('api_city_trend', {'select': 'city,period,yoy_pct,measure', 'limit': '1'});
      if (rows.isNotEmpty) _trend = CityTrend.fromJson((rows.first as Map).cast<String, dynamic>());
    } catch (_) {}
    return _trend;
  }

  /// Every area on the map that has a rate of [type], fetched in pages.
  Future<List<Area>> fetchMapAreas(String type) async {
    const page = 1000;
    final rows = <dynamic>[];
    for (var offset = 0;; offset += page) {
      final batch = await _get('api_rate', {
        'select': _rateColumns,
        'property_type': 'eq.$type',
        'lat': 'not.is.null',
        'guidance_rate': 'not.is.null',
        'order': 'geo_area_id.asc',
        'limit': '$page',
        'offset': '$offset',
      });
      rows.addAll(batch);
      if (batch.length < page) break;
    }
    return _group(rows);
  }

  /// Logs a market rate. Needs the editor key.
  Future<void> addMarketRate({
    required String editorKey,
    required int areaId,
    required String propertyType,
    required double rate,
    required String unit,
    required DateTime observedOn,
    required String source,
    String approvalStatus = 'unknown',
    String? note,
    double? lat,
    double? lon,
  }) async {
    final uri = Uri.parse('$_baseUrl/rpc/add_market_rate');
    final body = jsonEncode({
      'area_id': areaId,
      'property_type': propertyType,
      'rate': rate,
      'unit': unit,
      'observed_on': observedOn.toIso8601String().substring(0, 10),
      'approval_status': approvalStatus,
      'source': source,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (lat != null && lon != null) 'lat': lat,
      if (lat != null && lon != null) 'lon': lon,
    });
    final http.Response res;
    try {
      res = await _client
          .post(uri,
              headers: {
                'Authorization': 'Bearer $editorKey',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: body)
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      throw const ApiException("Couldn't reach the server. Check your connection and try again.");
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw const ApiException('Your editor key was not accepted. Check it in Settings.');
    }
    if (res.statusCode >= 300) {
      String message = 'Saving failed (${res.statusCode}).';
      try {
        final j = jsonDecode(utf8.decode(res.bodyBytes));
        if (j is Map && j['message'] is String) message = j['message'] as String;
      } catch (_) {}
      throw ApiException(message);
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
