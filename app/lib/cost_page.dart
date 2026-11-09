import 'package:flutter/material.dart';

import 'format.dart';
import 'listing.dart';
import 'models.dart';

const _sizeUnits = {'sqft': 'sq ft', 'sqm': 'sq m', 'sqyd': 'sq yard', 'guntha': 'guntha', 'acre': 'acre'};

/// Common sizes per property type: label → (size, unit).
const _presets = <String, List<(String, double, String)>>{
  'plot': [('20×30', 600, 'sqft'), ('30×40', 1200, 'sqft'), ('30×50', 1500, 'sqft'), ('40×60', 2400, 'sqft'), ('50×80', 4000, 'sqft')],
  'independent_house': [('30×40', 1200, 'sqft'), ('30×50', 1500, 'sqft'), ('40×60', 2400, 'sqft')],
  'apartment': [('1,000 sq ft', 1000, 'sqft'), ('1,250 sq ft', 1250, 'sqft'), ('1,600 sq ft', 1600, 'sqft')],
  'agricultural_land': [('10 guntha', 10, 'guntha'), ('20 guntha', 20, 'guntha'), ('1 acre', 1, 'acre'), ('2 acres', 2, 'acre')],
};

/// Karnataka registration charges on a property's value.
/// Sources (Aug–Oct 2025): Karnataka Stamp (Amendment) Act 2025 slabs and the
/// 31 Aug 2025 registration fee change. Always confirm on Kaveri Online.
class Charges {
  Charges(this.base, {required this.urban})
      : dutyPct = base <= 20e5
            ? 2
            : base <= 45e5
                ? 3
                : 5 {
    duty = base * dutyPct / 100;
    cess = duty * 0.10;
    surcharge = duty * (urban ? 0.02 : 0.03);
    registration = base * 0.02;
  }

  final double base;
  final bool urban;
  final int dutyPct;
  late final double duty, cess, surcharge, registration;

  double get total => duty + cess + surcharge + registration;
}

/// Total cost of buying: price plus stamp duty, cess, surcharge and registration.
class CostPage extends StatefulWidget {
  const CostPage({super.key, required this.area, required this.rate});

  final Area area;
  final Rate rate;

  @override
  State<CostPage> createState() => _CostPageState();
}

class _CostPageState extends State<CostPage> {
  late final _size = TextEditingController(text: _fmtNum(_presets[widget.rate.propertyType]?.first.$2 ?? 1200));
  final _price = TextEditingController();
  late String _unit = _presets[widget.rate.propertyType]?.first.$3 ?? 'sqft';
  late bool _urban = widget.area.district == 'Bangalore Urban';

  @override
  void initState() {
    super.initState();
    if (widget.rate.propertyType == 'plot') {
      _size.text = '1200'; // a 30×40 site
    }
  }

  @override
  void dispose() {
    _size.dispose();
    _price.dispose();
    super.dispose();
  }

  static String _fmtNum(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  double? get _sizeSqft {
    final v = double.tryParse(_size.text.replaceAll(',', '').trim());
    return v == null || v <= 0 ? null : sizeSqft(v, _unit);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final type = widget.rate.propertyType;
    final g = widget.rate.guidanceRate;
    final sqft = _sizeSqft;
    final agreed = parseMoney(_price.text);
    final guidanceValue = g != null && sqft != null ? g * sqft : null;
    final marketValue = widget.rate.marketMid != null && sqft != null ? widget.rate.marketMid! * sqft : null;
    final price = agreed ?? marketValue ?? guidanceValue;
    final base = [guidanceValue, agreed].whereType<double>().fold<double?>(null, (a, b) => a == null || b > a ? b : a);
    final charges = base == null ? null : Charges(base, urban: _urban);

    return Scaffold(
      appBar: AppBar(title: const Text('Total cost')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${propertyLabel(type)} in ${widget.area.name}', style: theme.textTheme.titleLarge),
          if (g != null) Text('Guidance value ${headline(type, g)}', style: muted),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _size,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: type == 'apartment' ? 'Size (super built-up)' : 'Size',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 130,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('size-unit-$_unit'),
                  initialValue: _unit,
                  decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                  items: [for (final e in _sizeUnits.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                  onChanged: (v) => setState(() => _unit = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final (label, size, unit) in _presets[type] ?? const <(String, double, String)>[])
                ActionChip(
                  label: Text(label),
                  onPressed: () => setState(() {
                    _size.text = _fmtNum(size);
                    _unit = unit;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _price,
            decoration: InputDecoration(
              labelText: 'Agreed price (optional)',
              hintText: 'e.g. 85 L or 1.2 Cr',
              helperText: agreed != null
                  ? rupees(agreed)
                  : marketValue != null
                      ? 'Leave empty to use the market mid, ${rupeesShort(marketValue)}'
                      : 'Leave empty to use the guidance value',
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('City / town')),
              ButtonSegment(value: false, label: Text('Village (rural)')),
            ],
            selected: {_urban},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _urban = s.first),
          ),
          const SizedBox(height: 4),
          Text('Sets the surcharge on stamp duty: 2% in city and town limits, 3% in villages.', style: muted),
          const SizedBox(height: 20),
          if (charges == null || price == null)
            Text('Enter a size to see the cost.', style: muted)
          else
            Card.outlined(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About ${rupeesShort(price + charges.total)}', style: theme.textTheme.headlineMedium),
                    Text('all in, of which ${rupeesShort(charges.total)} is government charges', style: muted),
                    const Divider(height: 24),
                    _Line(
                      agreed != null
                          ? 'Agreed price'
                          : marketValue != null
                              ? 'Price at market mid'
                              : 'Price at guidance value',
                      price,
                    ),
                    if (guidanceValue != null) _Line('Guidance value', guidanceValue, muted: true),
                    _Line('Charged on (the higher of the two)', charges.base, muted: true),
                    const SizedBox(height: 8),
                    _Line('Stamp duty (${charges.dutyPct}%)', charges.duty),
                    _Line('Cess (10% of duty)', charges.cess),
                    _Line('Surcharge (${_urban ? 2 : 3}% of duty)', charges.surcharge),
                    _Line('Registration fee (2%)', charges.registration),
                    const Divider(height: 24),
                    _Line('Total', price + charges.total, bold: true),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Indicative. Duty is 2% up to ₹20 L, 3% up to ₹45 L and 5% above, on the higher of the '
            'agreed price and the guidance value. Not included: '
            '${type == 'apartment' ? 'GST on under-construction flats (1–5%), ' : ''}'
            'khata transfer, legal checks, brokerage and loan fees. '
            'Confirm the exact amount on Kaveri Online (kaveri.karnataka.gov.in) before paying.',
            style: muted,
          ),
        ],
      ),
    );
  }
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
          Text(rupees(value), style: style),
        ],
      ),
    );
  }
}
