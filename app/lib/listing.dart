/// Reads price, size, property type and locality out of listing text
/// shared from a property portal (or pasted), e.g.
/// "3 BHK Flat for sale in Whitefield, Bangalore – ₹1.2 Cr, 1,650 sq.ft".
library;

import 'format.dart';

class ParsedListing {
  String? type;
  double? price; // total ₹
  double? size;
  String? sizeUnit;
  double? rate; // ₹ per [rateUnit]
  String? rateUnit;
  String? locality;
  String? url;

  bool get hasRate => rate != null && rateUnit != null;
}

const _unitPattern =
    r'(sq\.?\s*f(?:ee)?t\.?|sqft|sft|sq\.?\s*m(?:eters?|etres?|tr)?\.?|sqm|sq\.?\s*y(?:ar)?ds?\.?|sq\.?\s*yards?|gunt?h?as?|acres?)';

/// Our unit code for a unit as written in a listing.
String? unitCode(String raw) {
  final u = raw.toLowerCase().replaceAll(RegExp(r'[\s.]'), '');
  if (u.startsWith('acre')) return 'acre';
  if (u.startsWith('gunt')) return 'guntha';
  if (u.contains('y')) return 'sqyd';
  if (u.startsWith('sqm') || u.startsWith('sqmeter') || u.startsWith('sqmetre') || u == 'sqmtr') return 'sqm';
  if (u.contains('f') || u == 'sft') return 'sqft';
  return null;
}

/// Rupees from "1.2", "cr" → 12000000. Suffix may be cr, crore, l, lac, lakh, k.
double? amount(String number, String? suffix) {
  final n = double.tryParse(number.replaceAll(',', ''));
  if (n == null) return null;
  final s = (suffix ?? '').toLowerCase();
  if (s.startsWith('c')) return n * 1e7;
  if (s.startsWith('l')) return n * 1e5;
  if (s.startsWith('k')) return n * 1e3;
  return n;
}

/// Free-typed money, e.g. "85 L", "1.2 cr", "45,00,000". Null if unreadable.
double? parseMoney(String text) {
  final m = RegExp(r'^\s*(?:₹|rs\.?|inr)?\s*([\d,]+(?:\.\d+)?)\s*(cr|crores?|l|lacs?|lakhs?|k)?\s*$', caseSensitive: false)
      .firstMatch(text);
  return m == null ? null : amount(m.group(1)!, m.group(2));
}

/// ₹ per sq ft for a rate given per [unit].
double perSqft(double rate, String unit) => switch (unit) {
      'sqm' => rate / sqftPerSqm,
      'sqyd' => rate / 9,
      'guntha' => rate / sqftPerGuntha,
      'acre' => rate / sqftPerAcre,
      _ => rate,
    };

/// Size in sq ft for a size given in [unit].
double sizeSqft(double size, String unit) => switch (unit) {
      'sqm' => size * sqftPerSqm,
      'sqyd' => size * 9,
      'guntha' => size * sqftPerGuntha,
      'acre' => size * sqftPerAcre,
      _ => size,
    };

ParsedListing parseListing(String text) {
  final p = ParsedListing();
  final t = text.replaceAll(' ', ' ');
  final lower = t.toLowerCase();

  p.url = RegExp(r'https?://\S+').firstMatch(t)?.group(0);
  final body = p.url == null ? t : t.replaceAll(p.url!, ' ');

  // Property type
  if (RegExp(r'\b(agri(cultural)?|farm\s*land|farmland|acres? of land)\b').hasMatch(lower)) {
    p.type = 'agricultural_land';
  } else if (RegExp(r'\b(flat|apartment|\d\s*bhk\s*(flat|apartment)?|penthouse|studio)\b').hasMatch(lower) &&
      !RegExp(r'\b(villa|independent house|individual house)\b').hasMatch(lower)) {
    p.type = 'apartment';
  } else if (RegExp(r'\b(villa|independent house|individual house|house|row house|duplex)\b').hasMatch(lower)) {
    p.type = 'independent_house';
  } else if (RegExp(r'\b(plot|site|land)\b').hasMatch(lower)) {
    p.type = 'plot';
  }

  // Rate per unit, e.g. "₹8,500/sq.ft" or "8500 per sqft"
  final rateRe = RegExp(
      r'(?:₹|rs\.?|inr)?\s*([\d,]+(?:\.\d+)?)\s*(k|l|lacs?|lakhs?)?\s*(?:/|per)\s*' + _unitPattern,
      caseSensitive: false);
  final rm = rateRe.firstMatch(body);
  if (rm != null) {
    final unit = unitCode(rm.group(3)!);
    final v = amount(rm.group(1)!, rm.group(2));
    if (unit != null && v != null && v > 0) {
      p.rate = v;
      p.rateUnit = unit;
    }
  }

  // Total price: the first ₹ amount not followed by "/" or "per"
  final priceRe = RegExp(r'(?:₹|rs\.?|inr)\s*([\d,]+(?:\.\d+)?)\s*(cr|crores?|l|lacs?|lakhs?|k)?\b(?!\s*(?:/|per))',
      caseSensitive: false);
  for (final m in priceRe.allMatches(body)) {
    final v = amount(m.group(1)!, m.group(2));
    if (v != null && v >= 1e5) {
      p.price = v;
      break;
    }
  }
  if (p.price == null) {
    final m = RegExp(r'\b([\d.]+)\s*(cr|crores?|l|lacs?|lakhs?)\b', caseSensitive: false).firstMatch(body);
    if (m != null) p.price = amount(m.group(1)!, m.group(2));
  }

  // Size: "1,650 sq.ft", "2 acres", "30x40"
  final dim = RegExp(r'\b(\d{2})\s*[x×*]\s*(\d{2})\b').firstMatch(body);
  final sizeRe = RegExp(r'([\d,]+(?:\.\d+)?)\s*' + _unitPattern + r'(?!\s*\))', caseSensitive: false);
  for (final m in sizeRe.allMatches(body)) {
    // skip the per-unit rate match itself
    if (rm != null && m.start >= rm.start && m.end <= rm.end) continue;
    final before = body.substring(0, m.start).trimRight();
    if (before.endsWith('/') || before.toLowerCase().endsWith('per')) continue;
    final unit = unitCode(m.group(2)!);
    final v = double.tryParse(m.group(1)!.replaceAll(',', ''));
    if (unit != null && v != null && v > 0) {
      p.size = v;
      p.sizeUnit = unit;
      break;
    }
  }
  if (p.size == null && dim != null) {
    p.size = double.parse(dim.group(1)!) * double.parse(dim.group(2)!);
    p.sizeUnit = 'sqft';
  }

  if (!p.hasRate && p.price != null && p.size != null && p.sizeUnit != null) {
    p.rate = p.price! / p.size!;
    p.rateUnit = p.sizeUnit;
  }

  // Locality: "... in Whitefield, Bangalore" / "at Sarjapur Road"
  final loc = RegExp(
          r"\b(?:in|at|near)\s+([A-Z][A-Za-z0-9.'\- ]{2,40}?)\s*(?:,|\||–|-\s|:|\(|\.\s|\.$|\bfor\b|\bBangalore\b|\bBengaluru\b|\n|$)")
      .firstMatch(body);
  if (loc != null) {
    final name = loc.group(1)!.trim();
    if (!RegExp(r'^(Bangalore|Bengaluru|Karnataka|India)$', caseSensitive: false).hasMatch(name)) {
      p.locality = name;
    }
  }
  return p;
}
