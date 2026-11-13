/// Indian-style money formatting: ₹1,23,456 · ₹12.5 L · ₹1.2 Cr
library;

const sqftPerSqm = 10.7639;
const sqftPerAcre = 43560.0;
const sqftPerGuntha = 1089.0;

String _group(int n) {
  final s = n.abs().toString();
  if (s.length <= 3) return n < 0 ? '-$s' : s;
  final last3 = s.substring(s.length - 3);
  final rest = s
      .substring(0, s.length - 3)
      .replaceAllMapped(RegExp(r'\B(?=(\d{2})+(?!\d))'), (m) => ',');
  return '${n < 0 ? '-' : ''}$rest,$last3';
}

String _trim(String s) => s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;

/// Full rupees with Indian grouping, e.g. ₹8,500.
String rupees(num v) => '₹${_group(v.round())}';

/// A whole number with Indian digit grouping: 1,20,000.
String fmtInt(num v) => _group(v.round());

/// Short form for large amounts, e.g. ₹31 L, ₹1.1 Cr.
String rupeesShort(num v) {
  if (v >= 1e7) return '₹${_trim((v / 1e7).toStringAsFixed(2))} Cr';
  if (v >= 1e5) return '₹${_trim((v / 1e5).toStringAsFixed(1))} L';
  return rupees(v);
}

/// Headline figure for a rate given in ₹ per sq ft.
String headline(String type, double perSqft) => type == 'agricultural_land'
    ? '${rupeesShort(perSqft * sqftPerAcre)}/acre'
    : '${rupees(perSqft)}/sq ft';

/// Same rate in the other units people quote for this property type.
List<String> otherUnits(String type, double perSqft) => switch (type) {
      'agricultural_land' => [
          '${rupeesShort(perSqft * sqftPerGuntha)}/guntha',
          '${rupees(perSqft)}/sq ft',
        ],
      'apartment' => ['${rupees(perSqft * sqftPerSqm)}/sq m (super built-up)'],
      _ => [
          '${rupees(perSqft * sqftPerSqm)}/sq m',
          '${rupeesShort(perSqft * 1200)} for a 30×40 site',
        ],
    };

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String monthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';

/// "▲ 22%" / "▼ 5%" for a percentage change.
String changeLabel(double pct) => '${pct >= 0 ? '▲' : '▼'} ${pct.abs().toStringAsFixed(pct.abs() < 10 ? 1 : 0)}%';
