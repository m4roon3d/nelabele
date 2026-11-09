import 'package:flutter/material.dart';

import 'format.dart';
import 'models.dart';

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

class _AreaDetails extends StatelessWidget {
  const _AreaDetails({required this.area, required this.controller});

  final Area area;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Text(area.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(area.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        for (final r in area.sortedRates) _RateCard(rate: r),
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
  const _RateCard({required this.rate});

  final Rate rate;

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
                'Govt guidance value'
                '${rate.guidanceEffective != null ? ' · from ${monthYear(rate.guidanceEffective!)}' : ''}',
                style: muted,
              ),
            ],
            const Divider(height: 24),
            if (rate.hasMarket)
              Text(
                'Market range: ${headline(type, rate.marketLow!)} – ${headline(type, rate.marketHigh!)}'
                ' · ${rate.marketObs} data points, ${rate.confidence} confidence',
                style: theme.textTheme.bodyMedium,
              )
            else
              Text('Market range: not enough data yet', style: muted),
          ],
        ),
      ),
    );
  }
}
