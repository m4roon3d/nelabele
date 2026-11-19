import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

/// A metro station or road and how far it is, in km as the crow flies.
class Nearby {
  const Nearby(this.name, this.km, {this.planned = false});

  final String name;
  final double km;
  final bool planned;
}

/// Metro stations and ring roads from the map layer bundled with the app
/// (assets/infra.geojson, from OpenStreetMap), for "how far to the metro".
class Infra {
  Infra._(this._stations, this._roads);

  static Future<Infra>? _loading;

  /// Loaded once, the first time a rate card asks.
  static Future<Infra> load() => _loading ??= _read();

  final List<(String, double, double, bool)> _stations; // name, lat, lon, planned
  final Map<String, List<(List<(double, double)>, bool)>> _roads; // name -> [(line, planned)]

  static Future<Infra> _read() async {
    final data = jsonDecode(await rootBundle.loadString('assets/infra.geojson')) as Map<String, dynamic>;
    final stations = <(String, double, double, bool)>[];
    final roads = <String, List<(List<(double, double)>, bool)>>{};
    for (final f in (data['features'] as List).cast<Map<String, dynamic>>()) {
      final p = (f['properties'] as Map).cast<String, dynamic>();
      final g = (f['geometry'] as Map).cast<String, dynamic>();
      final kind = p['kind'] as String?;
      final name = p['name'] as String? ?? '';
      if (kind == 'station' && g['type'] == 'Point') {
        final c = g['coordinates'] as List;
        stations.add((name, (c[1] as num).toDouble(), (c[0] as num).toDouble(), p['planned'] == true));
      } else if (kind == 'ring' || kind == 'ring_planned') {
        final parts = g['type'] == 'LineString' ? [g['coordinates'] as List] : (g['coordinates'] as List);
        for (final part in parts) {
          final line = [
            for (final c in part as List) ((c as List)[1] as num).toDouble(),
          ];
          final lons = [for (final c in part) ((c as List)[0] as num).toDouble()];
          roads.putIfAbsent(name, () => []).add((
            [for (var i = 0; i < line.length; i++) (line[i], lons[i])],
            kind == 'ring_planned',
          ));
        }
      }
    }
    return Infra._(stations, roads);
  }

  /// Nearest open metro station, and a planned one too if it is closer.
  List<Nearby> stations(double lat, double lon) {
    Nearby? open, planned;
    for (final (name, la, lo, isPlanned) in _stations) {
      final d = _km(lat, lon, la, lo);
      if (isPlanned) {
        if (planned == null || d < planned.km) planned = Nearby(name, d, planned: true);
      } else if (open == null || d < open.km) {
        open = Nearby(name, d);
      }
    }
    return [
      if (open != null) open,
      if (planned != null && (open == null || planned.km < open.km)) planned,
    ];
  }

  /// Distance to each ring road (ORR, STRR, the PRR), nearest first, within [maxKm].
  List<Nearby> roads(double lat, double lon, {double maxKm = 25}) {
    final out = <Nearby>[];
    for (final MapEntry(key: name, value: lines) in _roads.entries) {
      var best = double.infinity;
      var bestPlanned = false;
      for (final (line, isPlanned) in lines) {
        for (var i = 1; i < line.length; i++) {
          final d = _toSegment(lat, lon, line[i - 1], line[i]);
          if (d < best) {
            best = d;
            bestPlanned = isPlanned;
          }
        }
      }
      if (best <= maxKm) out.add(Nearby(name, best, planned: bestPlanned));
    }
    out.sort((a, b) => a.km.compareTo(b.km));
    return out;
  }

  static double _km(double lat1, double lon1, double lat2, double lon2) {
    final x = (lon2 - lon1) * 111.32 * math.cos((lat1 + lat2) / 2 * math.pi / 180);
    final y = (lat2 - lat1) * 110.57;
    return math.sqrt(x * x + y * y);
  }

  /// Km from a point to a line segment, on a flat projection around the point.
  static double _toSegment(double lat, double lon, (double, double) a, (double, double) b) {
    final k = 111.32 * math.cos(lat * math.pi / 180);
    final ax = (a.$2 - lon) * k, ay = (a.$1 - lat) * 110.57;
    final bx = (b.$2 - lon) * k, by = (b.$1 - lat) * 110.57;
    final dx = bx - ax, dy = by - ay;
    final len2 = dx * dx + dy * dy;
    final t = len2 == 0 ? 0.0 : (-(ax * dx + ay * dy) / len2).clamp(0.0, 1.0);
    final px = ax + t * dx, py = ay + t * dy;
    return math.sqrt(px * px + py * py);
  }
}

/// "1.9 km" / "650 m".
String kmLabel(double km) => km < 1 ? '${(km * 1000 / 50).round() * 50} m' : '${km.toStringAsFixed(1)} km';
