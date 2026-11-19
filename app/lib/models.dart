/// Property types in the order the app shows them.
const propertyTypes = ['plot', 'agricultural_land', 'independent_house', 'apartment'];

String propertyLabel(String type) => switch (type) {
      'plot' => 'Plot',
      'agricultural_land' => 'Farmland',
      'independent_house' => 'House',
      'apartment' => 'Apartment',
      _ => type,
    };

String levelLabel(String level) => switch (level) {
      'village' => 'Village',
      'locality' => 'Locality',
      'ward' => 'Ward',
      'zone' => 'Zone',
      'hobli' => 'Hobli',
      'taluk' => 'Taluk',
      'district' => 'District',
      _ => level,
    };

double? _num(Object? v) => (v as num?)?.toDouble();

/// One property type's rates for one area. All rates are ₹ per sq ft.
class Rate {
  Rate({
    required this.propertyType,
    required this.guidanceRate,
    required this.guidanceEffective,
    required this.marketLow,
    required this.marketMid,
    required this.marketHigh,
    required this.marketObs,
    required this.confidence,
    this.sources = const [],
    this.estLow,
    this.estMid,
    this.estHigh,
    this.estRatio,
    this.estPlaces,
    this.prevGuidanceRate,
    this.prevGuidanceEffective,
    this.guidanceChangePct,
  });

  final String propertyType;
  final double? guidanceRate;
  final DateTime? guidanceEffective;
  final double? marketLow;
  final double? marketMid;
  final double? marketHigh;
  final int marketObs;
  final String confidence;
  final List<String> sources;

  /// Estimated market range for places without market data of their own.
  final double? estLow;
  final double? estMid;
  final double? estHigh;
  final double? estRatio;
  final int? estPlaces;

  /// Guidance value before the latest revision, when there has been one.
  final double? prevGuidanceRate;
  final DateTime? prevGuidanceEffective;
  final double? guidanceChangePct;

  bool get revised => guidanceChangePct != null && prevGuidanceEffective != null;

  bool get hasEstimate => estLow != null && estHigh != null;
  bool get fromReports => sources.contains('published');

  /// Market mid if known, else the estimate's mid.
  double? get bestMarketMid => marketMid ?? estMid;

  bool get hasMarket => marketLow != null && marketHigh != null;

  /// How many times the guidance value the market mid is, e.g. 1.8.
  double? get marketRatio {
    final g = guidanceRate, m = marketMid;
    if (g == null || m == null || g <= 0) return null;
    return m / g;
  }

  factory Rate.fromJson(Map<String, dynamic> j) => Rate(
        propertyType: j['property_type'] as String,
        guidanceRate: _num(j['guidance_rate']),
        guidanceEffective: j['guidance_effective'] == null
            ? null
            : DateTime.tryParse(j['guidance_effective'] as String),
        marketLow: _num(j['market_low']),
        marketMid: _num(j['market_mid']),
        marketHigh: _num(j['market_high']),
        marketObs: (j['market_obs'] as num?)?.toInt() ?? 0,
        confidence: (j['confidence'] as String?) ?? 'low',
        sources: [for (final s in (j['sources'] as List?) ?? const []) s as String],
        estLow: _num(j['est_low']),
        estMid: _num(j['est_mid']),
        estHigh: _num(j['est_high']),
        estRatio: _num(j['est_ratio']),
        estPlaces: (j['est_places'] as num?)?.toInt(),
        prevGuidanceRate: _num(j['prev_guidance_rate']),
        prevGuidanceEffective: j['prev_guidance_effective'] == null
            ? null
            : DateTime.tryParse(j['prev_guidance_effective'] as String),
        guidanceChangePct: _num(j['guidance_change_pct']),
      );
}

/// A village or locality with its rates by property type.
class Area {
  Area({
    required this.id,
    required this.name,
    required this.level,
    required this.district,
    required this.parentName,
    required this.parentLevel,
    required this.lat,
    required this.lon,
    this.nameKn,
    this.hasBoundary = false,
  });

  final int id;
  final String name;
  final String? nameKn;
  final bool hasBoundary;
  final String level;
  final String district;
  final String? parentName;
  final String? parentLevel;
  final double? lat;
  final double? lon;
  final Map<String, Rate> rates = {};

  factory Area.fromJson(Map<String, dynamic> j) => Area(
        id: (j['geo_area_id'] as num).toInt(),
        name: j['area_name'] as String,
        level: j['level'] as String,
        district: j['district'] as String,
        parentName: j['parent_name'] as String?,
        parentLevel: j['parent_level'] as String?,
        lat: _num(j['lat']),
        lon: _num(j['lon']),
        nameKn: j['name_kn'] as String?,
        hasBoundary: (j['has_boundary'] as bool?) ?? false,
      );

  List<Rate> get sortedRates => [
        for (final t in propertyTypes)
          if (rates[t] != null) rates[t]!,
        ...rates.values.where((r) => !propertyTypes.contains(r.propertyType)),
      ];

  String get subtitle => [
        levelLabel(level),
        if (parentName != null) parentLevel == 'zone' ? '$parentName area' : '$parentName taluk',
        district,
      ].join(' · ');
}

/// Latest city-wide price change (NHB RESIDEX).
class CityTrend {
  CityTrend({required this.city, required this.period, required this.yoyPct, required this.measure});

  final String city;
  final String period;
  final double yoyPct;
  final String measure;

  factory CityTrend.fromJson(Map<String, dynamic> j) => CityTrend(
        city: j['city'] as String,
        period: j['period'] as String,
        yoyPct: (j['yoy_pct'] as num).toDouble(),
        measure: j['measure'] as String,
      );
}

/// One market price for a place at a date (published or logged), ₹ per sq ft.
class PricePoint {
  PricePoint({required this.type, required this.date, required this.rate, required this.source, this.sourceRef});

  final String type;
  final DateTime date;
  final double rate;
  final String source;
  final String? sourceRef;

  /// The report and label part of a published price, without its link.
  String get label => (sourceRef ?? (source == 'published' ? 'Published price' : 'Logged rate')).split(' · ').first;

  factory PricePoint.fromJson(Map<String, dynamic> j) => PricePoint(
        type: j['property_type'] as String,
        date: DateTime.parse(j['observed_on'] as String),
        rate: (j['rate_per_sqft'] as num).toDouble(),
        source: j['source'] as String,
        sourceRef: j['source_ref'] as String?,
      );
}

/// Typical asking rent for a place, ₹ per sq ft per month, with its source.
class Rent {
  Rent({
    required this.type,
    required this.perSqft,
    required this.observedOn,
    required this.label,
    required this.report,
    required this.url,
  });

  final String type;
  final double perSqft;
  final DateTime observedOn;
  final String label;
  final String report;
  final String url;

  /// Gross yield in % for a price of [pricePerSqft].
  double yieldAt(double pricePerSqft) => perSqft * 12 / pricePerSqft * 100;

  factory Rent.fromJson(Map<String, dynamic> j) => Rent(
        type: j['property_type'] as String,
        perSqft: (j['rent_per_sqft'] as num).toDouble(),
        observedOn: DateTime.parse(j['observed_on'] as String),
        label: j['label'] as String,
        report: j['report'] as String,
        url: j['source_url'] as String,
      );
}
