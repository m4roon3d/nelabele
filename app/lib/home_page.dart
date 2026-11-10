import 'dart:async';

import 'package:flutter/material.dart';

import 'api.dart';
import 'area_sheet.dart';
import 'format.dart';
import 'location.dart';
import 'models.dart';

const _districts = ['Bangalore Urban', 'Bangalore Rural', 'Ramanagara'];
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
      final areas = await _api.fetchAreas(query: _search.text, district: _district, type: _type);
      if (id != _requestId || !mounted) return;
      setState(() {
        _areas = areas;
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

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
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
    if (_loading && _areas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _Message(
        icon: Icons.cloud_off,
        text: _error!,
        action: FilledButton.tonal(onPressed: _load, child: const Text('Try again')),
      );
    }
    if (_areas.isEmpty) {
      return const _Message(icon: Icons.search_off, text: 'No places match. Try another spelling.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        itemCount: _areas.length + 1,
        itemBuilder: (context, i) {
          if (i == _areas.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _nearKm != null
                    ? 'Distances are to the middle of each place.'
                    : _areas.length >= 100
                    ? 'Showing the first ${_areas.length} places. Search to narrow down.'
                    : 'Government guidance values, Oct 2023. Market prices are usually higher.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            );
          }
          return _AreaCard(area: _areas[i], km: _nearKm?[_areas[i].id]);
        },
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
                        extra: r.marketRatio != null
                            ? 'market ${r.marketRatio!.toStringAsFixed(1)}×'
                            : r.hasEstimate
                                ? 'est. ~${headline(r.propertyType, r.estMid!)}'
                                : null,
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
