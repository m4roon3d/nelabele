import 'dart:async';

import 'package:flutter/material.dart';

import 'api.dart';
import 'area_sheet.dart';
import 'format.dart';
import 'location.dart';
import 'models.dart';
import 'search.dart';

const _districts = ['Bangalore Urban', 'Bangalore Rural', 'Ramanagara', 'Tumakuru', 'Kolar', 'Chikkaballapura'];
const _types = ['plot', 'agricultural_land', 'apartment'];

/// Searchable list of places and their rates.
class RatesListView extends StatefulWidget {
  const RatesListView({super.key});

  @override
  State<RatesListView> createState() => _RatesListViewState();
}

class _RatesListViewState extends State<RatesListView> {
  final _api = NelaBeleApi();
  final _search = TextEditingController();
  Timer? _debounce;
  int _requestId = 0;

  String? _district;
  String? _type;
  bool _loading = true;
  String? _error;
  List<Area> _areas = [];
  Map<int, double>? _nearKm; // set while showing places near the user
  bool _locating = false;

  // search extras
  String? _parent;                    // showing every place in one taluk / city area
  List<AreaHit> _areaHits = const [];  // areas whose name matched
  List<Area> _nearAreas = const [];    // places near / along a popular name
  Map<int, double> _km = const {};
  String? _nearTitle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _nearMe() async {
    final id = ++_requestId;
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final here = await currentLocation();
      if (outsideCoverage(here)) {
        throw const LocationException('You seem to be outside Bengaluru and nearby districts, which NelaBele covers.');
      }
      final near = await _api.nearbyAreas(here.lat, here.lon);
      if (id != _requestId || !mounted) return;
      _search.clear();
      setState(() {
        _district = null;
        _type = null;
        _parent = null;
        _areaHits = const [];
        _nearAreas = const [];
        _nearTitle = null;
        _areas = [for (final (a, _) in near) a];
        _nearKm = {for (final (a, km) in near) a.id: km};
        _locating = false;
        _loading = false;
      });
    } catch (e) {
      if (id != _requestId || !mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _load() async {
    _nearKm = null;
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final q = _search.text.trim();
      final index = SearchIndex.current.value;
      var areas = <Area>[];
      var nearAreas = <Area>[];
      var km = <int, double>{};
      String? nearTitle;
      var hits = const <AreaHit>[];
      if (_parent != null) {
        areas = await _api.fetchAreas(parent: _parent, district: _district, type: _type);
      } else if (q.isNotEmpty && index != null) {
        final r = index.search(q, district: _district);
        final nearIds = [for (final (pid, _) in r.near) if (!r.places.contains(pid)) pid];
        final ids = [...r.places, ...nearIds];
        final fetched = ids.isEmpty ? <Area>[] : await _api.fetchAreasByIds(ids.take(140).toList());
        final byId = {for (final a in fetched) a.id: a};
        bool keep(Area? a) => a != null && (_type == null || a.rates[_type] != null);
        areas = [for (final pid in r.places) if (keep(byId[pid])) byId[pid]!];
        nearAreas = [for (final pid in nearIds) if (keep(byId[pid])) byId[pid]!];
        km = {for (final (pid, d) in r.near) pid: d};
        nearTitle = r.nearLabel == null
            ? null
            : RegExp(r'\b(road|highway|bypass|marga)\b', caseSensitive: false).hasMatch(r.nearLabel!)
                ? 'Along ${r.nearLabel}'
                : 'Near ${r.nearLabel}';
        hits = r.areas;
      } else {
        areas = await _api.fetchAreas(query: q, district: _district, type: _type);
      }
      if (id != _requestId || !mounted) return;
      setState(() {
        _areas = areas;
        _nearAreas = nearAreas;
        _km = km;
        _nearTitle = nearAreas.isEmpty ? null : nearTitle;
        _areaHits = hits;
        _loading = false;
      });
    } catch (e) {
      if (id != _requestId || !mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openArea(AreaHit a) {
    _search.clear();
    setState(() {
      _parent = a.name;
      _district = a.district;
    });
    _load();
  }

  void _onSearchChanged(String _) {
    _parent = null;
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: SearchIndex.current.value != null ? 200 : 350), _load);
    setState(() {}); // updates the clear button
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search a place · ಸ್ಥಳ ಹುಡುಕಿ',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? IconButton(
                        tooltip: 'Places near me',
                        icon: _locating
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location),
                        onPressed: _locating ? null : _nearMe,
                      )
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          _load();
                        },
                      ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          _ChipRow(
            options: _districts,
            labelOf: (d) => d.replaceFirst('Bangalore ', ''),
            selected: _district,
            allLabel: 'All areas',
            onSelected: (d) {
              setState(() => _district = d);
              _load();
            },
          ),
          _ChipRow(
            options: _types,
            labelOf: propertyLabel,
            selected: _type,
            allLabel: 'All types',
            onSelected: (t) {
              setState(() => _type = t);
              _load();
            },
          ),
          if (_parent != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
              child: Row(
                children: [
                  Icon(Icons.layers_outlined, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(child: Text('All places in $_parent area', style: theme.textTheme.titleSmall)),
                  TextButton(
                    onPressed: () {
                      setState(() => _parent = null);
                      _load();
                    },
                    child: const Text('Show all'),
                  ),
                ],
              ),
            ),
          if (_nearKm != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
              child: Row(
                children: [
                  Icon(Icons.near_me, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Places near you', style: theme.textTheme.titleSmall)),
                  TextButton(onPressed: _load, child: const Text('Show all')),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Expanded(child: _body(theme)),
        ],
    );
  }

  Widget _body(ThemeData theme) {
    if (_loading && _areas.isEmpty && _nearAreas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _Message(
        icon: Icons.cloud_off,
        text: _error!,
        action: FilledButton.tonal(onPressed: _load, child: const Text('Try again')),
      );
    }
    if (_areas.isEmpty && _nearAreas.isEmpty && _areaHits.isEmpty) {
      return const _Message(icon: Icons.search_off, text: 'No places match. Try another spelling or a nearby place.');
    }
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final items = <Widget>[
      for (final a in _areaHits)
        Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          color: theme.colorScheme.secondaryContainer,
          child: ListTile(
            leading: Icon(Icons.layers_outlined, color: theme.colorScheme.onSecondaryContainer),
            title: Text('${a.name} area', style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
            subtitle: Text('${a.places} places · ${a.district}',
                style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
            trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSecondaryContainer),
            onTap: () => _openArea(a),
          ),
        ),
      for (final a in _areas) _AreaCard(area: a, km: _nearKm?[a.id]),
      if (_nearTitle != null) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
          child: Row(children: [
            Icon(Icons.near_me_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(child: Text(_nearTitle!, style: theme.textTheme.titleSmall)),
          ]),
        ),
        for (final a in _nearAreas) _AreaCard(area: a, km: _km[a.id]),
      ],
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _nearKm != null || _nearTitle != null
              ? 'Distances are to the middle of each place. Place names nearby come from OpenStreetMap.'
              : _areas.length >= 100
                  ? 'Showing the first ${_areas.length} places. Search to narrow down.'
                  : 'Government guidance values. Market prices are usually higher.',
          textAlign: TextAlign.center,
          style: muted,
        ),
      ),
    ];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        itemCount: items.length,
        itemBuilder: (context, i) => items[i],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.allLabel,
    required this.onSelected,
  });

  final List<String> options;
  final String Function(String) labelOf;
  final String? selected;
  final String allLabel;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(allLabel),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final o in options)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(labelOf(o)),
                selected: selected == o,
                onSelected: (on) => onSelected(on ? o : null),
              ),
            ),
        ],
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area, this.km});

  final Area area;
  final double? km;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showAreaSheet(context, area),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: area.name),
                  if (area.nameKn != null)
                    TextSpan(
                      text: '  ${area.nameKn}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                    ),
                ]),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                  km == null
                      ? area.subtitle
                      : '${km! < 1 ? '${(km! * 1000).round()} m' : '${km!.toStringAsFixed(1)} km'} away · ${area.subtitle}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in area.sortedRates)
                    if (r.guidanceRate != null)
                      _RatePill(
                        label: propertyLabel(r.propertyType),
                        value: headline(r.propertyType, r.guidanceRate!),
                        extra: [
                          if (r.revised) changeLabel(r.guidanceChangePct!),
                          if (r.marketRatio != null)
                            'market ${r.marketRatio!.toStringAsFixed(1)}×'
                          else if (r.hasEstimate)
                            'est. ~${headline(r.propertyType, r.estMid!)}',
                        ].join('  ·  ').ifEmptyNull,
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatePill extends StatelessWidget {
  const _RatePill({required this.label, required this.value, this.extra});

  final String label;
  final String value;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: '$label  ', style: TextStyle(color: scheme.onSecondaryContainer)),
          TextSpan(
            text: value,
            style: TextStyle(color: scheme.onSecondaryContainer, fontWeight: FontWeight.w600),
          ),
          if (extra != null) TextSpan(text: '  ·  $extra', style: TextStyle(color: scheme.primary)),
        ]),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

extension on String {
  String? get ifEmptyNull => isEmpty ? null : this;
}
