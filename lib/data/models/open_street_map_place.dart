class OpenStreetMapPlace {
  const OpenStreetMapPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.category,
    this.osmType,
    this.osmId,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final String? category;
  final String? osmType;
  final int? osmId;

  String get subtitle => address ?? category ?? 'OpenStreetMap place';

  String get openStreetMapUrl =>
      'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=16/$latitude/$longitude';

  factory OpenStreetMapPlace.fromNominatim(Map<String, dynamic> json) {
    final latitude = double.tryParse(json['lat']?.toString() ?? '') ?? 0;
    final longitude = double.tryParse(json['lon']?.toString() ?? '') ?? 0;
    final displayName = (json['display_name'] as String?)?.trim() ?? '';

    return OpenStreetMapPlace(
      id: json['place_id']?.toString() ??
          '${latitude.toStringAsFixed(5)}_${longitude.toStringAsFixed(5)}',
      name: _extractName(json, displayName),
      latitude: latitude,
      longitude: longitude,
      address: displayName.isEmpty ? null : displayName,
      category: _toTitleCase(
        (json['type'] as String?) ??
            (json['category'] as String?) ??
            (json['class'] as String?),
      ),
      osmType: json['osm_type'] as String?,
      osmId: int.tryParse(json['osm_id']?.toString() ?? ''),
    );
  }

  factory OpenStreetMapPlace.fromPhoton(Map<String, dynamic> feature) {
    final geometry = feature['geometry'];
    final properties = feature['properties'];

    if (geometry is! Map<String, dynamic> || properties is! Map<String, dynamic>) {
      return const OpenStreetMapPlace(
        id: 'unknown',
        name: 'Place',
        latitude: 0,
        longitude: 0,
      );
    }

    final coordinates = geometry['coordinates'];
    double latitude = 0;
    double longitude = 0;
    if (coordinates is List && coordinates.length >= 2) {
      longitude = (coordinates[0] as num?)?.toDouble() ?? 0;
      latitude = (coordinates[1] as num?)?.toDouble() ?? 0;
    }

    final osmType = properties['osm_type']?.toString();
    final osmId = int.tryParse(properties['osm_id']?.toString() ?? '');
    final id = (osmType != null && osmId != null)
        ? '$osmType$osmId'
        : '${latitude.toStringAsFixed(5)}_${longitude.toStringAsFixed(5)}';

    final category =
        _toTitleCase(properties['osm_value']?.toString()) ??
        _toTitleCase(properties['osm_key']?.toString()) ??
        _toTitleCase(properties['type']?.toString());

    final address = _buildPhotonAddress(properties);

    return OpenStreetMapPlace(
      id: id,
      name: _extractPhotonName(properties, address),
      latitude: latitude,
      longitude: longitude,
      address: address,
      category: category,
      osmType: osmType,
      osmId: osmId,
    );
  }

  static String _extractPhotonName(
    Map<String, dynamic> properties,
    String? address,
  ) {
    final name = (properties['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (address != null && address.isNotEmpty) {
      return address.split(',').first.trim();
    }
    return 'Place';
  }

  static String? _buildPhotonAddress(Map<String, dynamic> properties) {
    const keys = [
      'housenumber',
      'street',
      'locality',
      'district',
      'city',
      'state',
      'country',
    ];
    final parts = <String>[];
    for (final key in keys) {
      final value = (properties[key] as String?)?.trim();
      if (value != null && value.isNotEmpty && !parts.contains(value)) {
        parts.add(value);
      }
    }
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  static String _extractName(Map<String, dynamic> json, String displayName) {
    final directName = (json['name'] as String?)?.trim();
    if (directName != null && directName.isNotEmpty) return directName;

    final namedetails = json['namedetails'];
    if (namedetails is Map<String, dynamic>) {
      final nameFromDetails = (namedetails['name'] as String?)?.trim();
      if (nameFromDetails != null && nameFromDetails.isNotEmpty) {
        return nameFromDetails;
      }
    }

    if (displayName.isEmpty) return 'Place';
    return displayName.split(',').first.trim();
  }

  static String? _toTitleCase(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.replaceAll('_', ' ').trim();
    final words = normalized.split(RegExp(r'\s+'));
    return words
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }
}
