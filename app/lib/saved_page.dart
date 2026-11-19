import 'api.dart';
import 'area_sheet.dart';
import 'format.dart';
import 'i18n.dart';
import 'models.dart';
import 'saved.dart';
import 'ui.dart';

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

  /// Changes since the last time they were acknowledged: (place, what changed).
  List<(Area, String)> _changes = const [];
  DateTime? _since;

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
      await _compare(areas);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  static Map<String, List<num?>> _snapOf(Area a) => {
        for (final r in a.rates.values) r.propertyType: [r.guidanceRate, r.marketMid, r.marketObs],
      };

  /// Compares each saved place with how it looked last time. Places saved
  /// since then are recorded quietly, so only real changes show.
  Future<void> _compare(List<Area> areas) async {
    final (snap, since) = await SavedSnapshot.load();
    final changes = <(Area, String)>[];
    var added = false;
    for (final a in areas) {
      final old = snap[a.id];
      if (old == null) {
        snap[a.id] = _snapOf(a);
        added = true;
        continue;
      }
      for (final r in a.sortedRates) {
        final o = old[r.propertyType];
        if (o == null) continue;
        final type = r.propertyType;
        final label = propertyLabel(type);
        final (og, om, oo) = (o[0]?.toDouble(), o[1]?.toDouble(), (o[2] ?? 0).toInt());
        final g = r.guidanceRate;
        if (og != null && g != null && (g - og).abs() / og > 0.005) {
          changes.add((a, t('{type}: guidance {from} → {to} ({change})', {
            'type': label,
            'from': headline(type, og),
            'to': headline(type, g),
            'change': changeLabel((g - og) / og * 100),
          })));
        }
        final m = r.marketMid;
        if (om == null && m != null) {
          changes.add((a, t('{type}: market range now {range}', {
            'type': label,
            'range': '${headline(type, r.marketLow!)} – ${headline(type, r.marketHigh!)}',
          })));
        } else if (om != null && m != null && (m - om).abs() / om > 0.03) {
          changes.add((a, t('{type}: market middle {from} → {to} ({change})', {
            'type': label,
            'from': headline(type, om),
            'to': headline(type, m),
            'change': changeLabel((m - om) / om * 100),
          })));
        } else if (r.marketObs > oo) {
          final n = r.marketObs - oo;
          changes.add((a, t(n == 1 ? '{type}: 1 new market price' : '{type}: {n} new market prices',
              {'type': label, 'n': '$n'})));
        }
      }
    }
    if (added) await SavedSnapshot.save(snap, touchDate: since == null);
    if (mounted) {
      setState(() {
        _changes = changes;
        _since = since;
      });
    }
  }

  Future<void> _acknowledge() async {
    final (snap, _) = await SavedSnapshot.load();
    for (final a in _areas) {
      snap[a.id] = _snapOf(a);
    }
    await SavedSnapshot.save(snap);
    if (mounted) setState(() => _changes = const []);
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
    final changes = [
      for (final a in _areas)
        for (final r in a.rates.values)
          if (r.revised) r.guidanceChangePct!,
    ]..sort();
    final revisedFrom = [
      for (final a in _areas)
        for (final r in a.rates.values)
          if (r.revised) r.guidanceEffective,
    ].whereType<DateTime>().fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    return Column(
      children: [
        if (_changes.isNotEmpty)
          Card(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.notifications_active_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _since == null
                            ? t('What\'s changed for your saved places')
                            : t('What\'s changed since {date}', {'date': dayMonthYear(_since!)}),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  for (final (a, what) in _changes.take(8))
                    InkWell(
                      onTap: () => showAreaSheet(context, a),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text.rich(TextSpan(children: [
                          TextSpan(text: '${a.name}  ', style: const TextStyle(fontWeight: FontWeight.w600)),
                          TextSpan(text: what),
                        ])),
                      ),
                    ),
                  if (_changes.length > 8) Text(t('and {n} more', {'n': '${_changes.length - 8}'}), style: muted),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: _acknowledge, child: Text(t('Got it'))),
                  ),
                ],
              ),
            ),
          ),
        if (changes.isNotEmpty)
          Card(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            color: theme.colorScheme.tertiaryContainer,
            child: ListTile(
              leading: const Icon(Icons.gavel_outlined),
              title: Text(revisedFrom != null
                  ? t('Guidance values revised from {date}', {'date': monthYear(revisedFrom)})
                  : t('Guidance values revised')),
              subtitle: Text(changes.first == changes.last
                  ? '${t('Your saved places')}: ${changeLabel(changes.first)}'
                  : '${t('Your saved places')}: ${changeLabel(changes.first)} – ${changeLabel(changes.last)}'),
            ),
          ),
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
                    subtitle: ValueListenableBuilder<Set<int>>(
                      valueListenable: PlaceNotes.withNotes,
                      builder: (context, withNotes, _) => Text.rich(TextSpan(children: [
                        if (withNotes.contains(a.id))
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.sticky_note_2, size: 14, color: theme.colorScheme.primary),
                            ),
                          ),
                        TextSpan(text: a.subtitle),
                      ])),
                    ),
                    trailing: IconButton(
                      tooltip: t('Remove from saved'),
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
                label: Text(picked.length < 2 ? t('Compare') : t('Compare {n} places', {'n': '${picked.length}'})),
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
      for (final pt in propertyTypes)
        if (areas.any((a) => a.rates[pt] != null)) pt,
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
          for (final type in types) ...[
            const Divider(height: 24),
            Text(propertyLabel(type), style: theme.textTheme.titleSmall),
            Table(
              columnWidths: const {0: FixedColumnWidth(96)},
              children: [
                row('Guidance', (a) {
                  final g = a.rates[type]?.guidanceRate;
                  return g == null ? '–' : headline(type, g);
                }, strong: true),
                if (areas.any((a) => a.rates[type]?.revised ?? false))
                  row('Revision', (a) {
                    final r = a.rates[type];
                    return r == null || !r.revised
                        ? '–'
                        : t('{change} since {date}', {'change': changeLabel(r.guidanceChangePct!), 'date': monthYear(r.prevGuidanceEffective!)});
                  }),
                row('Market', (a) {
                  final r = a.rates[type];
                  if (r != null && r.hasMarket) return '${headline(type, r.marketLow!)} – ${headline(type, r.marketHigh!)}';
                  if (r != null && r.hasEstimate) {
                    return '${t('est.')} ${headline(type, r.estLow!)} – ${headline(type, r.estHigh!)}';
                  }
                  return 'no data yet';
                }),
                row('Market ÷ guidance', (a) {
                  final x = a.rates[type]?.marketRatio;
                  return x == null ? '–' : '${x.toStringAsFixed(1)}×';
                }),
                if (type == 'plot')
                  row('30×40 site', (a) {
                    final g = a.rates[type]?.guidanceRate;
                    return g == null ? '–' : rupeesShort(g * 1200);
                  }),
                if (type == 'agricultural_land')
                  row('Per guntha', (a) {
                    final g = a.rates[type]?.guidanceRate;
                    return g == null ? '–' : rupeesShort(g * sqftPerGuntha);
                  }),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text('Guidance values are the government minimum (Oct 2023). Market ranges come from published reports and rates you log; "est." ranges are estimates from guidance.',
              style: muted),
        ],
      ),
    );
  }
}
