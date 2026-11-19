import 'format.dart';
import 'i18n.dart';
import 'listing.dart';
import 'models.dart';
import 'ui.dart';

/// Units a size can be typed in, per property type.
List<(String, String)> _units(String type) => type == 'agricultural_land'
    ? const [('acre', 'acres'), ('guntha', 'guntha'), ('sqft', 'sq ft')]
    : const [('sqft', 'sq ft'), ('sqm', 'sq m'), ('sqyd', 'sq yd')];

/// Is an asking price fair? Puts the price per sq ft against the guidance
/// value and the market range (or estimate) for the place, and shows the
/// gross rental yield from a known or typed-in rent.
class FairPricePage extends StatefulWidget {
  const FairPricePage({super.key, required this.area, required this.rate, this.rent});

  final Area area;
  final Rate rate;
  final Rent? rent;

  @override
  State<FairPricePage> createState() => _FairPricePageState();
}

class _FairPricePageState extends State<FairPricePage> {
  final _price = TextEditingController();
  final _size = TextEditingController();
  final _rentCtl = TextEditingController();
  late String _unit = _units(widget.rate.propertyType).first.$1;

  @override
  void dispose() {
    _price.dispose();
    _size.dispose();
    _rentCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final r = widget.rate;
    final type = r.propertyType;
    final price = parseMoney(_price.text);
    final size = double.tryParse(_size.text.replaceAll(',', '').trim());
    final sqft = size != null && size > 0 ? sizeSqft(size, _unit) : null;
    final asked = price != null && sqft != null ? price / sqft : null;

    final (lo, mid, hi, isEstimate) = r.hasMarket
        ? (r.marketLow!, r.marketMid ?? (r.marketLow! + r.marketHigh!) / 2, r.marketHigh!, false)
        : r.hasEstimate
            ? (r.estLow!, r.estMid ?? (r.estLow! + r.estHigh!) / 2, r.estHigh!, true)
            : (null, null, null, false);

    // monthly rent: typed in, else the place's typical rent for this size
    final typedRent = parseMoney(_rentCtl.text);
    final knownRent = widget.rent != null && sqft != null ? widget.rent!.perSqft * sqft : null;
    final monthlyRent = typedRent ?? knownRent;
    final yieldPct = monthlyRent != null && price != null && price > 0 ? monthlyRent * 12 / price * 100 : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Is this price fair?')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t('{type} in {place}', {'type': propertyLabel(type), 'place': widget.area.name}), style: theme.textTheme.titleLarge),
          Text(widget.area.subtitle, style: muted),
          const SizedBox(height: 16),
          TextField(
            controller: _price,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: t('Asking price'),
              hintText: t('e.g. 1.2 cr, 85 L, 45,00,000'),
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _size,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: type == 'apartment' ? t('Super built-up area') : t('Size'),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _unit,
                items: [for (final (code, label) in _units(type)) DropdownMenuItem(value: code, child: Text(label))],
                onChanged: (u) => setState(() => _unit = u ?? _unit),
              ),
            ],
          ),
          if (type != 'agricultural_land') ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (label, sq) in type == 'apartment'
                    ? const [('2 BHK ~1,100', 1100), ('3 BHK ~1,600', 1600)]
                    : const [('30×40', 1200), ('30×50', 1500), ('40×60', 2400)])
                  ActionChip(
                    label: Text(label),
                    onPressed: () => setState(() {
                      _unit = 'sqft';
                      _size.text = '$sq';
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          if (asked == null)
            Text('Enter the asking price and the size.', style: muted)
          else ...[
            Text(t('{rate} asked', {'rate': headline(type, asked)}), style: theme.textTheme.headlineMedium),
            if (type == 'agricultural_land') Text('${rupees(asked)}/sq ft', style: muted),
            const SizedBox(height: 12),
            _Verdict(asked: asked, lo: lo, mid: mid, hi: hi, isEstimate: isEstimate, type: type),
            const SizedBox(height: 16),
            if (lo != null) _RangeBar(asked: asked, lo: lo, hi: hi!, guidance: r.guidanceRate),
            const SizedBox(height: 12),
            if (r.guidanceRate != null)
              _Line('Govt guidance value', headline(type, r.guidanceRate!),
                  note: t('{x}× guidance', {'x': (asked / r.guidanceRate!).toStringAsFixed(1)})),
            if (lo != null)
              _Line(isEstimate ? 'Estimated market range' : 'Market range',
                  '${headline(type, lo)} – ${headline(type, hi!)}',
                  note: isEstimate ? t('an estimate, not data') : t(r.marketObs == 1 ? '1 data point' : '{n} data points', {'n': '${r.marketObs}'})),
            if (r.guidanceRate != null && sqft != null)
              _Line('Registration value (guidance)', rupeesShort(r.guidanceRate! * sqft),
                  note: 'stamp duty is on the higher of this and the price'),
          ],
          if (type == 'apartment' || type == 'independent_house') ...[
            const Divider(height: 32),
            Text('Rental yield', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _rentCtl,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: t('Expected rent a month'),
                hintText: knownRent != null ? t('typical here: {rent}', {'rent': rupees(knownRent)}) : t('e.g. 35,000'),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (yieldPct != null)
              Text(
                t(typedRent == null ? 'Gross yield {pct}% a year at the typical rent here' : 'Gross yield {pct}% a year',
                    {'pct': yieldPct.toStringAsFixed(1)}),
                style: theme.textTheme.titleMedium,
              ),
            if (widget.rent != null)
              Text(
                '${t('Typical rent: {rent}/sq ft a month', {'rent': rupees(widget.rent!.perSqft)})}, ${widget.rent!.label} '
                '(${widget.rent!.report.split(':').first}). ${t('Bengaluru flats usually yield 3–4.5% gross.')}',
                style: muted,
              )
            else
              Text('Bengaluru flats usually yield 3–4.5% gross, before maintenance, tax and vacancy.', style: muted),
          ],
          const SizedBox(height: 20),
          Text(
            'Indicative: market figures are mostly asking prices from reports and listings. '
            'Corner plots, wide roads, khata status, approvals and condition can justify a price well '
            'outside the range, and a price far below it is a reason to check the papers.',
            style: muted,
          ),
        ],
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({
    required this.asked,
    required this.lo,
    required this.mid,
    required this.hi,
    required this.isEstimate,
    required this.type,
  });

  final double asked;
  final double? lo, mid, hi;
  final bool isEstimate;
  final String type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    if (lo == null || hi == null || mid == null) {
      return Text('No market range here yet, so only the guidance comparison below is possible.',
          style: theme.textTheme.bodyMedium);
    }
    final pct = (asked - mid!) / mid! * 100;
    final (icon, text, color) = asked < lo! * 0.85
        ? (Icons.warning_amber, t('Well below the range: check khata, approvals and title closely'), cs.tertiary)
        : asked < lo!
            ? (Icons.thumb_up_alt_outlined, t('Below the range: a good price if the papers are clean'), cs.primary)
            : asked <= hi!
                ? (Icons.check_circle_outline, t('Within the range'), cs.primary)
                : asked <= hi! * 1.15
                    ? (Icons.trending_up, t('A little above the range: room to negotiate'), cs.error)
                    : (Icons.priority_high, t('Well above the range'), cs.error);
    return Card(
      margin: EdgeInsets.zero,
      color: color.withValues(alpha: 0.12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(text),
        subtitle: Text(t(isEstimate ? '{pct}% against the estimated market middle of {rate}' : '{pct}% against the market middle of {rate}', {
          'pct': '${pct >= 0 ? '+' : '−'}${pct.abs().toStringAsFixed(0)}',
          'rate': headline(type, mid!),
        })),
      ),
    );
  }
}

/// A bar from guidance to the top of the range, with the market range shaded
/// and a marker at the asked price.
class _RangeBar extends StatelessWidget {
  const _RangeBar({required this.asked, required this.lo, required this.hi, this.guidance});

  final double asked, lo, hi;
  final double? guidance;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final values = [asked, lo, hi, if (guidance != null) guidance!];
    final min = values.reduce((a, b) => a < b ? a : b) * 0.9;
    final max = values.reduce((a, b) => a > b ? a : b) * 1.1;
    double x(double v, double w) => (v - min) / (max - min) * w;
    return SizedBox(
      height: 40,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        return Stack(
          children: [
            Positioned(left: 0, right: 0, top: 16, height: 8,
                child: DecoratedBox(decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(4)))),
            Positioned(left: x(lo, w), width: (x(hi, w) - x(lo, w)).clamp(2, w), top: 16, height: 8,
                child: DecoratedBox(decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4)))),
            if (guidance != null)
              Positioned(left: x(guidance!, w) - 1, top: 10, width: 2, height: 20, child: ColoredBox(color: cs.outline)),
            Positioned(left: x(asked, w) - 7, top: 13, width: 14, height: 14,
                child: DecoratedBox(decoration: BoxDecoration(color: cs.error, shape: BoxShape.circle, border: Border.all(color: cs.surface, width: 2)))),
          ],
        );
      }),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                if (note != null)
                  Text(note!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
