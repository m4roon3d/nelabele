import 'dart:convert';
import 'dart:math' show Point;

import 'package:flutter/services.dart' show rootBundle;
import 'package:maplibre_gl/maplibre_gl.dart';

import 'api.dart';
import 'area_sheet.dart';
import 'format.dart';
import 'i18n.dart';
import 'location.dart';
import 'models.dart';
import 'ui.dart';

const _styleLight = 'https://tiles.openfreemap.org/styles/positron';
const _styleDark = 'https://tiles.openfreemap.org/styles/dark';
const _sourceId = 'areas';
const _layerId = 'areas-dots';
const _shapeSourceId = 'area-shapes';
const _fillLayerId = 'areas-fill';
const _lineLayerId = 'areas-outline';
const _mapTypes = ['plot', 'agricultural_land', 'apartment'];
const _infraSourceId = 'infra';
const _infraLayers = ['infra-ring', 'infra-ring-planned', 'infra-metro', 'infra-metro-planned', 'infra-stations', 'infra-places', 'infra-station-names'];
const _meSourceId = 'me';
const _meLayerId = 'me-dot';
const _metroColor = '#7A3E9D';
const _noDataColor = '#B9B2A6';
const _ringColor = '#3D4A5C';
const _metroColorDark = '#C08BE6';
const _ringColorDark = '#AAB6C4';

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
  bool _showInfra = true;
  bool _market = false; // colour by market price (real or estimated) instead of guidance
  int _noData = 0;      // places with no market figure in market mode
  bool _infraAdded = false;
  bool _locating = false;
  bool _dark = false;

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
      final rates = [for (final a in areas) if (_value(a) != null) _value(a)!]..sort();
      _noData = areas.length - rates.length;
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

  /// The figure a place is coloured by: guidance, or market mid (real, else estimated).
  double? _value(Area a) {
    final r = a.rates[_type];
    if (r == null) return null;
    return _market ? r.bestMarketMid : r.guidanceRate;
  }

  Future<void> _setMarket(bool market) async {
    if (market == _market) return;
    setState(() => _market = market);
    await _show(_type);
  }

  Future<void> _draw(List<Area> areas) async {
    final map = _map;
    if (map == null || !_styleReady) return;
    final shapes = await (_shapes ?? Future.value(<int, Map<String, dynamic>>{}));
    // no figure in market mode: -1, drawn grey
    Map<String, dynamic> props(Area a) => {'id': a.id, 'name': a.name, 'rate': _value(a) ?? -1};
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
            _noDataColor, 0,
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
    // infrastructure sits above outlines but below the dots
    if (!_infraAdded) await _addInfra();
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

  /// Metro lines and stations, ring roads and airports (OpenStreetMap), drawn once.
  Future<void> _addInfra() async {
    final map = _map;
    if (map == null || _infraAdded) return;
    _infraAdded = true;
    try {
      final data = jsonDecode(await rootBundle.loadString('assets/infra.geojson')) as Map<String, dynamic>;
      await map.addGeoJsonSource(_infraSourceId, data);
      final metro = _dark ? _metroColorDark : _metroColor;
      final ring = _dark ? _ringColorDark : _ringColor;
      Future<void> line(String id, String kind, String color, double width, {bool dashed = false}) =>
          map.addLineLayer(
            _infraSourceId,
            id,
            LineLayerProperties(
              lineColor: color,
              lineWidth: ['interpolate', ['linear'], ['zoom'], 8, width * 0.6, 14, width * 1.6],
              lineOpacity: dashed ? 0.7 : 0.9,
              lineDasharray: dashed ? [2, 1.5] : null,
              lineCap: dashed ? 'butt' : 'round',
            ),
            filter: ['==', ['get', 'kind'], kind],
          );
      await line('infra-ring', 'ring', ring, 2.2);
      await line('infra-ring-planned', 'ring_planned', ring, 2.2, dashed: true);
      await line('infra-metro', 'metro', metro, 2.6);
      await line('infra-metro-planned', 'metro_planned', metro, 2.6, dashed: true);
      await map.addCircleLayer(
        _infraSourceId,
        'infra-stations',
        CircleLayerProperties(
          circleColor: _dark ? '#161D19' : '#FFFFFF',
          circleStrokeColor: metro,
          circleStrokeWidth: 2,
          circleRadius: ['interpolate', ['linear'], ['zoom'], 9, 2, 14, 5],
        ),
        filter: ['==', ['get', 'kind'], 'station'],
        minzoom: 10,
      );
      SymbolLayerProperties label(double size) => SymbolLayerProperties(
            textField: ['get', 'name'],
            textFont: const ['Noto Sans Regular'],
            textSize: size,
            textColor: metro,
            textHaloColor: _dark ? '#161D19' : '#FFFFFF',
            textHaloWidth: 1.4,
            textOffset: const [0, 1.1],
            textAnchor: 'top',
            textOptional: true,
          );
      await map.addSymbolLayer(_infraSourceId, 'infra-places', label(12),
          filter: ['==', ['get', 'kind'], 'airport']);
      await map.addSymbolLayer(_infraSourceId, 'infra-station-names', label(11),
          filter: ['==', ['get', 'kind'], 'station'], minzoom: 12.5);
      if (!_showInfra) await _setInfraVisible(false);
    } catch (_) {
      _infraAdded = false;
    }
  }

  Future<void> _setInfraVisible(bool visible) async {
    final map = _map;
    if (map == null) return;
    for (final id in _infraLayers) {
      try {
        await map.setLayerVisibility(id, visible);
      } catch (_) {}
    }
  }

  Future<void> _locate() async {
    final map = _map;
    if (map == null) return;
    setState(() => _locating = true);
    try {
      final here = await currentLocation();
      final me = {
        'type': 'FeatureCollection',
        'features': [
          {'type': 'Feature', 'geometry': {'type': 'Point', 'coordinates': [here.lon, here.lat]}, 'properties': {}},
        ],
      };
      try {
        await map.setGeoJsonSource(_meSourceId, me);
      } catch (_) {
        await map.addGeoJsonSource(_meSourceId, me);
        await map.addCircleLayer(
          _meSourceId,
          _meLayerId,
          const CircleLayerProperties(
            circleColor: '#1A73E8',
            circleRadius: 7,
            circleStrokeColor: '#FFFFFF',
            circleStrokeWidth: 2.5,
          ),
        );
      }
      await map.animateCamera(CameraUpdate.newLatLngZoom(LatLng(here.lat, here.lon), 13.5));
      if (outsideCoverage(here) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You seem to be outside the area NelaBele covers.'),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
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
      0 => t('under {rate}', {'rate': fmt(_breaks[0])}),
      4 => t('over {rate}', {'rate': fmt(_breaks[3])}),
      _ => '${fmt(_breaks[band - 1])} – ${fmt(_breaks[band])}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    _dark = dark;
    return Stack(
      children: [
        MapLibreMap(
          // a new map when the theme flips, so the style and our layers load fresh
          key: ValueKey(dark),
          styleString: dark ? _styleDark : _styleLight,
          initialCameraPosition: const CameraPosition(target: LatLng(13.05, 77.6), zoom: 9.3),
          minMaxZoomPreference: const MinMaxZoomPreference(7, 17),
          compassEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          onMapCreated: (c) {
            _map = c;
            _styleReady = false;
            _infraAdded = false;
          },
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    avatar: const Icon(Icons.train_outlined, size: 18),
                    label: const Text('Metro & roads'),
                    selected: _showInfra,
                    showCheckmark: false,
                    onSelected: (on) {
                      setState(() => _showInfra = on);
                      _setInfraVisible(on);
                    },
                    backgroundColor: scheme.surfaceContainerLow,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 54,
          left: 16,
          child: SegmentedButton<bool>(
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              backgroundColor: scheme.surfaceContainerLow,
            ),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('Guidance')),
              ButtonSegment(value: true, label: Text('Market')),
            ],
            selected: {_market},
            onSelectionChanged: (v) => _setMarket(v.first),
          ),
        ),
        if (_loading) const Positioned(top: 100, left: 0, right: 0, child: Center(child: CircularProgressIndicator())),
        if (_error != null)
          Positioned(
            top: 100,
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
          right: 12,
          bottom: 56,
          child: FloatingActionButton.small(
            heroTag: 'locate',
            tooltip: t('Show where I am'),
            onPressed: _locating ? null : _locate,
            child: _locating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
          ),
        ),
        Positioned(
          right: 8,
          bottom: 34,
          child: Text(
            'Outlines: Census 2011 via DataMeet · Metro & roads: © OpenStreetMap',
            style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 9),
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
                    Text(
                      '${propertyLabel(_type)} · ${_market ? t('market (incl. estimates)') : t('guidance value')}',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    if (_showInfra) ...[
                      const SizedBox(height: 2),
                      _LineKey(color: dark ? _metroColorDark : _metroColor, label: 'Metro', dashedLabel: 'building'),
                      _LineKey(color: dark ? _ringColorDark : _ringColor, label: 'Ring roads', dashedLabel: 'planned'),
                      const SizedBox(height: 4),
                    ],
                    if (_market && _noData > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: _hex(_noDataColor), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text('no market figure yet', style: theme.textTheme.bodySmall),
                        ]),
                      ),
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

Color _hex(String hex) => Color(int.parse('FF${hex.substring(1)}', radix: 16));

/// Legend row: a solid and a dashed line sample.
class _LineKey extends StatelessWidget {
  const _LineKey({required this.color, required this.label, required this.dashedLabel});

  final String color;
  final String label;
  final String dashedLabel;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final c = _hex(color);
    Widget dash(bool dashed) => SizedBox(
          width: 16,
          height: 3,
          child: dashed
              ? Row(children: [
                  Expanded(child: Container(color: c)),
                  const SizedBox(width: 2),
                  Expanded(child: Container(color: c)),
                  const SizedBox(width: 2),
                  Expanded(child: Container(color: c)),
                ])
              : Container(color: c),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        dash(false),
        const SizedBox(width: 6),
        Text(label, style: style),
        const SizedBox(width: 8),
        dash(true),
        const SizedBox(width: 4),
        Text(dashedLabel, style: style),
      ]),
    );
  }
}
