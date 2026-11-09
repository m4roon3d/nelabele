import 'package:flutter/material.dart';

import 'api.dart';
import 'area_sheet.dart';
import 'format.dart';
import 'models.dart';
import 'saved.dart';

/// Starred places, with up to three picked for a side-by-side comparison.
class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  final _api = NelaBeleApi();
  List<Area> _areas = [];
  final Set<int> _picked = {};
  bool _loading = false;
  String? _error;
  List<int> _loadedIds = const [];

  @override
  void initState() {
    super.initState();
    SavedPlaces.ids.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    SavedPlaces.ids.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final ids = SavedPlaces.ids.value;
    _picked.removeWhere((id) => !ids.contains(id));
    // Unstarring only removes a row; no need to fetch again
    if (ids.every(_loadedIds.contains)) {
      setState(() {
        _areas = _areas.where((a) => ids.contains(a.id)).toList();
        _loadedIds = ids;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final areas = await _api.fetchAreasByIds(ids);
      if (!mounted) return;
      setState(() {
        _areas = areas;
        _loadedIds = ids;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _togglePick(int id) => setState(() {
        if (!_picked.remove(id) && _picked.length < 3) _picked.add(id);
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    if (_loading && _areas.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: () {
                _loadedIds = const [];
                _load();
              }, child: const Text('Try again')),
        ]),
      );
    }
    if (_areas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.star_outline, size: 40, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('No saved places yet. Tap the star on a place to keep it here and compare.',
                textAlign: TextAlign.center, style: muted),
          ]),
        ),
      );
    }
    final picked = [for (final a in _areas) if (_picked.contains(a.id)) a];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('Pick two or three to compare', style: muted),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              for (final a in _areas)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Checkbox(
                      value: _picked.contains(a.id),
                      onChanged: _picked.contains(a.id) || _picked.length < 3 ? (_) => _togglePick(a.id) : null,
                    ),
                    title: Text(a.nameKn == null ? a.name : '${a.name} · ${a.nameKn}'),
                    subtitle: Text(a.subtitle),
                    trailing: IconButton(
                      tooltip: 'Remove from saved',
                      icon: const Icon(Icons.star),
                      color: theme.colorScheme.primary,
                      onPressed: () => SavedPlaces.toggle(a.id),
                    ),
                    onTap: () => showAreaSheet(context, a),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: picked.length < 2
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => ComparePage(areas: picked),
                        )),
                icon: const Icon(Icons.compare_arrows),
                label: Text(picked.length < 2 ? 'Compare' : 'Compare ${picked.length} places'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Two or three places side by side, one block per property type.
class ComparePage extends StatelessWidget {
  const ComparePage({super.key, required this.areas});

  final List<Area> areas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final types = [
      for (final t in propertyTypes)
        if (areas.any((a) => a.rates[t] != null)) t,
    ];

    Widget cell(Widget child) => Padding(padding: const EdgeInsets.fromLTRB(0, 6, 10, 6), child: child);
    TableRow row(String label, String Function(Area a) value, {bool strong = false}) => TableRow(children: [
          cell(Text(label, style: muted)),
          for (final a in areas)
            cell(Text(value(a), style: strong ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)),
        ]);

    return Scaffold(
      appBar: AppBar(title: const Text('Compare')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Table(
            columnWidths: const {0: FixedColumnWidth(96)},
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: [
              TableRow(children: [
                const SizedBox.shrink(),
                for (final a in areas)
                  cell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.name, style: theme.textTheme.titleMedium),
                    if (a.nameKn != null) Text(a.nameKn!, style: muted),
                    Text(a.subtitle, style: muted),
                  ])),
              ]),
            ],
          ),
          for (final t in types) ...[
            const Divider(height: 24),
            Text(propertyLabel(t), style: theme.textTheme.titleSmall),
            Table(
              columnWidths: const {0: FixedColumnWidth(96)},
              children: [
                row('Guidance', (a) {
                  final g = a.rates[t]?.guidanceRate;
                  return g == null ? '–' : headline(t, g);
                }, strong: true),
                row('Market', (a) {
                  final r = a.rates[t];
                  return r == null || !r.hasMarket
                      ? 'no data yet'
                      : '${headline(t, r.marketLow!)} – ${headline(t, r.marketHigh!)}';
                }),
                row('Market ÷ guidance', (a) {
                  final x = a.rates[t]?.marketRatio;
                  return x == null ? '–' : '${x.toStringAsFixed(1)}×';
                }),
                if (t == 'plot')
                  row('30×40 site', (a) {
                    final g = a.rates[t]?.guidanceRate;
                    return g == null ? '–' : rupeesShort(g * 1200);
                  }),
                if (t == 'agricultural_land')
                  row('Per guntha', (a) {
                    final g = a.rates[t]?.guidanceRate;
                    return g == null ? '–' : rupeesShort(g * sqftPerGuntha);
                  }),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text('Guidance values are the government minimum (Oct 2023). Market ranges come from rates you have logged.',
              style: muted),
        ],
      ),
    );
  }
}
