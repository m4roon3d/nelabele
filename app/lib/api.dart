import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

/// Reads rates from the Neon Data API with the app's read-only token.
/// Both values come from config/data_api.json at build time
/// (flutter build ... --dart-define-from-file=../config/data_api.json).
class NelaBeleApi {
  static const _baseUrl = String.fromEnvironment('data_api_url');
  static const _token = String.fromEnvironment('app_token');

  static bool get isConfigured => _baseUrl.isNotEmpty && _token.isNotEmpty;

  final http.Client _client = http.Client();

  /// Areas matching the filters, with their rates, sorted by name.
  Future<List<Area>> fetchAreas({String query = '', String? taluk, String? type}) async {
    if (!isConfigured) {
      throw const ApiException('The app was built without its Data API settings.');
    }
    final params = <String, String>{
      'select': 'geo_area_id,area_name,level,district,parent_name,property_type,'
          'guidance_rate,guidance_effective,market_low,market_mid,market_high,'
          'market_obs,confidence',
      'order': 'area_name.asc,property_type.asc',
      'limit': '200',
    };
    final q = query.trim().replaceAll(RegExp(r'[*,()]'), ' ');
    if (q.isNotEmpty) params['area_name'] = 'ilike.*$q*';
    if (taluk != null) params['parent_name'] = 'eq.$taluk';
    if (type != null) params['property_type'] = 'eq.$type';

    final uri = Uri.parse('$_baseUrl/api_rate').replace(queryParameters: params);
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

    final rows = (jsonDecode(utf8.decode(res.bodyBytes)) as List).cast<Map<String, dynamic>>();
    final areas = <int, Area>{};
    for (final row in rows) {
      final id = (row['geo_area_id'] as num).toInt();
      final area = areas.putIfAbsent(
        id,
        () => Area(
          id: id,
          name: row['area_name'] as String,
          level: row['level'] as String,
          district: row['district'] as String,
          parentName: row['parent_name'] as String?,
        ),
      );
      final rate = Rate.fromJson(row);
      area.rates[rate.propertyType] = rate;
    }
    return areas.values.toList();
  }
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
