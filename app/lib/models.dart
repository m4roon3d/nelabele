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
  });

  final int id;
  final String name;
  final String level;
  final String district;
  final String? parentName;
  final Map<String, Rate> rates = {};

  List<Rate> get sortedRates => [
        for (final t in propertyTypes)
          if (rates[t] != null) rates[t]!,
        ...rates.values.where((r) => !propertyTypes.contains(r.propertyType)),
      ];

  String get subtitle => [
        levelLabel(level),
        if (parentName != null) '$parentName taluk',
        district,
      ].join(' · ');
}
