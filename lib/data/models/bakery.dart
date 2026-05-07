import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  const MenuItem({required this.name, required this.price, required this.category, required this.imageUrl});

  final String name;
  final double price;
  final String category;
  final String imageUrl;

  factory MenuItem.fromMap(Map<String, dynamic> map) => MenuItem(
        name: map['name'] ?? '',
        price: (map['price'] ?? 0).toDouble(),
        category: map['category'] ?? 'Pastries',
        imageUrl: map['imageUrl'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'category': category,
        'imageUrl': imageUrl,
      };
}

class Bakery {
  const Bakery({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.category,
    required this.mood,
    required this.imageUrls,
    required this.rating,
    required this.reviewCount,
    required this.popularity,
    required this.trendingScore,
    required this.latitude,
    required this.longitude,
    required this.menu,
    required this.openUntil,
    this.distanceKm,
  });

  final String id;
  final String name;
  final String description;
  final String address;
  final String category;
  final String mood;
  final List<String> imageUrls;
  final double rating;
  final int reviewCount;
  final double popularity;
  final double trendingScore;
  final double latitude;
  final double longitude;
  final List<MenuItem> menu;
  final String openUntil;
  final double? distanceKm;

  Bakery copyWith({double? distanceKm}) => Bakery(
        id: id,
        name: name,
        description: description,
        address: address,
        category: category,
        mood: mood,
        imageUrls: imageUrls,
        rating: rating,
        reviewCount: reviewCount,
        popularity: popularity,
        trendingScore: trendingScore,
        latitude: latitude,
        longitude: longitude,
        menu: menu,
        openUntil: openUntil,
        distanceKm: distanceKm ?? this.distanceKm,
      );

  factory Bakery.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Bakery.fromMap(doc.id, data);
  }

  factory Bakery.fromMap(String id, Map<String, dynamic> map) => Bakery(
        id: id,
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        address: map['address'] ?? '',
        category: map['category'] ?? 'Cafe',
        mood: map['mood'] ?? 'Cozy Study Cafe',
        imageUrls: List<String>.from(map['imageUrls'] ?? const []),
        rating: (map['rating'] ?? 4.5).toDouble(),
        reviewCount: (map['reviewCount'] ?? 0).toInt(),
        popularity: (map['popularity'] ?? 50).toDouble(),
        trendingScore: (map['trendingScore'] ?? 50).toDouble(),
        latitude: (map['latitude'] ?? 28.4595).toDouble(),
        longitude: (map['longitude'] ?? 77.0266).toDouble(),
        menu: (map['menu'] as List<dynamic>? ?? const [])
            .map((item) => MenuItem.fromMap(Map<String, dynamic>.from(item)))
            .toList(),
        openUntil: map['openUntil'] ?? '10:00 PM',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'address': address,
        'category': category,
        'mood': mood,
        'imageUrls': imageUrls,
        'rating': rating,
        'reviewCount': reviewCount,
        'popularity': popularity,
        'trendingScore': trendingScore,
        'latitude': latitude,
        'longitude': longitude,
        'menu': menu.map((item) => item.toMap()).toList(),
        'openUntil': openUntil,
      };
}
