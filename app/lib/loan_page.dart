import 'dart:math' as math;

import 'cost_page.dart';
import 'format.dart';
import 'i18n.dart';
import 'listing.dart';
import 'models.dart';
import 'ui.dart';

/// Monthly instalment on a loan of [loan] at [annualPct] for [months].
double emi(double loan, double annualPct, int months) {
  if (loan <= 0 || months <= 0) return 0;
  final r = annualPct / 12 / 100;
  if (r == 0) return loan / months;
  final f = math.pow(1 + r, months).toDouble();
  return loan * r * f / (f - 1);
}

/// The loan a monthly instalment of [monthly] pays off.
double loanFor(double monthly, double annualPct, int months) {
  if (monthly <= 0 || months <= 0) return 0;
  final r = annualPct / 12 / 100;
  if (r == 0) return monthly * months;
  return monthly * (1 - math.pow(1 + r, -months).toDouble()) / r;
}

/// The most a bank lends against a home of this price (RBI loan-to-value
/// limits): 90% up to ₹30 L, 80% up to ₹75 L, 75% above.
double maxLtv(double price) => price <= 30e5
    ? 0.90
    : price <= 75e5
        ? 0.80
        : 0.75;

/// Home loan EMI from a price, and the reverse: the price a monthly budget
/// and savings can buy, after registration charges (which banks don't lend).
class LoanPage extends StatefulWidget {
  const LoanPage({super.key, this.area, this.rate, this.price, this.charges});

  final Area? area;
  final Rate? rate;

  /// Price to start from, e.g. from the total-cost page.
  final double? price;

  /// Registration charges on that price, if already worked out.
  final double? charges;

  @override
  State<LoanPage> createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  bool _fromBudget = false;
  late final _price = TextEditingController(text: widget.price == null ? '' : _short(widget.price!));
  final _budget = TextEditingController();
  final _savings = TextEditingController();
  final _rateCtl = TextEditingController(text: '8.0');
  double _downPct = 20;
  double _years = 20;

  static String _short(double v) => v >= 1e7
      ? '${(v / 1e7).toStringAsFixed(2)} cr'
      : v >= 1e5
          ? '${(v / 1e5).toStringAsFixed(1)} L'
          : v.round().toString();

  @override
  void dispose() {
    _price.dispose();
    _budget.dispose();
    _savings.dispose();
    _rateCtl.dispose();
    super.dispose();
  }

  double get _rate => double.tryParse(_rateCtl.text.trim()) ?? 0;
  int get _months => (_years * 12).round();

  bool get _urban => widget.area == null || widget.area!.district == 'Bangalore Urban';

  /// Charges on a price, valued at the higher of price and guidance when we know the size.
  double _chargesOn(double price) => Charges(price, urban: _urban).total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(title: Text(t('Home loan and EMI'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.area != null) ...[
            Text(
              widget.rate == null
                  ? widget.area!.name
                  : '${propertyLabel(widget.rate!.propertyType)} · ${widget.area!.name}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
          ],
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, icon: const Icon(Icons.home_outlined), label: Text(t('From a price'))),
              ButtonSegment(value: true, icon: const Icon(Icons.savings_outlined), label: Text(t('From my budget'))),
            ],
            selected: {_fromBudget},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _fromBudget = s.first),
          ),
          const SizedBox(height: 16),
          if (_fromBudget) ..._budgetInputs() else ..._priceInputs(),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _rateCtl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: t('Interest'),
                    suffixText: '%',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${t('Tenure')}: ${_years.round()} ${t('years')}'),
                    Slider(
                      value: _years,
                      min: 5,
                      max: 30,
                      divisions: 25,
                      label: '${_years.round()}',
                      onChanged: (v) => setState(() => _years = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            t('The RBI repo rate is 5.5% (raised in Oct 2026); home loans usually cost about 2–3 points more, '
                'depending on the bank and your credit score.'),
            style: muted,
          ),
          const SizedBox(height: 16),
          if (_fromBudget) _budgetResult(theme, muted) else _priceResult(theme, muted),
          const SizedBox(height: 16),
          Text(
            t('Indicative. Banks lend at most 90% of the price up to ₹30 L, 80% up to ₹75 L and 75% above, '
                'and do not lend for stamp duty and registration, so those come from your savings. '
                'Most banks keep all EMIs under about half of your take-home pay. Processing fees, insurance '
                'and rate changes on floating loans are not included.'),
            style: muted,
          ),
        ],
      ),
    );
  }

  List<Widget> _priceInputs() {
    final price = parseMoney(_price.text);
    final minDown = price == null ? 10.0 : (1 - maxLtv(price)) * 100;
    if (_downPct < minDown) _downPct = minDown;
    return [
      TextField(
        controller: _price,
        decoration: InputDecoration(
          labelText: t('Property price'),
          hintText: t('e.g. 85 L or 1.2 cr'),
          helperText: price == null ? null : rupees(price),
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      Text('${t('Down payment')}: ${_downPct.round()}%'
          '${price != null ? ' · ${rupeesShort(price * _downPct / 100)}' : ''}'),
      Slider(
        value: _downPct,
        min: 10,
        max: 90,
        divisions: 80,
        label: '${_downPct.round()}%',
        onChanged: (v) => setState(() => _downPct = math.max(v, minDown)),
      ),
      if (price != null && minDown > 10)
        Text(
          t('At this price the bank lends at most {pct}%, so the down payment is at least {down}%.',
              {'pct': '${(maxLtv(price) * 100).round()}', 'down': '${minDown.round()}'}),
          style: Theme.of(context).textTheme.bodySmall,
        ),
    ];
  }

  Widget _priceResult(ThemeData theme, TextStyle? muted) {
    final price = parseMoney(_price.text);
    if (price == null || _rate <= 0) {
      return Text(t('Enter the price and the interest rate.'), style: muted);
    }
    final down = price * _downPct / 100;
    final loan = price - down;
    final monthly = emi(loan, _rate, _months);
    final total = monthly * _months;
    final charges = widget.price == price && widget.charges != null ? widget.charges! : _chargesOn(price);
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${rupees(monthly)} ${t('a month')}', style: theme.textTheme.headlineMedium),
            Text(t('EMI for {years} years', {'years': '${_years.round()}'}), style: muted),
            const Divider(height: 24),
            _Line(t('Loan'), rupeesShort(loan)),
            _Line(t('Interest over the loan'), rupeesShort(total - loan)),
            _Line(t('Total repaid'), rupeesShort(total)),
            const SizedBox(height: 8),
            _Line(t('Down payment'), rupeesShort(down)),
            _Line(t('Stamp duty and registration (about)'), rupeesShort(charges)),
            _Line(t('Cash needed up front'), rupeesShort(down + charges), bold: true),
            const Divider(height: 24),
            _Line(t('Take-home pay banks usually want'), '${rupees(monthly * 2)} ${t('a month')}',
                note: t('EMI at about half of take-home pay, with no other loans')),
          ],
        ),
      ),
    );
  }

  List<Widget> _budgetInputs() => [
        TextField(
          controller: _budget,
          decoration: InputDecoration(
            labelText: t('EMI you can pay each month'),
            hintText: t('e.g. 45,000'),
            helperText: t('A common rule: no more than 40–50% of take-home pay'),
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _savings,
          decoration: InputDecoration(
            labelText: t('Savings for down payment and charges'),
            hintText: t('e.g. 25 L'),
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ];

  Widget _budgetResult(ThemeData theme, TextStyle? muted) {
    final monthly = parseMoney(_budget.text);
    final savings = parseMoney(_savings.text) ?? 0;
    if (monthly == null || _rate <= 0) {
      return Text(t('Enter the EMI you can pay and the interest rate.'), style: muted);
    }
    final loanMax = loanFor(monthly, _rate, _months);
    // Highest price where the loan needed fits both the EMI and the bank's limit.
    bool fits(double p) {
      final needed = p + _chargesOn(p) - savings;
      return needed <= loanMax && needed <= maxLtv(p) * p;
    }

    var lo = 0.0, hi = 50e7;
    for (var i = 0; i < 60; i++) {
      final mid = (lo + hi) / 2;
      if (fits(mid)) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final price = lo;
    final charges = _chargesOn(price);
    final loan = math.max(0.0, price + charges - savings);
    final limitedBySavings = loan < loanMax * 0.98;
    final mid = widget.rate?.bestMarketMid;
    final type = widget.rate?.propertyType;
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('About {price}', {'price': rupeesShort(price)}), style: theme.textTheme.headlineMedium),
            Text(t('is what you can buy for'), style: muted),
            const Divider(height: 24),
            _Line(t('Loan'), rupeesShort(loan), note: t('the most this EMI repays: {max}', {'max': rupeesShort(loanMax)})),
            _Line(t('From your savings'), rupeesShort(math.min(savings, price + charges))),
            _Line(t('Stamp duty and registration (about)'), rupeesShort(charges)),
            if (limitedBySavings)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  t('Your savings limit this, not the EMI: banks lend only part of the price, so more savings would raise it.'),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            if (mid != null && type != null && price > 0) ...[
              const Divider(height: 24),
              Text(
                type == 'agricultural_land'
                    ? t('At the market middle here, that is about {n} guntha.',
                        {'n': (price / mid / sqftPerGuntha).toStringAsFixed(1)})
                    : t('At the market middle here, {rate}, that is about {n} sq ft.',
                        {'rate': headline(type, mid), 'n': fmtInt(price / mid)}),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.note, this.bold = false});

  final String label;
  final String value;
  final String? note;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = bold ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: style),
                if (note != null)
                  Text(note!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: style?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
