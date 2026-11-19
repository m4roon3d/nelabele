import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One year's property tax payment, with an optional receipt photo.
class TaxPayment {
  TaxPayment({required this.fy, required this.amount, required this.paidOn, this.photo});

  /// Financial year starting April: 2026 means FY 2026-27.
  final int fy;
  final double amount;
  final DateTime paidOn;

  /// Receipt photo id in the PhotoStore.
  String? photo;

  Map<String, dynamic> toJson() =>
      {'fy': fy, 'amount': amount, 'paidOn': paidOn.toIso8601String(), if (photo != null) 'photo': photo};

  static TaxPayment fromJson(Map<String, dynamic> j) => TaxPayment(
        fy: (j['fy'] as num).toInt(),
        amount: (j['amount'] as num).toDouble(),
        paidOn: DateTime.tryParse(j['paidOn'] as String? ?? '') ?? DateTime.now(),
        photo: j['photo'] as String?,
      );
}

/// A property the user owns, kept on this device only.
class OwnedProperty {
  OwnedProperty({
    required this.id,
    this.name = '',
    this.village = false,
    this.pid = '',
    this.epid = '',
    this.sasNo = '',
    this.ward = '',
    this.notes = '',
    this.zone,
    this.tenanted = false,
    this.builtUp,
    this.yearBuilt,
    List<TaxPayment>? payments,
  }) : payments = payments ?? [];

  final String id;
  String name;

  /// Gram panchayat property (pays the panchayat) rather than GBA.
  bool village;
  String pid, epid, sasNo, ward, notes;

  /// For the estimate: UAV zone A–F, use, built-up sq ft, year built.
  String? zone;
  bool tenanted;
  double? builtUp;
  int? yearBuilt;
  final List<TaxPayment> payments;

  TaxPayment? paymentFor(int fy) {
    for (final p in payments) {
      if (p.fy == fy) return p;
    }
    return null;
  }

  TaxPayment? get latest {
    if (payments.isEmpty) return null;
    return payments.reduce((a, b) => a.fy >= b.fy ? a : b);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'village': village,
        'pid': pid,
        'epid': epid,
        'sasNo': sasNo,
        'ward': ward,
        'notes': notes,
        if (zone != null) 'zone': zone,
        'tenanted': tenanted,
        if (builtUp != null) 'builtUp': builtUp,
        if (yearBuilt != null) 'yearBuilt': yearBuilt,
        'payments': [for (final p in payments) p.toJson()],
      };

  static OwnedProperty fromJson(Map<String, dynamic> j) => OwnedProperty(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        village: j['village'] as bool? ?? false,
        pid: j['pid'] as String? ?? '',
        epid: j['epid'] as String? ?? '',
        sasNo: j['sasNo'] as String? ?? '',
        ward: j['ward'] as String? ?? '',
        notes: j['notes'] as String? ?? '',
        zone: j['zone'] as String?,
        tenanted: j['tenanted'] as bool? ?? false,
        builtUp: (j['builtUp'] as num?)?.toDouble(),
        yearBuilt: (j['yearBuilt'] as num?)?.toInt(),
        payments: [for (final p in (j['payments'] as List? ?? const [])) TaxPayment.fromJson((p as Map).cast())],
      );
}

/// The user's properties, on this device only.
class OwnedProperties {
  static const _prefKey = 'owned_properties';
  static final ValueNotifier<List<OwnedProperty>> all = ValueNotifier<List<OwnedProperty>>(const []);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null) return;
      all.value = [for (final j in jsonDecode(raw) as List) OwnedProperty.fromJson((j as Map).cast())];
    } catch (_) {}
  }

  static Future<void> save(List<OwnedProperty> list) async {
    all.value = List.unmodifiable(list);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode([for (final p in list) p.toJson()]));
  }

  static Future<void> put(OwnedProperty p) async {
    final list = [...all.value];
    final i = list.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      list[i] = p;
    } else {
      list.add(p);
    }
    await save(list);
  }

  static Future<void> remove(String id) => save([...all.value]..removeWhere((x) => x.id == id));
}

/// Financial year (April–March) a date falls in: 2026 for FY 2026-27.
int financialYear(DateTime d) => d.month >= 4 ? d.year : d.year - 1;

String fyLabel(int fy) => 'FY $fy-${((fy + 1) % 100).toString().padLeft(2, '0')}';

/// The official GBA (formerly BBMP) property tax site.
const gbaTaxUrl = 'https://bbmptax.karnataka.gov.in/';

/// Self-assessment unit area values, ₹ per sq ft per month, for residential
/// buildings by value zone (SAS; tenanted is twice self-occupied).
const residentialUav = {'A': 2.50, 'B': 2.00, 'C': 1.80, 'D': 1.60, 'E': 1.20, 'F': 1.00};

/// A rough yearly tax under the GBA self-assessment formula.
class TaxEstimate {
  TaxEstimate._(this.gross, this.depreciationPct, this.tax, this.cess);

  final double gross, depreciationPct, tax, cess;

  double get total => tax + cess;
  double get rebate => total * 0.05;

  /// Annual value = area × UAV × 10 months, less depreciation for age; tax is
  /// 20% of that for homes, plus 24% cess. Depreciation follows BBMP's worked
  /// examples at about 1% a year of age.
  static TaxEstimate? of(OwnedProperty p, {DateTime? today}) {
    final uav = residentialUav[p.zone];
    final area = p.builtUp;
    if (uav == null || area == null || area <= 0) return null;
    final rate = p.tenanted ? uav * 2 : uav;
    final gross = area * rate * 10;
    final year = (today ?? DateTime.now()).year;
    final age = p.yearBuilt == null ? 0 : (year - p.yearBuilt!).clamp(0, 100);
    final dep = p.yearBuilt == null ? 0.0 : (age + 1).clamp(0, 60).toDouble();
    final tax = gross * (1 - dep / 100) * 0.20;
    return TaxEstimate._(gross, dep, tax, tax * 0.24);
  }
}

/// A Google Calendar link for a yearly reminder on [date] (all day).
Uri yearlyReminderLink(DateTime date, String title, String details) {
  String d(DateTime x) =>
      '${x.year}${x.month.toString().padLeft(2, '0')}${x.day.toString().padLeft(2, '0')}';
  final end = date.add(const Duration(days: 1));
  return Uri.https('calendar.google.com', '/calendar/render', {
    'action': 'TEMPLATE',
    'text': title,
    'dates': '${d(date)}/${d(end)}',
    'recur': 'RRULE:FREQ=YEARLY',
    'details': details,
  });
}

/// The next 5 April from [today]: early in the rebate window.
DateTime nextReminderDate(DateTime today) {
  final thisYear = DateTime(today.year, 4, 5);
  return today.isBefore(thisYear) ? thisYear : DateTime(today.year + 1, 4, 5);
}
