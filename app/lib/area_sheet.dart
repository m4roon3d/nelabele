import 'package:share_plus/share_plus.dart';

import 'add_rate_page.dart';
import 'api.dart';
import 'checklist_page.dart';
import 'cost_page.dart';
import 'fair_price_page.dart';
import 'format.dart';
import 'house_page.dart';
import 'i18n.dart';
import 'infra.dart';
import 'loan_page.dart';
import 'models.dart';
import 'notes_page.dart';
import 'saved.dart';
import 'settings.dart';
import 'ui.dart';

Future<void> showAreaSheet(BuildContext context, Area area) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, controller) => _AreaDetails(area: area, controller: controller),
    ),
  );
}

class _AreaDetails extends StatefulWidget {
  const _AreaDetails({required this.area, required this.controller});

  final Area area;
  final ScrollController controller;

  @override
  State<_AreaDetails> createState() => _AreaDetailsState();
}

/// Price history and typical rents for a place, fetched with the sheet.
typedef _Extras = (Map<String, List<PricePoint>>, Map<String, Rent>);

class _AreaDetailsState extends State<_AreaDetails> {
  late Area _area = widget.area;
  late Future<_Extras> _extras = _loadExtras();

  Future<_Extras> _loadExtras() async {
    final api = NelaBeleApi();
    final results = await Future.wait([
      api.marketHistory(_area.id).catchError((_) => <String, List<PricePoint>>{}),
      api.rents(_area.id).catchError((_) => <String, Rent>{}),
    ]);
    return (results[0] as Map<String, List<PricePoint>>, results[1] as Map<String, Rent>);
  }

  void _share() {
    final area = _area;
    final lines = [
      '${area.name} (${area.subtitle})',
      for (final r in area.sortedRates)
        '${propertyLabel(r.propertyType)}: ${[
          if (r.guidanceRate != null) '${t('guidance')} ${headline(r.propertyType, r.guidanceRate!)}',
          if (r.hasMarket)
            '${t('market')} ${headline(r.propertyType, r.marketLow!)}–${headline(r.propertyType, r.marketHigh!)}'
          else if (r.hasEstimate)
            '${t('est. market')} ${headline(r.propertyType, r.estLow!)}–${headline(r.propertyType, r.estHigh!)}',
        ].join(', ')}',
      '',
      '${t('NelaBele, indicative rates')}: https://m4roon3d.github.io/nelabele/?area=${area.id}',
    ];
    SharePlus.instance.share(ShareParams(text: lines.join('\n'), subject: '${area.name}: ${t('property rates')}'));
  }

  Future<void> _logRate() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddRatePage(area: _area)),
    );
    if (saved != true || !mounted) return;
    try {
      final fresh = await NelaBeleApi().fetchArea(_area.id);
      if (fresh != null && mounted) {
        setState(() {
          _area = fresh;
          _extras = _loadExtras();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final area = _area;
    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(area.name, style: theme.textTheme.headlineSmall),
                  if (area.nameKn != null)
                    Text(area.nameKn!, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                  const SizedBox(height: 4),
                  Text(area.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            ValueListenableBuilder<Set<int>>(
              valueListenable: PlaceNotes.withNotes,
              builder: (context, withNotes, _) => IconButton(
                tooltip: t('Your notes and documents'),
                icon: Icon(withNotes.contains(area.id) ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined),
                color: withNotes.contains(area.id) ? theme.colorScheme.primary : null,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => NotesPage(area: area)),
                ),
              ),
            ),
            IconButton(
              tooltip: t('Share this place'),
              icon: const Icon(Icons.share_outlined),
              onPressed: _share,
            ),
            ValueListenableBuilder<List<int>>(
              valueListenable: SavedPlaces.ids,
              builder: (context, ids, _) {
                final saved = ids.contains(area.id);
                return IconButton(
                  tooltip: saved ? t('Remove from saved') : t('Save this place'),
                  icon: Icon(saved ? Icons.star : Icons.star_outline),
                  color: saved ? theme.colorScheme.primary : null,
                  onPressed: () => SavedPlaces.toggle(area.id),
                );
              },
            ),
          ],
        ),
        if (area.lat != null && area.lon != null) _NearbyLine(lat: area.lat!, lon: area.lon!),
        const SizedBox(height: 16),
        FutureBuilder<_Extras>(
          future: _extras,
          builder: (context, snap) {
            final (history, rents) = snap.data ?? (const <String, List<PricePoint>>{}, const <String, Rent>{});
            return Column(
              children: [
                for (final r in area.sortedRates)
                  _RateCard(area: area, rate: r, history: history[r.propertyType] ?? const [], rent: rents[r.propertyType]),
              ],
            );
          },
        ),
        ValueListenableBuilder<String?>(
          valueListenable: EditorKey.current,
          builder: (context, key, _) => key == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FilledButton.tonalIcon(
                    onPressed: _logRate,
                    icon: const Icon(Icons.add),
                    label: const Text('Log a market rate'),
                  ),
                ),
        ),
        const _CityTrendNote(),
        const SizedBox(height: 8),
        Text(
          'Indicative only. Guidance values are the government minimum used for '
          'registration; actual market prices are usually higher and vary with '
          'khata, approvals, road access and plot size.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({required this.area, required this.rate, this.history = const [], this.rent});

  final Area area;
  final Rate rate;
  final List<PricePoint> history;
  final Rent? rent;

  Widget _link(BuildContext context, IconData icon, String label, Widget Function() page) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page())),
          icon: Icon(icon, size: 18),
          label: Text(label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final type = rate.propertyType;
    final g = rate.guidanceRate;

    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(propertyLabel(type), style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (g != null) ...[
              Text(headline(type, g), style: theme.textTheme.headlineMedium),
              const SizedBox(height: 2),
              Text(otherUnits(type, g).join('  ·  '), style: muted),
              const SizedBox(height: 6),
              Text(
                '${t('Govt guidance value')}'
                '${rate.guidanceEffective != null ? ' · ${t('from {date}', {'date': monthYear(rate.guidanceEffective!)})}' : ''}',
                style: muted,
              ),
              if (rate.revised) ...[
                const SizedBox(height: 4),
                Text(
                  t('{change} from {rate} ({date})', {
                    'change': changeLabel(rate.guidanceChangePct!),
                    'rate': headline(type, rate.prevGuidanceRate!),
                    'date': monthYear(rate.prevGuidanceEffective!),
                  }),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: rate.guidanceChangePct! >= 0 ? theme.colorScheme.error : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ] else
              Text('No guidance value for this type', style: muted),
            const Divider(height: 24),
            if (rate.hasMarket) ...[
              Text(
                '${t('Market range')}: ${headline(type, rate.marketLow!)} – ${headline(type, rate.marketHigh!)}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                '${t(rate.marketObs == 1 ? '1 data point' : '{n} data points', {'n': '${rate.marketObs}'})}, '
                '${t('{level} confidence', {'level': t(rate.confidence)})}'
                '${rate.fromReports ? ' · ${t('includes published prices (reports, auction reserves, listing averages)')}' : ''}',
                style: muted,
              ),
              if (rate.marketRatio != null) ...[
                const SizedBox(height: 4),
                Text(
                  t('Market is about {x}× the guidance value', {'x': rate.marketRatio!.toStringAsFixed(1)}),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                ),
              ],
            ] else if (rate.hasEstimate) ...[
              Text(
                '${t('Estimated market')}: ${headline(type, rate.estLow!)} – ${headline(type, rate.estHigh!)}',
                style: theme.textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 2),
              Text(
                t('Estimate, not data: about {x}× guidance, the ratio seen in {n} areas with published prices. '
                    'Log or share a listing to replace it.',
                    {'x': rate.estRatio?.toStringAsFixed(1) ?? '–', 'n': '${rate.estPlaces ?? t('several')}'}),
                style: muted,
              ),
            ] else
              Text('Market range: no data or estimate yet', style: muted),
            if (rent != null) ...[
              const SizedBox(height: 10),
              Text(
                '${t('Typical rent: {rent}/sq ft a month', {'rent': rupees(rent!.perSqft)})}'
                '${rate.bestMarketMid != null ? ' · ${t('about {pct}% gross yield', {'pct': rent!.yieldAt(rate.bestMarketMid!).toStringAsFixed(1)})}' : ''}',
                style: theme.textTheme.bodyMedium,
              ),
              Text('${rent!.label}: ${rent!.report.split(':').first}', style: muted),
            ],
            if (history.length >= 2) ...[
              const SizedBox(height: 12),
              _HistoryChart(points: history, guidance: g, type: type),
            ],
            if (g != null || rate.hasMarket || rate.hasEstimate) ...[
              const SizedBox(height: 8),
              _link(context, Icons.balance_outlined, 'Is this price fair?',
                  () => FairPricePage(area: area, rate: rate, rent: rent)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => CostPage(area: area, rate: rate)),
                  ),
                  icon: const Icon(Icons.calculate_outlined, size: 18),
                  label: const Text('Total cost with registration'),
                ),
              ),
              if (type == 'plot')
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => HousePage(area: area, plot: rate)),
                    ),
                    icon: const Icon(Icons.house_outlined, size: 18),
                    label: const Text('Value a house on this plot'),
                  ),
                ),
            ],
            if (rate.bestMarketMid != null || g != null)
              _link(context, Icons.account_balance_outlined, 'Home loan and EMI',
                  () => LoanPage(area: area, rate: rate)),
            _link(context, Icons.checklist, 'Buyer\'s checklist',
                () => ChecklistPage(type: type, district: area.district)),
          ],
        ),
      ),
    );
  }
}

/// City-wide price change, as a sense check on 2023 guidance values.
class _CityTrendNote extends StatelessWidget {
  const _CityTrendNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<CityTrend?>(
      future: NelaBeleApi().cityTrend(),
      builder: (context, snap) {
        final trend = snap.data;
        if (trend == null) return const SizedBox.shrink();
        final sign = trend.yoyPct >= 0 ? '+' : '';
        return Card(
          margin: const EdgeInsets.only(bottom: 4),
          color: theme.colorScheme.surfaceContainerHigh,
          child: ListTile(
            leading: const Icon(Icons.trending_up),
            title: Text(t('{city} homes: {pct}% in a year', {'city': trend.city, 'pct': '$sign${trend.yoyPct.toStringAsFixed(1)}'})),
            subtitle: Text('${trend.measure}, ${trend.period}. ${t('Guidance values have not changed since Oct 2023.')}'),
          ),
        );
      },
    );
  }
}


/// Nearest metro station and ring roads, as the crow flies.
class _NearbyLine extends StatelessWidget {
  const _NearbyLine({required this.lat, required this.lon});

  final double lat, lon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<Infra>(
      future: Infra.load(),
      builder: (context, snap) {
        final infra = snap.data;
        if (infra == null) return const SizedBox.shrink();
        final stations = infra.stations(lat, lon).where((s) => s.km <= 15).toList();
        final roads = infra.roads(lat, lon).take(2).toList();
        if (stations.isEmpty && roads.isEmpty) return const SizedBox.shrink();
        final parts = [
          for (final s in stations) '${s.name} ${t('metro')}${s.planned ? ' (${t('planned')})' : ''} ${kmLabel(s.km)}',
          for (final r in roads) '${r.name}${r.planned ? ' (${t('planned')})' : ''} ${kmLabel(r.km)}',
        ];
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.directions_transit_outlined, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${parts.join(' · ')}  (${t('straight line')})',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Market prices over time as dots and a line, with the guidance value dashed.
class _HistoryChart extends StatelessWidget {
  const _HistoryChart({required this.points, required this.guidance, required this.type});

  final List<PricePoint> points;
  final double? guidance;
  final String type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final first = points.first, last = points.last;
    final change = first.rate > 0 ? (last.rate - first.rate) / first.rate * 100 : 0.0;
    final sameDay = points.every((p) => p.date == first.date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price history', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        SizedBox(
          height: 90,
          width: double.infinity,
          child: CustomPaint(
            painter: _HistoryPainter(
              points: points,
              guidance: guidance,
              line: theme.colorScheme.primary,
              guide: theme.colorScheme.outline,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sameDay
              ? t('{n} prices from {date}, {low} – {high}', {
                  'n': '${points.length}',
                  'date': monthYear(first.date),
                  'low': headline(type, _min),
                  'high': headline(type, _max),
                })
              : '${monthYear(first.date)} → ${monthYear(last.date)}: ${headline(type, first.rate)} → '
                  '${headline(type, last.rate)} (${changeLabel(change)}) · ${t('{n} prices', {'n': '${points.length}'})}'
                  '${guidance != null ? ' · ${t('dashed: guidance')}' : ''}',
          style: muted,
        ),
      ],
    );
  }

  double get _min => points.map((p) => p.rate).reduce((a, b) => a < b ? a : b);
  double get _max => points.map((p) => p.rate).reduce((a, b) => a > b ? a : b);
}

class _HistoryPainter extends CustomPainter {
  _HistoryPainter({required this.points, required this.guidance, required this.line, required this.guide});

  final List<PricePoint> points;
  final double? guidance;
  final Color line, guide;

  @override
  void paint(Canvas canvas, Size size) {
    final rates = [for (final p in points) p.rate, if (guidance != null) guidance!];
    var lo = rates.reduce((a, b) => a < b ? a : b), hi = rates.reduce((a, b) => a > b ? a : b);
    if (hi - lo < 1) {
      lo -= 1;
      hi += 1;
    }
    final t0 = points.first.date.millisecondsSinceEpoch.toDouble();
    final t1 = points.last.date.millisecondsSinceEpoch.toDouble();
    const pad = 6.0;
    double x(PricePoint p) => t1 == t0
        ? size.width / 2
        : pad + (p.date.millisecondsSinceEpoch - t0) / (t1 - t0) * (size.width - 2 * pad);
    double y(double v) => size.height - pad - (v - lo) / (hi - lo) * (size.height - 2 * pad);

    if (guidance != null) {
      final gy = y(guidance!);
      final dash = Paint()
        ..color = guide
        ..strokeWidth = 1;
      for (var dx = 0.0; dx < size.width; dx += 8) {
        canvas.drawLine(Offset(dx, gy), Offset((dx + 4).clamp(0, size.width), gy), dash);
      }
    }
    // the middle of each date's prices, joined up
    final byDate = <int, List<double>>{};
    for (final p in points) {
      byDate.putIfAbsent(p.date.millisecondsSinceEpoch, () => []).add(p.rate);
    }
    final dates = byDate.keys.toList()..sort();
    if (dates.length >= 2) {
      final path = Path();
      for (final (i, d) in dates.indexed) {
        final v = byDate[d]!..sort();
        final m = v[v.length ~/ 2];
        final px = x(PricePoint(type: '', date: DateTime.fromMillisecondsSinceEpoch(d), rate: m, source: ''));
        if (i == 0) {
          path.moveTo(px, y(m));
        } else {
          path.lineTo(px, y(m));
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = line
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
    final dot = Paint()..color = line;
    for (final p in points) {
      canvas.drawCircle(Offset(x(p), y(p.rate)), 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(_HistoryPainter old) => old.points != points || old.guidance != guidance;
}
