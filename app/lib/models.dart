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
  });

  final String propertyType;
  final double? guidanceRate;
  final DateTime? guidanceEffective;
  final double? marketLow;
  final double? marketMid;
  final double? marketHigh;
  final int marketObs;
  final String confidence;

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
