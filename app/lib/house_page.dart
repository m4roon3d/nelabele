import 'package:flutter/material.dart';

import 'format.dart';
import 'models.dart';

/// Construction cost per sq ft of built-up area in Bengaluru, 2026, GST included.
/// Midpoints of the InfraLens bands (May 2026); Brick & Bolt's packages
/// (Sep 2026: ₹1,995–2,750) sit in the Basic–Standard range.
const houseTiers = <(String, String, double)>[
  ('Basic', 'plain finish, local fittings', 2200),
  ('Standard', 'vitrified tiles, branded fittings', 2700),
  ('Premium', 'imported tiles, modular kitchen', 3900),
  ('Luxury', 'marble, smart-home', 6000),
];

/// Depreciation on the building, straight line over a 60-year life,
/// never below 30% of the cost to rebuild it.
double depreciationPct(int age) => (age * 1.5).clamp(0, 70).toDouble();

/// Value of an independent house: the land at its plot rate, plus the
/// building at today's cost to build it, less depreciation for age.
class HousePage extends StatefulWidget {
  const HousePage({super.key, required this.area, required this.plot});

  final Area area;
  final Rate plot;

  @override
  State<HousePage> createState() => _HousePageState();
}

class _HousePageState extends State<HousePage> {
  final _site = TextEditingController(text: '1200');
  final _built = TextEditingController(text: '2400');
  int _tier = 1;
  double _age = 10;

  @override
  void dispose() {
    _site.dispose();
    _built.dispose();
    super.dispose();
  }

  static double? _num(TextEditingController c) {
    final v = double.tryParse(c.text.replaceAll(',', '').trim());
    return v == null || v <= 0 ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final p = widget.plot;
    final site = _num(_site), built = _num(_built);
    final landRate = p.bestMarketMid ?? p.guidanceRate;
    final landBasis = p.marketMid != null
        ? 'market mid'
        : p.estMid != null
            ? 'estimated market mid'
            : 'guidance value';
    final (tierName, _, costRate) = houseTiers[_tier];
    final age = _age.round();
    final dep = depreciationPct(age);

    final land = landRate != null && site != null ? landRate * site : null;
    final rebuild = built != null ? built * costRate : null;
    final building = rebuild != null ? rebuild * (1 - dep / 100) : null;
    final total = land != null && building != null ? land + building : null;
    final guidanceLand = p.guidanceRate != null && site != null ? p.guidanceRate! * site : null;

    return Scaffold(
      appBar: AppBar(title: const Text('House value')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Independent house in ${widget.area.name}', style: theme.textTheme.titleLarge),
          Text('Land at the plot ${landBasis == 'guidance value' ? 'guidance value' : landBasis}'
              '${landRate != null ? ', ${headline('plot', landRate)}' : ''}', style: muted),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _field(_site, 'Site area (sq ft)')),
              const SizedBox(width: 12),
              Expanded(child: _field(_built, 'Built-up area (sq ft)')),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final (label, s, b) in const [('30×40, G+1', 1200, 2400), ('30×40, G+2', 1200, 3400),
                ('30×50, G+1', 1500, 3000), ('40×60, G+1', 2400, 4600)])
                ActionChip(
                  label: Text(label),
                  onPressed: () => setState(() {
                    _site.text = '$s';
                    _built.text = '$b';
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Construction quality', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            segments: [
              for (var i = 0; i < houseTiers.length; i++)
                ButtonSegment(value: i, label: Text(houseTiers[i].$1)),
            ],
            selected: {_tier},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _tier = s.first),
          ),
          const SizedBox(height: 4),
          Text('${houseTiers[_tier].$2}: about ₹${fmtInt(costRate)}/sq ft to build today', style: muted),
          const SizedBox(height: 16),
          Text('Age of the building: $age year${age == 1 ? '' : 's'}', style: theme.textTheme.titleSmall),
          Slider(
            value: _age,
            min: 0,
            max: 50,
            divisions: 50,
            label: '$age',
            onChanged: (v) => setState(() => _age = v),
          ),
          const SizedBox(height: 8),
          if (total == null)
            Text(landRate == null ? 'No plot rate here to value the land.' : 'Enter the site and built-up areas.',
                style: muted)
          else
            Card.outlined(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About ${rupeesShort(total)}', style: theme.textTheme.headlineMedium),
                    Text('${rupeesShort(land!)} land + ${rupeesShort(building!)} building', style: muted),
                    const Divider(height: 24),
                    _Line('Land, ${fmtInt(site!)} sq ft', land),
                    _Line('Building, new ($tierName, ${fmtInt(built!)} sq ft)', rebuild!),
                    _Line('Less ${dep.toStringAsFixed(0)}% for $age years of age', -(rebuild - building)),
                    _Line('Building today', building, muted: true),
                    const Divider(height: 24),
                    _Line('Estimated value', total, bold: true),
                    if (guidanceLand != null) _Line('Land at guidance value', guidanceLand, muted: true),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Indicative: land plus what the building would cost to put up today, less 1.5% a year for '
            'age (at most 70%). Build rates are Bengaluru 2026 figures including GST (InfraLens, '
            'Brick & Bolt). Location premiums, interiors, condition, khata status and rental income '
            'can move a real price well away from this.',
            style: muted,
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        onChanged: (_) => setState(() {}),
      );
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.muted = false, this.bold = false});

  final String label;
  final double value;
  final bool muted;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = (bold ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)
        ?.copyWith(color: muted ? theme.colorScheme.onSurfaceVariant : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value < 0 ? '− ${rupees(-value)}' : rupees(value), style: style),
        ],
      ),
    );
  }
}
