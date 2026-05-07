class GrokPlace {
  const GrokPlace({
    required this.name,
    required this.area,
    required this.why,
    required this.mapsQuery,
  });

  final String name;
  final String area;
  final String why;
  final String mapsQuery;

  factory GrokPlace.fromMap(Map<String, dynamic> map) => GrokPlace(
    name: (map['name'] ?? '').toString().trim(),
    area: (map['area'] ?? '').toString().trim(),
    why: (map['why'] ?? '').toString().trim(),
    mapsQuery: (map['maps_query'] ?? '').toString().trim(),
  );

  bool get isValid => name.isNotEmpty;
}
