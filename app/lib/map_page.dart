import 'dart:convert';
import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'api.dart';
import 'area_sheet.dart';
import 'format.dart';
import 'models.dart';

const _styleUrl = 'https://tiles.openfreemap.org/styles/positron';
const _sourceId = 'areas';
const _layerId = 'areas-dots';
const _shapeSourceId = 'area-shapes';
const _fillLayerId = 'areas-fill';
const _lineLayerId = 'areas-outline';
const _mapTypes = ['plot', 'agricultural_land', 'apartment'];

/// Five rate bands, cheapest to priciest: field green through to deep red earth.
const _bandColors = ['#5C8A38', '#A3B84A', '#E3A21A', '#D9774A', '#9C3F1C'];

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _api = NelaBeleApi();
  MapLibreMapController? _map;
  bool _styleReady = false;
  String _type = 'plot';
  final Map<String, List<Area>> _cache = {};
  Future<Map<int, Map<String, dynamic>>>? _shapes;
  List<double> _breaks = [];
  bool _loading = false;
  String? _error;

  Future<void> _show(String type) async {
    setState(() {
      _type = type;
      _loading = true;
      _error = null;
    });
    try {
      // outlines are the same for every type: fetch once, alongside the first rates
      _shapes ??= _api.fetchShapes().catchError((_) => <int, Map<String, dynamic>>{});
      final areas = _cache[type] ??= await _api.fetchMapAreas(type);
      await _shapes;
      if (!mounted || _type != type) return;
      final rates = [for (final a in areas) a.rates[type]!.guidanceRate!]..sort();
      _breaks = rates.isEmpty
          ? []
          : [for (final q in [0.2, 0.4, 0.6, 0.8]) rates[(q * (rates.length - 1)).round()]];
      await _draw(areas);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  /// First label layer of the base map, so outlines sit beneath place names.
  Future<String?> _firstLabelLayer(MapLibreMapController map) async {
    try {
      final ids = await map.getLayerIds();
      for (final id in ids) {
        final s = id.toString();
        if (s.contains('label') || s.contains('name') || s.startsWith('place') || s.contains('poi')) return s;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _draw(List<Area> areas) async {
    final map = _map;
    if (map == null || !_styleReady) return;
    final shapes = await (_shapes ?? Future.value(<int, Map<String, dynamic>>{}));
    Map<String, dynamic> props(Area a) => {'id': a.id, 'name': a.name, 'rate': a.rates[_type]!.guidanceRate};
    final geojson = {
      'type': 'FeatureCollection',
      'features': [
        for (final a in areas)
          if (!shapes.containsKey(a.id))
            {
              'type': 'Feature',
              'id': a.id,
              'geometry': {'type': 'Point', 'coordinates': [a.lon, a.lat]},
              'properties': props(a),
            },
      ],
    };
    final shapeJson = {
      'type': 'FeatureCollection',
      'features': [
        for (final a in areas)
          if (shapes.containsKey(a.id))
            {'type': 'Feature', 'id': a.id, 'geometry': shapes[a.id], 'properties': props(a)},
      ],
    };
    final color = _breaks.length == 4
        ? [
            'step', ['get', 'rate'],
            _bandColors[0], _breaks[0], _bandColors[1], _breaks[1], _bandColors[2],
            _breaks[2], _bandColors[3], _breaks[3], _bandColors[4],
          ]
        : _bandColors[2];
    for (final id in [_layerId, _fillLayerId, _lineLayerId]) {
      try {
        await map.removeLayer(id);
      } catch (_) {}
    }
    for (final id in [_sourceId, _shapeSourceId]) {
      try {
        await map.removeSource(id);
      } catch (_) {}
    }
    await map.addGeoJsonSource(_shapeSourceId, shapeJson);
    final below = await _firstLabelLayer(map);
    await map.addFillLayer(
      _shapeSourceId,
      _fillLayerId,
      FillLayerProperties(
        fillColor: color,
        fillOpacity: ['interpolate', ['linear'], ['zoom'], 8, 0.7, 13, 0.45],
      ),
      belowLayerId: below,
    );
    await map.addLineLayer(
      _shapeSourceId,
      _lineLayerId,
      LineLayerProperties(
        lineColor: '#FBF6EE',
        lineWidth: ['interpolate', ['linear'], ['zoom'], 8, 0.3, 13, 1.2],
      ),
      belowLayerId: below,
    );
    await map.addGeoJsonSource(_sourceId, geojson);
    await map.addCircleLayer(
      _sourceId,
      _layerId,
      CircleLayerProperties(
        circleColor: color,
        circleRadius: ['interpolate', ['linear'], ['zoom'], 8, 4, 11, 7, 14, 11],
        circleStrokeColor: '#FBF6EE',
        circleStrokeWidth: 1.2,
        circleOpacity: 0.92,
      ),
    );
  }

  Future<void> _onTap(Point<double> point, LatLng _) async {
    final map = _map;
    if (map == null) return;
    final features = await map.queryRenderedFeatures(point, [_layerId, _fillLayerId], null);
    if (features.isEmpty || !mounted) return;
    var f = features.first;
    if (f is String) f = jsonDecode(f);
    final props = (f as Map)['properties'] as Map?;
    final id = (props?['id'] as num?)?.toInt();
    if (id == null) return;
    try {
      final area = await _api.fetchArea(id);
      if (area != null && mounted) await showAreaSheet(context, area);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  String _legendLabel(int band) {
    String fmt(double v) => headline(_type, v);
    if (_breaks.length != 4) return '';
    return switch (band) {
      0 => 'under ${fmt(_breaks[0])}',
      4 => 'over ${fmt(_breaks[3])}',
      _ => '${fmt(_breaks[band - 1])} – ${fmt(_breaks[band])}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Stack(
      children: [
        MapLibreMap(
          styleString: _styleUrl,
          initialCameraPosition: const CameraPosition(target: LatLng(13.05, 77.6), zoom: 9.3),
          minMaxZoomPreference: const MinMaxZoomPreference(7, 17),
          compassEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          onMapCreated: (c) => _map = c,
          onStyleLoadedCallback: () {
            _styleReady = true;
            _show(_type);
          },
          onMapClick: _onTap,
        ),
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final t in _mapTypes)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(propertyLabel(t)),
                      selected: _type == t,
                      onSelected: (_) => _show(t),
                      backgroundColor: scheme.surfaceContainerLow,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_loading) const Positioned(top: 60, left: 0, right: 0, child: Center(child: CircularProgressIndicator())),
        if (_error != null)
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_off),
                title: Text(_error!),
                trailing: TextButton(onPressed: () => _show(_type), child: const Text('Retry')),
              ),
            ),
          ),
        Positioned(
          right: 8,
          bottom: 34,
          child: Text(
            'Village outlines: Census 2011 via DataMeet (ODbL)',
            style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFF6B6157), fontSize: 9),
          ),
        ),
        if (_breaks.length == 4)
          Positioned(
            left: 12,
            bottom: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${propertyLabel(_type)} · guidance value', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 6),
                    for (var b = 4; b >= 0; b--)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(int.parse('FF${_bandColors[b].substring(1)}', radix: 16)),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(_legendLabel(b), style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
