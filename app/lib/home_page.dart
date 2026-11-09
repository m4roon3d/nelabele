import 'dart:async';

import 'package:flutter/material.dart';

import 'api.dart';
import 'area_sheet.dart';
import 'format.dart';
import 'models.dart';
import 'theme.dart';

const _taluks = ['Nelamangala', 'Doddaballapur', 'Devanahalli', 'Hoskote'];
const _types = ['plot', 'agricultural_land', 'apartment'];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _api = NelaBeleApi();
  final _search = TextEditingController();
  Timer? _debounce;
  int _requestId = 0;

  String? _taluk;
  String? _type;
  bool _loading = true;
  String? _error;
  List<Area> _areas = [];

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

  Future<void> _load() async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final areas = await _api.fetchAreas(query: _search.text, taluk: _taluk, type: _type);
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
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 36, semanticLabel: 'NelaBele logo'),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Nela'),
                    TextSpan(
                      text: 'Bele',
                      style: TextStyle(
                        color: theme.brightness == Brightness.dark ? Brand.redEarthDark : Brand.redEarthText,
                      ),
                    ),
                  ]),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text('ನೆಲ ಬೆಲೆ · indicative property rates',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search a village or locality',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
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
            options: _taluks,
            labelOf: (t) => t,
            selected: _taluk,
            allLabel: 'All taluks',
            onSelected: (t) {
              setState(() => _taluk = t);
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
          const SizedBox(height: 4),
          Expanded(child: _body(theme)),
        ],
      ),
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
                _areas.length >= 100
                    ? 'Showing the first ${_areas.length} places. Search to narrow down.'
                    : 'Government guidance values, Oct 2023. Market prices are usually higher.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            );
          }
          return _AreaCard(area: _areas[i]);
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
  const _AreaCard({required this.area});

  final Area area;

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
              Text(area.name, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(area.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in area.sortedRates)
                    if (r.guidanceRate != null)
                      _RatePill(label: propertyLabel(r.propertyType), value: headline(r.propertyType, r.guidanceRate!)),
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
  const _RatePill({required this.label, required this.value});

  final String label;
  final String value;

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
