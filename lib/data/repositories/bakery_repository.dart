import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/cache_service.dart';
import '../models/bakery.dart';
import '../models/review.dart';

class BakeryRepository {
  BakeryRepository({
    FirebaseFirestore? firestore,
    CacheService? cacheService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cache = cacheService ?? CacheService();

  final FirebaseFirestore _firestore;
  final CacheService _cache;

  Future<List<Bakery>> fetchBakeries() async {
    try {
      final snapshot = await _firestore.collection('bakeries').get();
      final bakeries = snapshot.docs.map(Bakery.fromDoc).toList();
      final data = _withSeedFallbacks(bakeries);
      await _cache.cacheBakeries(data.map((bakery) => {'id': bakery.id, ...bakery.toMap()}).toList());
      return data;
    } catch (_) {
      final cached = await _cache.cachedBakeries();
      if (cached.isNotEmpty) {
        return _withSeedFallbacks(
          cached.map((map) => Bakery.fromMap(map['id'] as String, map)).toList(),
        );
      }
      return seedBakeries;
    }
  }

  List<Bakery> _withSeedFallbacks(List<Bakery> remoteOrCached) {
    if (remoteOrCached.isEmpty) return seedBakeries;
    final seedsById = {for (final bakery in seedBakeries) bakery.id: bakery};
    final refreshed = remoteOrCached.map((bakery) {
      final seed = seedsById[bakery.id];
      if (seed != null && bakery.menu.length < seed.menu.length) return seed;
      return bakery;
    }).toList();
    final ids = refreshed.map((bakery) => bakery.id).toSet();
    final missingSeeds = seedBakeries.where((bakery) => !ids.contains(bakery.id));
    return [...refreshed, ...missingSeeds];
  }

  Future<List<Review>> fetchReviews(String bakeryId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('bakeryId', isEqualTo: bakeryId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      final reviews = snapshot.docs.map(Review.fromDoc).toList();
      return reviews.isEmpty ? generatedReviews(bakeryId) : reviews;
    } catch (_) {
      return generatedReviews(bakeryId);
    }
  }
}

List<Review> generatedReviews(String bakeryId) {
  final comments = [
    ('Aarav', 4.8, 'Beautiful ambience, quick service, and the pastry layers tasted fresh instead of oily.'),
    ('Mira', 4.7, 'Loved the coffee balance. It was smooth, not bitter, and the seating felt calm enough to work.'),
    ('Kabir', 4.5, 'The staff explained the menu nicely and helped us pick a dessert that was not too sweet.'),
    ('Naina', 4.9, 'Presentation was lovely. The cakes felt premium and the place is perfect for evening plans.'),
    ('Rhea', 4.6, 'Good portions for the price. I would come back for the breads and cold coffee.'),
    ('Dev', 4.4, 'Slightly busy during peak hours, but the food quality and warm vibe made up for it.'),
  ];

  return comments.asMap().entries.map((entry) {
    final comment = entry.value;
    return Review(
      id: '$bakeryId-review-${entry.key}',
      bakeryId: bakeryId,
      userName: comment.$1,
      rating: comment.$2,
      comment: comment.$3,
      createdAt: DateTime.now().subtract(Duration(days: entry.key + 1)),
    );
  }).toList();
}

List<MenuItem> menuFor(String bakeryId) {
  const coffee = 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=800&q=85';
  const coldCoffee = 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=800&q=85';
  const pastry = 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800&q=85';
  const cake = 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800&q=85';
  const dessert = 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=800&q=85';
  const tart = 'https://images.unsplash.com/photo-1464305795204-6f5bbfc7fb81?w=800&q=85';
  const bread = 'https://images.unsplash.com/photo-1589367920969-ab8e050eb0e9?w=800&q=85';

  final menus = {
    'woodrose-cafe': [
      const MenuItem(name: 'Rose Cappuccino', price: 210, category: 'Coffee', imageUrl: coffee),
      const MenuItem(name: 'Spanish Latte', price: 240, category: 'Coffee', imageUrl: coffee),
      const MenuItem(name: 'Classic Cold Coffee', price: 230, category: 'Coffee', imageUrl: coldCoffee),
      const MenuItem(name: 'Chocolate Tea Cake', price: 180, category: 'Cakes', imageUrl: cake),
      const MenuItem(name: 'Blueberry Muffin', price: 155, category: 'Pastries', imageUrl: pastry),
      const MenuItem(name: 'Almond Croissant', price: 225, category: 'Pastries', imageUrl: pastry),
      const MenuItem(name: 'Grilled Pesto Sandwich', price: 290, category: 'Bread', imageUrl: bread),
      const MenuItem(name: 'Mushroom Cheese Toast', price: 270, category: 'Bread', imageUrl: bread),
      const MenuItem(name: 'Biscoff Cheesecake Slice', price: 260, category: 'Desserts', imageUrl: dessert),
      const MenuItem(name: 'Strawberry Tart', price: 240, category: 'Desserts', imageUrl: tart),
    ],
    'theobroma-galleria': [
      const MenuItem(name: 'Millionaire Brownie', price: 145, category: 'Desserts', imageUrl: dessert),
      const MenuItem(name: 'Overload Brownie', price: 160, category: 'Desserts', imageUrl: dessert),
      const MenuItem(name: 'Dutch Truffle Cake', price: 260, category: 'Cakes', imageUrl: cake),
      const MenuItem(name: 'Red Velvet Pastry', price: 230, category: 'Cakes', imageUrl: cake),
      const MenuItem(name: 'New York Cheesecake', price: 275, category: 'Desserts', imageUrl: dessert),
      const MenuItem(name: 'Chocolate Chip Cookie Box', price: 220, category: 'Desserts', imageUrl: pastry),
      const MenuItem(name: 'Butter Croissant', price: 175, category: 'Pastries', imageUrl: pastry),
      const MenuItem(name: 'Pain au Chocolat', price: 195, category: 'Pastries', imageUrl: pastry),
      const MenuItem(name: 'Iced Mocha', price: 230, category: 'Coffee', imageUrl: coldCoffee),
      const MenuItem(name: 'Cappuccino', price: 190, category: 'Coffee', imageUrl: coffee),
    ],
    'blue-tokai-gurugram': [
      const MenuItem(name: 'Pour Over Coffee', price: 260, category: 'Coffee', imageUrl: coffee),
      const MenuItem(name: 'Iced Latte', price: 230, category: 'Coffee', imageUrl: coldCoffee),
      const MenuItem(name: 'Vietnamese Iced Coffee', price: 250, category: 'Coffee', imageUrl: coldCoffee),
      const MenuItem(name: 'Sea Salt Mocha', price: 260, category: 'Coffee', imageUrl: coffee),
      const MenuItem(name: 'Butter Croissant', price: 190, category: 'Pastries', imageUrl: pastry),
      const MenuItem(name: 'Almond Croissant', price: 230, category: 'Pastries', imageUrl: pastry),
      const MenuItem(name: 'Banana Walnut Bread', price: 180, category: 'Bread', imageUrl: bread),
      const MenuItem(name: 'Avocado Sourdough Toast', price: 340, category: 'Bread', imageUrl: bread),
      const MenuItem(name: 'Coffee Tiramisu Cup', price: 280, category: 'Desserts', imageUrl: dessert),
      const MenuItem(name: 'Dark Chocolate Cookie', price: 130, category: 'Desserts', imageUrl: pastry),
    ],
    'third-wave-coffee': [
      const MenuItem(name: 'Classic Cold Coffee', price: 240, category: 'Coffee', imageUrl: coldCoffee),
      const MenuItem(name: 'Caramel Macchiato', price: 275, category: 'Coffee', imageUrl: coffee),
      const MenuItem(name: 'Hazelnut Cappuccino', price: 245, category: 'Coffee', imageUrl: coffee),
      const MenuItem(name: 'Mocha Frappe', price: 285, category: 'Coffee', imageUrl: coldCoffee),
      const MenuItem(name: 'Banana Walnut Bread', price: 170, category: 'Bread', imageUrl: bread),
      const MenuItem(name: 'Cheese Garlic Croissant', price: 240, category: 'Pastries', imageUrl: pastry),
      const MenuItem(name: 'Blueberry Cheesecake', price: 290, category: 'Desserts', imageUrl: dessert),
      const MenuItem(name: 'Double Chocolate Muffin', price: 185, category: 'Pastries', imageUrl: pastry),
      const MenuItem(name: 'Sourdough Veggie Melt', price: 330, category: 'Bread', imageUrl: bread),
      const MenuItem(name: 'Cinnamon Roll', price: 210, category: 'Desserts', imageUrl: pastry),
    ],
    'sweet-crumbs': [
      const MenuItem(name: 'Pistachio Cruffin', price: 260, category: 'Pastries', imageUrl: pastry),
      const MenuItem(name: 'Orange Cold Brew', price: 220, category: 'Coffee', imageUrl: coldCoffee),
      const MenuItem(name: 'Raspberry Mille-Feuille', price: 320, category: 'Pastries', imageUrl: pastry),
      const MenuItem(name: 'Vanilla Bean Eclair', price: 240, category: 'Pastries', imageUrl: pastry),
      const MenuItem(name: 'Paris Brest', price: 310, category: 'Desserts', imageUrl: dessert),
      const MenuItem(name: 'Opera Cake Slice', price: 340, category: 'Cakes', imageUrl: cake),
      const MenuItem(name: 'Salted Caramel Tart', price: 275, category: 'Desserts', imageUrl: tart),
      const MenuItem(name: 'Rose Pistachio Latte', price: 255, category: 'Coffee', imageUrl: coffee),
      const MenuItem(name: 'Truffle Mushroom Brioche', price: 360, category: 'Bread', imageUrl: bread),
      const MenuItem(name: 'Lemon Meringue Tart', price: 265, category: 'Desserts', imageUrl: tart),
    ],
    'brown-butter': [
      const MenuItem(name: 'Sourdough Tartine', price: 310, category: 'Bread', imageUrl: bread),
      const MenuItem(name: 'Hazelnut Latte', price: 210, category: 'Coffee', imageUrl: coffee),
      const MenuItem(name: 'Cinnamon Knot', price: 185, category: 'Pastries', imageUrl: pastry),
      const MenuItem(name: 'Everything Bagel Toastie', price: 290, category: 'Bread', imageUrl: bread),
      const MenuItem(name: 'Basque Cheesecake', price: 285, category: 'Desserts', imageUrl: dessert),
      const MenuItem(name: 'Brown Butter Cookie', price: 125, category: 'Desserts', imageUrl: pastry),
      const MenuItem(name: 'Rosemary Focaccia Slab', price: 220, category: 'Bread', imageUrl: bread),
      const MenuItem(name: 'Iced Americano', price: 190, category: 'Coffee', imageUrl: coldCoffee),
      const MenuItem(name: 'Apple Crumble Danish', price: 240, category: 'Pastries', imageUrl: pastry),
      const MenuItem(name: 'Dark Chocolate Babka', price: 260, category: 'Bread', imageUrl: bread),
    ],
    'moonlit-cafe': [
      const MenuItem(name: 'Tiramisu Jar', price: 280, category: 'Desserts', imageUrl: dessert),
      const MenuItem(name: 'Sea Salt Mocha', price: 240, category: 'Coffee', imageUrl: coffee),
      const MenuItem(name: 'Midnight Cold Brew', price: 235, category: 'Coffee', imageUrl: coldCoffee),
      const MenuItem(name: 'Nutella Waffle Stack', price: 330, category: 'Desserts', imageUrl: dessert),
      const MenuItem(name: 'Lotus Biscoff Cheesecake', price: 295, category: 'Desserts', imageUrl: dessert),
      const MenuItem(name: 'Chocolate Hazelnut Croissant', price: 245, category: 'Pastries', imageUrl: pastry),
      const MenuItem(name: 'Garlic Cream Cheese Bun', price: 210, category: 'Bread', imageUrl: bread),
      const MenuItem(name: 'Affogato', price: 220, category: 'Coffee', imageUrl: coffee),
      const MenuItem(name: 'Berry Danish', price: 235, category: 'Pastries', imageUrl: pastry),
      const MenuItem(name: 'Molten Chocolate Cup', price: 260, category: 'Desserts', imageUrl: dessert),
    ],
    'oven-and-orchard': [
      const MenuItem(name: 'Belgian Chocolate Cake', price: 520, category: 'Cakes', imageUrl: cake),
      const MenuItem(name: 'Berry Mini Tart', price: 190, category: 'Desserts', imageUrl: tart),
      const MenuItem(name: 'Fresh Fruit Gateaux', price: 480, category: 'Cakes', imageUrl: cake),
      const MenuItem(name: 'Vanilla Sprinkle Cupcake', price: 120, category: 'Cakes', imageUrl: cake),
      const MenuItem(name: 'Pull-Apart Garlic Bread', price: 240, category: 'Bread', imageUrl: bread),
      const MenuItem(name: 'Cheese Corn Puff', price: 160, category: 'Pastries', imageUrl: pastry),
      const MenuItem(name: 'Hot Chocolate', price: 210, category: 'Coffee', imageUrl: coffee),
      const MenuItem(name: 'Strawberry Milk Cake', price: 300, category: 'Desserts', imageUrl: dessert),
      const MenuItem(name: 'Multigrain Sandwich Loaf', price: 220, category: 'Bread', imageUrl: bread),
      const MenuItem(name: 'Apple Pie Slice', price: 230, category: 'Desserts', imageUrl: tart),
    ],
    'cocoa-courtyard': [
      const MenuItem(name: 'Molten Brownie', price: 250, category: 'Desserts', imageUrl: dessert),
      const MenuItem(name: 'Caramel Cappuccino', price: 210, category: 'Coffee', imageUrl: coffee),
      const MenuItem(name: 'Belgian Chocolate Mousse', price: 280, category: 'Desserts', imageUrl: dessert),
      const MenuItem(name: 'Cocoa Hazelnut Tart', price: 275, category: 'Desserts', imageUrl: tart),
      const MenuItem(name: 'Mocha Cold Brew', price: 245, category: 'Coffee', imageUrl: coldCoffee),
      const MenuItem(name: 'Chocolate Croissant', price: 220, category: 'Pastries', imageUrl: pastry),
      const MenuItem(name: 'Espresso Cheesecake', price: 295, category: 'Cakes', imageUrl: cake),
      const MenuItem(name: 'Fudge Cookie Skillet', price: 260, category: 'Desserts', imageUrl: dessert),
      const MenuItem(name: 'Cocoa Banana Bread', price: 190, category: 'Bread', imageUrl: bread),
      const MenuItem(name: 'Salted Caramel Eclair', price: 240, category: 'Pastries', imageUrl: pastry),
    ],
  };

  return menus[bakeryId] ?? menus['sweet-crumbs']!;
}

final seedBakeries = <Bakery>[
  Bakery(
    id: 'woodrose-cafe',
    name: 'Woodrose Cafe',
    description: 'A pretty neighborhood cafe for cappuccinos, loaded sandwiches, cakes, and calm catch-ups.',
    address: 'South City, Gurugram',
    category: 'Coffee',
    mood: 'Cozy Study Cafe',
    imageUrls: const [
      'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=1200&q=85',
      'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=1200&q=85',
    ],
    rating: 4.6,
    reviewCount: 176,
    popularity: 81,
    trendingScore: 79,
    latitude: 28.4518,
    longitude: 77.0648,
    openUntil: '10:30 PM',
    menu: menuFor('woodrose-cafe'),
  ),
  Bakery(
    id: 'theobroma-galleria',
    name: 'Theobroma',
    description: 'Known for brownies, dense cakes, cookies, and quick dessert boxes for gifting.',
    address: 'Galleria Market, Gurugram',
    category: 'Desserts',
    mood: 'Family Bakery',
    imageUrls: const [
      'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=1200&q=85',
      'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=1200&q=85',
    ],
    rating: 4.5,
    reviewCount: 512,
    popularity: 92,
    trendingScore: 83,
    latitude: 28.4680,
    longitude: 77.0813,
    openUntil: '11:00 PM',
    menu: menuFor('theobroma-galleria'),
  ),
  Bakery(
    id: 'blue-tokai-gurugram',
    name: 'Blue Tokai Coffee Roasters',
    description: 'Specialty coffee cafe with pour overs, iced lattes, croissants, and work-friendly seating.',
    address: 'DLF Phase 1, Gurugram',
    category: 'Coffee',
    mood: 'Cozy Study Cafe',
    imageUrls: const [
      'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=1200&q=85',
      'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=1200&q=85',
    ],
    rating: 4.7,
    reviewCount: 623,
    popularity: 95,
    trendingScore: 90,
    latitude: 28.4757,
    longitude: 77.1007,
    openUntil: '11:00 PM',
    menu: menuFor('blue-tokai-gurugram'),
  ),
  Bakery(
    id: 'third-wave-coffee',
    name: 'Third Wave Coffee',
    description: 'Modern coffee chain with espresso drinks, banana bread, cookies, and bright cafe seating.',
    address: 'Cyber Hub, Gurugram',
    category: 'Coffee',
    mood: 'Late Night Coffee',
    imageUrls: const [
      'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=1200&q=85',
      'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=1200&q=85',
    ],
    rating: 4.4,
    reviewCount: 448,
    popularity: 89,
    trendingScore: 86,
    latitude: 28.4945,
    longitude: 77.0886,
    openUntil: '12:00 AM',
    menu: menuFor('third-wave-coffee'),
  ),
  Bakery(
    id: 'sweet-crumbs',
    name: 'Sweet Crumbs Atelier',
    description: 'A refined patisserie with plated desserts, single-origin coffee, and buttery morning bakes.',
    address: 'Galleria Market, Gurugram',
    category: 'Pastries',
    mood: 'Date Spot',
    imageUrls: const [
      'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=1200&q=85',
      'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=1200&q=85',
    ],
    rating: 4.9,
    reviewCount: 328,
    popularity: 94,
    trendingScore: 91,
    latitude: 28.4675,
    longitude: 77.0818,
    openUntil: '11:00 PM',
    menu: menuFor('sweet-crumbs'),
  ),
  Bakery(
    id: 'brown-butter',
    name: 'Brown Butter Room',
    description: 'Warm, wood-toned cafe known for sourdough toasties, cinnamon knots, and slow weekend brunch.',
    address: 'DLF Phase 4, Gurugram',
    category: 'Bread',
    mood: 'Cozy Study Cafe',
    imageUrls: const [
      'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=1200&q=85',
      'https://images.unsplash.com/photo-1517433670267-08bbd4be890f?w=1200&q=85',
    ],
    rating: 4.7,
    reviewCount: 214,
    popularity: 82,
    trendingScore: 78,
    latitude: 28.4648,
    longitude: 77.0732,
    openUntil: '10:30 PM',
    menu: menuFor('brown-butter'),
  ),
  Bakery(
    id: 'moonlit-cafe',
    name: 'Moonlit Cafe & Bakes',
    description: 'Late-night coffee bar with dessert jars, cheesecakes, and a relaxed after-hours crowd.',
    address: 'Cyber Hub, Gurugram',
    category: 'Coffee',
    mood: 'Late Night Coffee',
    imageUrls: const [
      'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=1200&q=85',
      'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=1200&q=85',
    ],
    rating: 4.6,
    reviewCount: 401,
    popularity: 90,
    trendingScore: 88,
    latitude: 28.4950,
    longitude: 77.0880,
    openUntil: '1:00 AM',
    menu: menuFor('moonlit-cafe'),
  ),
  Bakery(
    id: 'oven-and-orchard',
    name: 'Oven & Orchard',
    description: 'Family-friendly bakery with celebration cakes, kids treats, and bright garden seating.',
    address: 'Golf Course Road, Gurugram',
    category: 'Cakes',
    mood: 'Family Bakery',
    imageUrls: const [
      'https://images.unsplash.com/photo-1559620192-032c4bc4674e?w=1200&q=85',
      'https://images.unsplash.com/photo-1464349095431-e9a21285b5f3?w=1200&q=85',
    ],
    rating: 4.8,
    reviewCount: 286,
    popularity: 86,
    trendingScore: 84,
    latitude: 28.4420,
    longitude: 77.1010,
    openUntil: '10:00 PM',
    menu: menuFor('oven-and-orchard'),
  ),
  Bakery(
    id: 'cocoa-courtyard',
    name: 'Cocoa Courtyard',
    description: 'Dessert-forward cafe with plated brownies, mousse cups, and polished outdoor seating.',
    address: 'Udyog Vihar, Gurugram',
    category: 'Desserts',
    mood: 'Date Spot',
    imageUrls: const [
      'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=1200&q=85',
      'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=1200&q=85',
    ],
    rating: 4.5,
    reviewCount: 192,
    popularity: 72,
    trendingScore: 80,
    latitude: 28.5054,
    longitude: 77.0720,
    openUntil: '11:30 PM',
    menu: menuFor('cocoa-courtyard'),
  ),
];
