import 'dart:convert';

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
  static const _rateColumns = 'geo_area_id,area_name,level,district,parent_name,parent_level,'
      'lat,lon,property_type,guidance_rate,guidance_effective,market_low,market_mid,'
      'market_high,market_obs,confidence';

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
  Future<List<Area>> fetchAreas({String query = '', String? district, String? type}) async {
    final params = <String, String>{
      'select': _rateColumns,
      'order': 'area_name.asc,property_type.asc',
      'limit': '200',
    };
    final q = query.trim().replaceAll(RegExp(r'[*,()]'), ' ');
    if (q.isNotEmpty) params['area_name'] = 'ilike.*$q*';
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
