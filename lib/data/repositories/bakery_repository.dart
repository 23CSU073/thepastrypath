import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/cache_service.dart';
import '../models/bakery.dart';
import '../models/review.dart';

class BakeryRepository {
  BakeryRepository({FirebaseFirestore? firestore, CacheService? cacheService})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _cache = cacheService ?? CacheService();

  final FirebaseFirestore _firestore;
  final CacheService _cache;

  Future<int> syncSeedBakeriesToFirestore() async {
    final collection = _firestore.collection('bakeries');
    var written = 0;
    final chunk = <Bakery>[];

    Future<void> commitChunk(List<Bakery> bakeries) async {
      if (bakeries.isEmpty) return;
      final batch = _firestore.batch();
      for (final bakery in bakeries) {
        final doc = collection.doc(bakery.id);
        batch.set(doc, bakery.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
      written += bakeries.length;
    }

    for (final bakery in seedBakeries) {
      chunk.add(bakery);
      if (chunk.length == 450) {
        await commitChunk(chunk);
        chunk.clear();
      }
    }
    await commitChunk(chunk);
    return written;
  }

  Future<List<Bakery>> fetchBakeries() async {
    try {
      final snapshot = await _firestore.collection('bakeries').get();
      final bakeries = snapshot.docs.map(Bakery.fromDoc).toList();
      final data = _withSeedFallbacks(bakeries);
      await _cache.cacheBakeries(
        data.map((bakery) => {'id': bakery.id, ...bakery.toMap()}).toList(),
      );
      return data;
    } catch (_) {
      final cached = await _cache.cachedBakeries();
      if (cached.isNotEmpty) {
        return _withSeedFallbacks(
          cached
              .map((map) => Bakery.fromMap(map['id'] as String, map))
              .toList(),
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
    final missingSeeds = seedBakeries.where(
      (bakery) => !ids.contains(bakery.id),
    );
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
    (
      'Aarav',
      4.8,
      'Beautiful ambience, quick service, and the pastry layers tasted fresh instead of oily.',
    ),
    (
      'Mira',
      4.7,
      'Loved the coffee balance. It was smooth, not bitter, and the seating felt calm enough to work.',
    ),
    (
      'Kabir',
      4.5,
      'The staff explained the menu nicely and helped us pick a dessert that was not too sweet.',
    ),
    (
      'Naina',
      4.9,
      'Presentation was lovely. The cakes felt premium and the place is perfect for evening plans.',
    ),
    (
      'Rhea',
      4.6,
      'Good portions for the price. I would come back for the breads and cold coffee.',
    ),
    (
      'Dev',
      4.4,
      'Slightly busy during peak hours, but the food quality and warm vibe made up for it.',
    ),
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
  const coffee =
      'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=800&q=85';
  const coldCoffee =
      'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=800&q=85';
  const pastry =
      'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800&q=85';
  const cake =
      'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800&q=85';
  const dessert =
      'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=800&q=85';
  const tart =
      'https://images.unsplash.com/photo-1464305795204-6f5bbfc7fb81?w=800&q=85';
  const bread =
      'https://images.unsplash.com/photo-1589367920969-ab8e050eb0e9?w=800&q=85';

  final menus = {
    'woodrose-cafe': [
      const MenuItem(
        name: 'Rose Cappuccino',
        price: 210,
        category: 'Coffee',
        imageUrl: coffee,
      ),
      const MenuItem(
        name: 'Spanish Latte',
        price: 240,
        category: 'Coffee',
        imageUrl: coffee,
      ),
      const MenuItem(
        name: 'Classic Cold Coffee',
        price: 230,
        category: 'Coffee',
        imageUrl: coldCoffee,
      ),
      const MenuItem(
        name: 'Chocolate Tea Cake',
        price: 180,
        category: 'Cakes',
        imageUrl: cake,
      ),
      const MenuItem(
        name: 'Blueberry Muffin',
        price: 155,
        category: 'Pastries',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Almond Croissant',
        price: 225,
        category: 'Pastries',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Grilled Pesto Sandwich',
        price: 290,
        category: 'Bread',
        imageUrl: bread,
      ),
      const MenuItem(
        name: 'Mushroom Cheese Toast',
        price: 270,
        category: 'Bread',
        imageUrl: bread,
      ),
      const MenuItem(
        name: 'Biscoff Cheesecake Slice',
        price: 260,
        category: 'Desserts',
        imageUrl: dessert,
      ),
      const MenuItem(
        name: 'Strawberry Tart',
        price: 240,
        category: 'Desserts',
        imageUrl: tart,
      ),
    ],
    'theobroma-galleria': [
      const MenuItem(
        name: 'Millionaire Brownie',
        price: 145,
        category: 'Desserts',
        imageUrl: dessert,
      ),
      const MenuItem(
        name: 'Overload Brownie',
        price: 160,
        category: 'Desserts',
        imageUrl: dessert,
      ),
      const MenuItem(
        name: 'Dutch Truffle Cake',
        price: 260,
        category: 'Cakes',
        imageUrl: cake,
      ),
      const MenuItem(
        name: 'Red Velvet Pastry',
        price: 230,
        category: 'Cakes',
        imageUrl: cake,
      ),
      const MenuItem(
        name: 'New York Cheesecake',
        price: 275,
        category: 'Desserts',
        imageUrl: dessert,
      ),
      const MenuItem(
        name: 'Chocolate Chip Cookie Box',
        price: 220,
        category: 'Desserts',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Butter Croissant',
        price: 175,
        category: 'Pastries',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Pain au Chocolat',
        price: 195,
        category: 'Pastries',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Iced Mocha',
        price: 230,
        category: 'Coffee',
        imageUrl: coldCoffee,
      ),
      const MenuItem(
        name: 'Cappuccino',
        price: 190,
        category: 'Coffee',
        imageUrl: coffee,
      ),
    ],
    'blue-tokai-gurugram': [
      const MenuItem(
        name: 'Pour Over Coffee',
        price: 260,
        category: 'Coffee',
        imageUrl: coffee,
      ),
      const MenuItem(
        name: 'Iced Latte',
        price: 230,
        category: 'Coffee',
        imageUrl: coldCoffee,
      ),
      const MenuItem(
        name: 'Vietnamese Iced Coffee',
        price: 250,
        category: 'Coffee',
        imageUrl: coldCoffee,
      ),
      const MenuItem(
        name: 'Sea Salt Mocha',
        price: 260,
        category: 'Coffee',
        imageUrl: coffee,
      ),
      const MenuItem(
        name: 'Butter Croissant',
        price: 190,
        category: 'Pastries',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Almond Croissant',
        price: 230,
        category: 'Pastries',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Banana Walnut Bread',
        price: 180,
        category: 'Bread',
        imageUrl: bread,
      ),
      const MenuItem(
        name: 'Avocado Sourdough Toast',
        price: 340,
        category: 'Bread',
        imageUrl: bread,
      ),
      const MenuItem(
        name: 'Coffee Tiramisu Cup',
        price: 280,
        category: 'Desserts',
        imageUrl: dessert,
      ),
      const MenuItem(
        name: 'Dark Chocolate Cookie',
        price: 130,
        category: 'Desserts',
        imageUrl: pastry,
      ),
    ],
    'third-wave-coffee': [
      const MenuItem(
        name: 'Classic Cold Coffee',
        price: 240,
        category: 'Coffee',
        imageUrl: coldCoffee,
      ),
      const MenuItem(
        name: 'Caramel Macchiato',
        price: 275,
        category: 'Coffee',
        imageUrl: coffee,
      ),
      const MenuItem(
        name: 'Hazelnut Cappuccino',
        price: 245,
        category: 'Coffee',
        imageUrl: coffee,
      ),
      const MenuItem(
        name: 'Mocha Frappe',
        price: 285,
        category: 'Coffee',
        imageUrl: coldCoffee,
      ),
      const MenuItem(
        name: 'Banana Walnut Bread',
        price: 170,
        category: 'Bread',
        imageUrl: bread,
      ),
      const MenuItem(
        name: 'Cheese Garlic Croissant',
        price: 240,
        category: 'Pastries',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Blueberry Cheesecake',
        price: 290,
        category: 'Desserts',
        imageUrl: dessert,
      ),
      const MenuItem(
        name: 'Double Chocolate Muffin',
        price: 185,
        category: 'Pastries',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Sourdough Veggie Melt',
        price: 330,
        category: 'Bread',
        imageUrl: bread,
      ),
      const MenuItem(
        name: 'Cinnamon Roll',
        price: 210,
        category: 'Desserts',
        imageUrl: pastry,
      ),
    ],
    'sweet-crumbs': [
      const MenuItem(
        name: 'Pistachio Cruffin',
        price: 260,
        category: 'Pastries',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Orange Cold Brew',
        price: 220,
        category: 'Coffee',
        imageUrl: coldCoffee,
      ),
      const MenuItem(
        name: 'Raspberry Mille-Feuille',
        price: 320,
        category: 'Pastries',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Vanilla Bean Eclair',
        price: 240,
        category: 'Pastries',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Paris Brest',
        price: 310,
        category: 'Desserts',
        imageUrl: dessert,
      ),
      const MenuItem(
        name: 'Opera Cake Slice',
        price: 340,
        category: 'Cakes',
        imageUrl: cake,
      ),
      const MenuItem(
        name: 'Salted Caramel Tart',
        price: 275,
        category: 'Desserts',
        imageUrl: tart,
      ),
      const MenuItem(
        name: 'Rose Pistachio Latte',
        price: 255,
        category: 'Coffee',
        imageUrl: coffee,
      ),
      const MenuItem(
        name: 'Truffle Mushroom Brioche',
        price: 360,
        category: 'Bread',
        imageUrl: bread,
      ),
      const MenuItem(
        name: 'Lemon Meringue Tart',
        price: 265,
        category: 'Desserts',
        imageUrl: tart,
      ),
    ],
    'brown-butter': [
      const MenuItem(
        name: 'Sourdough Tartine',
        price: 310,
        category: 'Bread',
        imageUrl: bread,
      ),
      const MenuItem(
        name: 'Hazelnut Latte',
        price: 210,
        category: 'Coffee',
        imageUrl: coffee,
      ),
      const MenuItem(
        name: 'Cinnamon Knot',
        price: 185,
        category: 'Pastries',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Everything Bagel Toastie',
        price: 290,
        category: 'Bread',
        imageUrl: bread,
      ),
      const MenuItem(
        name: 'Basque Cheesecake',
        price: 285,
        category: 'Desserts',
        imageUrl: dessert,
      ),
      const MenuItem(
        name: 'Brown Butter Cookie',
        price: 125,
        category: 'Desserts',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Rosemary Focaccia Slab',
        price: 220,
        category: 'Bread',
        imageUrl: bread,
      ),
      const MenuItem(
        name: 'Iced Americano',
        price: 190,
        category: 'Coffee',
        imageUrl: coldCoffee,
      ),
      const MenuItem(
        name: 'Apple Crumble Danish',
        price: 240,
        category: 'Pastries',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Dark Chocolate Babka',
        price: 260,
        category: 'Bread',
        imageUrl: bread,
      ),
    ],
    'moonlit-cafe': [
      const MenuItem(
        name: 'Tiramisu Jar',
        price: 280,
        category: 'Desserts',
        imageUrl: dessert,
      ),
      const MenuItem(
        name: 'Sea Salt Mocha',
        price: 240,
        category: 'Coffee',
        imageUrl: coffee,
      ),
      const MenuItem(
        name: 'Midnight Cold Brew',
        price: 235,
        category: 'Coffee',
        imageUrl: coldCoffee,
      ),
      const MenuItem(
        name: 'Nutella Waffle Stack',
        price: 330,
        category: 'Desserts',
        imageUrl: dessert,
      ),
      const MenuItem(
        name: 'Lotus Biscoff Cheesecake',
        price: 295,
        category: 'Desserts',
        imageUrl: dessert,
      ),
      const MenuItem(
        name: 'Chocolate Hazelnut Croissant',
        price: 245,
        category: 'Pastries',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Garlic Cream Cheese Bun',
        price: 210,
        category: 'Bread',
        imageUrl: bread,
      ),
      const MenuItem(
        name: 'Affogato',
        price: 220,
        category: 'Coffee',
        imageUrl: coffee,
      ),
      const MenuItem(
        name: 'Berry Danish',
        price: 235,
        category: 'Pastries',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Molten Chocolate Cup',
        price: 260,
        category: 'Desserts',
        imageUrl: dessert,
      ),
    ],
    'oven-and-orchard': [
      const MenuItem(
        name: 'Belgian Chocolate Cake',
        price: 520,
        category: 'Cakes',
        imageUrl: cake,
      ),
      const MenuItem(
        name: 'Berry Mini Tart',
        price: 190,
        category: 'Desserts',
        imageUrl: tart,
      ),
      const MenuItem(
        name: 'Fresh Fruit Gateaux',
        price: 480,
        category: 'Cakes',
        imageUrl: cake,
      ),
      const MenuItem(
        name: 'Vanilla Sprinkle Cupcake',
        price: 120,
        category: 'Cakes',
        imageUrl: cake,
      ),
      const MenuItem(
        name: 'Pull-Apart Garlic Bread',
        price: 240,
        category: 'Bread',
        imageUrl: bread,
      ),
      const MenuItem(
        name: 'Cheese Corn Puff',
        price: 160,
        category: 'Pastries',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Hot Chocolate',
        price: 210,
        category: 'Coffee',
        imageUrl: coffee,
      ),
      const MenuItem(
        name: 'Strawberry Milk Cake',
        price: 300,
        category: 'Desserts',
        imageUrl: dessert,
      ),
      const MenuItem(
        name: 'Multigrain Sandwich Loaf',
        price: 220,
        category: 'Bread',
        imageUrl: bread,
      ),
      const MenuItem(
        name: 'Apple Pie Slice',
        price: 230,
        category: 'Desserts',
        imageUrl: tart,
      ),
    ],
    'cocoa-courtyard': [
      const MenuItem(
        name: 'Molten Brownie',
        price: 250,
        category: 'Desserts',
        imageUrl: dessert,
      ),
      const MenuItem(
        name: 'Caramel Cappuccino',
        price: 210,
        category: 'Coffee',
        imageUrl: coffee,
      ),
      const MenuItem(
        name: 'Belgian Chocolate Mousse',
        price: 280,
        category: 'Desserts',
        imageUrl: dessert,
      ),
      const MenuItem(
        name: 'Cocoa Hazelnut Tart',
        price: 275,
        category: 'Desserts',
        imageUrl: tart,
      ),
      const MenuItem(
        name: 'Mocha Cold Brew',
        price: 245,
        category: 'Coffee',
        imageUrl: coldCoffee,
      ),
      const MenuItem(
        name: 'Chocolate Croissant',
        price: 220,
        category: 'Pastries',
        imageUrl: pastry,
      ),
      const MenuItem(
        name: 'Espresso Cheesecake',
        price: 295,
        category: 'Cakes',
        imageUrl: cake,
      ),
      const MenuItem(
        name: 'Fudge Cookie Skillet',
        price: 260,
        category: 'Desserts',
        imageUrl: dessert,
      ),
      const MenuItem(
        name: 'Cocoa Banana Bread',
        price: 190,
        category: 'Bread',
        imageUrl: bread,
      ),
      const MenuItem(
        name: 'Salted Caramel Eclair',
        price: 240,
        category: 'Pastries',
        imageUrl: pastry,
      ),
    ],
  };

  final aliases = <String, String>{
    'theobroma-sector-14': 'theobroma-galleria',
    'theobroma-baani-square': 'theobroma-galleria',
    'theobroma-m3m-urbana': 'theobroma-galleria',
    'theobroma-central-plaza53': 'theobroma-galleria',
    'binge-worldmark65': 'brown-butter',
    'binge-cyber-park39': 'brown-butter',
    'binge-nirvana50': 'brown-butter',
    'lopera-galleria': 'sweet-crumbs',
    'lopera-cyberhub': 'sweet-crumbs',
    'angels-sector14': 'oven-and-orchard',
    'angels-sector57': 'oven-and-orchard',
    'angels-sushant-lok': 'oven-and-orchard',
    'defence-bakery-sector15': 'brown-butter',
    'bakingo-studio-gurugram': 'theobroma-galleria',
    'big-chill-cakery-galleria': 'cocoa-courtyard',
    'big-chill-cakery-cyberhub': 'cocoa-courtyard',
    'suchalis-artisan53': 'brown-butter',
    'suchalis-artisan-udyog-vihar': 'brown-butter',
    'cakecity-galleria': 'theobroma-galleria',
    'breadtalk-galleria': 'third-wave-coffee',
    'harish-bakery-old-railway': 'oven-and-orchard',
    'miam-patisserie-chakkarpur': 'sweet-crumbs',
    'oh-boy-patisserie-66': 'sweet-crumbs',
    'sibang-bakery-south-point': 'blue-tokai-gurugram',
    'sibang-bakery-sushant-lok': 'blue-tokai-gurugram',
    'the-oberoi-patisserie': 'sweet-crumbs',
    'nik-bakers-56': 'brown-butter',
    'parisian-bakery-galleria': 'sweet-crumbs',
    'decakery-sector57': 'sweet-crumbs',
    'whipped-sector51': 'cocoa-courtyard',
    'starbucks-cyber-hub': 'third-wave-coffee',
    'starbucks-galleria': 'third-wave-coffee',
    'chaayos-cyber-city': 'woodrose-cafe',
    'chaayos-golf-course-road': 'woodrose-cafe',
    'cafe-dori-sector-43': 'brown-butter',
    'cafe-di-ghent-cross-point': 'brown-butter',
    'another-fine-day-galleria': 'blue-tokai-gurugram',
    'greenr-cafe-galleria': 'moonlit-cafe',
    'hamoni-cafe-sector-23': 'moonlit-cafe',
    'roots-cafe-sector-29': 'woodrose-cafe',
    'fig-at-museo-sector-43': 'blue-tokai-gurugram',
    'comorin-two-horizon': 'moonlit-cafe',
  };
  final menuId = aliases[bakeryId] ?? bakeryId;
  return menus[menuId] ?? menus['sweet-crumbs']!;
}

final seedBakeries = <Bakery>[
  Bakery(
    id: 'woodrose-cafe',
    name: 'Woodrose Cafe',
    description:
        'A pretty neighborhood cafe for cappuccinos, loaded sandwiches, cakes, and calm catch-ups.',
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
    description:
        'Known for brownies, dense cakes, cookies, and quick dessert boxes for gifting.',
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
    description:
        'Specialty coffee cafe with pour overs, iced lattes, croissants, and work-friendly seating.',
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
    description:
        'Modern coffee chain with espresso drinks, banana bread, cookies, and bright cafe seating.',
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
    description:
        'A refined patisserie with plated desserts, single-origin coffee, and buttery morning bakes.',
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
    description:
        'Warm, wood-toned cafe known for sourdough toasties, cinnamon knots, and slow weekend brunch.',
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
    description:
        'Late-night coffee bar with dessert jars, cheesecakes, and a relaxed after-hours crowd.',
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
    description:
        'Family-friendly bakery with celebration cakes, kids treats, and bright garden seating.',
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
    description:
        'Dessert-forward cafe with plated brownies, mousse cups, and polished outdoor seating.',
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
  Bakery(
    id: 'theobroma-sector-14',
    name: 'Theobroma Sector 14',
    description:
        'Fast moving pastry counter for brownies, cakes, and quick coffee breaks.',
    address: 'Sector 14 Market, Gurugram',
    category: 'Desserts',
    mood: 'Family Bakery',
    imageUrls: const [
      'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=1200&q=85',
      'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=1200&q=85',
    ],
    rating: 4.4,
    reviewCount: 367,
    popularity: 85,
    trendingScore: 80,
    latitude: 28.4730,
    longitude: 77.0484,
    openUntil: '11:00 PM',
    menu: menuFor('theobroma-sector-14'),
  ),
  Bakery(
    id: 'theobroma-baani-square',
    name: 'Theobroma Baani Square',
    description:
        'Popular bakery stop for dessert boxes, tea cakes, and evening cravings.',
    address: 'Baani Square, Sector 50, Gurugram',
    category: 'Cakes',
    mood: 'Family Bakery',
    imageUrls: const [
      'https://images.unsplash.com/photo-1559620192-032c4bc4674e?w=1200&q=85',
      'https://images.unsplash.com/photo-1464349095431-e9a21285b5f3?w=1200&q=85',
    ],
    rating: 4.5,
    reviewCount: 298,
    popularity: 82,
    trendingScore: 78,
    latitude: 28.4114,
    longitude: 77.0506,
    openUntil: '10:30 PM',
    menu: menuFor('theobroma-baani-square'),
  ),
  Bakery(
    id: 'theobroma-m3m-urbana',
    name: 'Theobroma M3M Urbana',
    description:
        'Dessert-heavy outlet with brownies, pastry slices, and fast takeaways.',
    address: 'M3M Urbana, Sector 67, Gurugram',
    category: 'Desserts',
    mood: 'Date Spot',
    imageUrls: const [
      'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=1200&q=85',
      'https://images.unsplash.com/photo-1559620192-032c4bc4674e?w=1200&q=85',
    ],
    rating: 4.3,
    reviewCount: 212,
    popularity: 76,
    trendingScore: 74,
    latitude: 28.3837,
    longitude: 77.0640,
    openUntil: '10:30 PM',
    menu: menuFor('theobroma-m3m-urbana'),
  ),
  Bakery(
    id: 'theobroma-central-plaza53',
    name: 'Theobroma Central Plaza',
    description:
        'Comfort bakery for dense chocolate desserts and quick gifting options.',
    address: 'Central Plaza, Sector 53, Gurugram',
    category: 'Desserts',
    mood: 'Family Bakery',
    imageUrls: const [
      'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=1200&q=85',
      'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=1200&q=85',
    ],
    rating: 4.4,
    reviewCount: 254,
    popularity: 79,
    trendingScore: 77,
    latitude: 28.4450,
    longitude: 77.1012,
    openUntil: '11:00 PM',
    menu: menuFor('theobroma-central-plaza53'),
  ),
  Bakery(
    id: 'binge-worldmark65',
    name: 'Binge Bakery Worldmark',
    description:
        'Modern bakery cafe with savory bakes, coffee, and plated sweets.',
    address: 'Worldmark, Sector 65, Gurugram',
    category: 'Pastries',
    mood: 'Cozy Study Cafe',
    imageUrls: const [
      'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=1200&q=85',
      'https://images.unsplash.com/photo-1517433670267-08bbd4be890f?w=1200&q=85',
    ],
    rating: 4.5,
    reviewCount: 189,
    popularity: 74,
    trendingScore: 79,
    latitude: 28.3962,
    longitude: 77.0658,
    openUntil: '11:00 PM',
    menu: menuFor('binge-worldmark65'),
  ),
  Bakery(
    id: 'binge-cyber-park39',
    name: 'Binge Bakery Cyber Park',
    description: 'Workday cafe for coffee, breads, and quick pastry combos.',
    address: 'Unitech Cyber Park, Sector 39, Gurugram',
    category: 'Coffee',
    mood: 'Late Night Coffee',
    imageUrls: const [
      'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=1200&q=85',
      'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=1200&q=85',
    ],
    rating: 4.4,
    reviewCount: 173,
    popularity: 72,
    trendingScore: 75,
    latitude: 28.4478,
    longitude: 77.0579,
    openUntil: '11:30 PM',
    menu: menuFor('binge-cyber-park39'),
  ),
  Bakery(
    id: 'binge-nirvana50',
    name: 'Binge Bakery Nirvana',
    description:
        'Neighborhood bakehouse with breads, brunch bakes, and evening desserts.',
    address: 'Nirvana Courtyard, Sector 50, Gurugram',
    category: 'Bread',
    mood: 'Cozy Study Cafe',
    imageUrls: const [
      'https://images.unsplash.com/photo-1589367920969-ab8e050eb0e9?w=1200&q=85',
      'https://images.unsplash.com/photo-1517433670267-08bbd4be890f?w=1200&q=85',
    ],
    rating: 4.3,
    reviewCount: 148,
    popularity: 68,
    trendingScore: 72,
    latitude: 28.4306,
    longitude: 77.0504,
    openUntil: '10:30 PM',
    menu: menuFor('binge-nirvana50'),
  ),
  Bakery(
    id: 'lopera-galleria',
    name: "L'Opera Patisserie Galleria",
    description:
        'French-style pastry boutique with tarts, entremets, and premium coffee.',
    address: 'Galleria Market, DLF Phase 4, Gurugram',
    category: 'Pastries',
    mood: 'Date Spot',
    imageUrls: const [
      'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=1200&q=85',
      'https://images.unsplash.com/photo-1464305795204-6f5bbfc7fb81?w=1200&q=85',
    ],
    rating: 4.7,
    reviewCount: 401,
    popularity: 88,
    trendingScore: 90,
    latitude: 28.4686,
    longitude: 77.0817,
    openUntil: '11:00 PM',
    menu: menuFor('lopera-galleria'),
  ),
  Bakery(
    id: 'lopera-cyberhub',
    name: "L'Opera Patisserie CyberHub",
    description:
        'Elegant pastry lounge with artisan desserts and celebration cakes.',
    address: 'Cyber Hub, DLF Phase 2, Gurugram',
    category: 'Desserts',
    mood: 'Date Spot',
    imageUrls: const [
      'https://images.unsplash.com/photo-1464305795204-6f5bbfc7fb81?w=1200&q=85',
      'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=1200&q=85',
    ],
    rating: 4.6,
    reviewCount: 276,
    popularity: 84,
    trendingScore: 87,
    latitude: 28.4958,
    longitude: 77.0886,
    openUntil: '11:30 PM',
    menu: menuFor('lopera-cyberhub'),
  ),
  Bakery(
    id: 'angels-sector14',
    name: 'Angels In My Kitchen Sector 14',
    description:
        'Trusted family bakery for custom cakes, puffs, and daily fresh breads.',
    address: 'Sector 14, Gurugram',
    category: 'Cakes',
    mood: 'Family Bakery',
    imageUrls: const [
      'https://images.unsplash.com/photo-1559620192-032c4bc4674e?w=1200&q=85',
      'https://images.unsplash.com/photo-1464349095431-e9a21285b5f3?w=1200&q=85',
    ],
    rating: 4.4,
    reviewCount: 329,
    popularity: 83,
    trendingScore: 79,
    latitude: 28.4733,
    longitude: 77.0487,
    openUntil: '10:30 PM',
    menu: menuFor('angels-sector14'),
  ),
  Bakery(
    id: 'angels-sector57',
    name: 'Angels In My Kitchen Sector 57',
    description:
        'Go-to neighborhood bakery for celebration cakes and snack platters.',
    address: 'Sector 57, Gurugram',
    category: 'Cakes',
    mood: 'Family Bakery',
    imageUrls: const [
      'https://images.unsplash.com/photo-1559620192-032c4bc4674e?w=1200&q=85',
      'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=1200&q=85',
    ],
    rating: 4.3,
    reviewCount: 217,
    popularity: 77,
    trendingScore: 74,
    latitude: 28.4223,
    longitude: 77.0703,
    openUntil: '10:00 PM',
    menu: menuFor('angels-sector57'),
  ),
  Bakery(
    id: 'defence-bakery-sector15',
    name: 'Defence Bakery Sector 15',
    description:
        'Classic bakery with patties, breads, and rich dessert options.',
    address: 'Sector 15 Part 2, Gurugram',
    category: 'Bread',
    mood: 'Family Bakery',
    imageUrls: const [
      'https://images.unsplash.com/photo-1589367920969-ab8e050eb0e9?w=1200&q=85',
      'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=1200&q=85',
    ],
    rating: 4.2,
    reviewCount: 194,
    popularity: 70,
    trendingScore: 71,
    latitude: 28.4597,
    longitude: 77.0458,
    openUntil: '10:00 PM',
    menu: menuFor('defence-bakery-sector15'),
  ),
  Bakery(
    id: 'bakingo-studio-gurugram',
    name: 'Bakingo Studio Gurugram',
    description:
        'Online-first cake studio known for quick birthday and event delivery.',
    address: 'Sector 22, Gurugram',
    category: 'Cakes',
    mood: 'Family Bakery',
    imageUrls: const [
      'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=1200&q=85',
      'https://images.unsplash.com/photo-1559620192-032c4bc4674e?w=1200&q=85',
    ],
    rating: 4.5,
    reviewCount: 421,
    popularity: 86,
    trendingScore: 85,
    latitude: 28.5210,
    longitude: 77.0211,
    openUntil: '12:00 AM',
    menu: menuFor('bakingo-studio-gurugram'),
  ),
  Bakery(
    id: 'big-chill-cakery-galleria',
    name: 'The Big Chill Cakery Galleria',
    description:
        'Dessert boutique with cheesecakes, rich slices, and signature baked treats.',
    address: 'Galleria Market, Gurugram',
    category: 'Desserts',
    mood: 'Date Spot',
    imageUrls: const [
      'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=1200&q=85',
      'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=1200&q=85',
    ],
    rating: 4.6,
    reviewCount: 365,
    popularity: 87,
    trendingScore: 88,
    latitude: 28.4682,
    longitude: 77.0815,
    openUntil: '11:00 PM',
    menu: menuFor('big-chill-cakery-galleria'),
  ),
  Bakery(
    id: 'suchalis-artisan53',
    name: "Suchali's Artisan Bakehouse",
    description:
        'Artisan bakery for sourdoughs, seasonal viennoiserie, and specialty brews.',
    address: 'Sector 53, Gurugram',
    category: 'Bread',
    mood: 'Cozy Study Cafe',
    imageUrls: const [
      'https://images.unsplash.com/photo-1517433670267-08bbd4be890f?w=1200&q=85',
      'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=1200&q=85',
    ],
    rating: 4.7,
    reviewCount: 241,
    popularity: 82,
    trendingScore: 86,
    latitude: 28.4553,
    longitude: 77.1040,
    openUntil: '10:30 PM',
    menu: menuFor('suchalis-artisan53'),
  ),
  Bakery(
    id: 'suchalis-artisan-udyog-vihar',
    name: "Suchali's Artisan Bakehouse Udyog Vihar",
    description:
        'Workday-friendly artisan counter with breads, buns, and coffee.',
    address: 'Udyog Vihar Phase 4, Gurugram',
    category: 'Bread',
    mood: 'Cozy Study Cafe',
    imageUrls: const [
      'https://images.unsplash.com/photo-1517433670267-08bbd4be890f?w=1200&q=85',
      'https://images.unsplash.com/photo-1589367920969-ab8e050eb0e9?w=1200&q=85',
    ],
    rating: 4.5,
    reviewCount: 178,
    popularity: 75,
    trendingScore: 80,
    latitude: 28.5006,
    longitude: 77.0723,
    openUntil: '10:00 PM',
    menu: menuFor('suchalis-artisan-udyog-vihar'),
  ),
  Bakery(
    id: 'cakecity-galleria',
    name: 'Cake City Galleria',
    description:
        'Celebration cake shop with custom themes, pastries, and classic bakes.',
    address: 'Galleria Market, Gurugram',
    category: 'Cakes',
    mood: 'Family Bakery',
    imageUrls: const [
      'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=1200&q=85',
      'https://images.unsplash.com/photo-1559620192-032c4bc4674e?w=1200&q=85',
    ],
    rating: 4.3,
    reviewCount: 153,
    popularity: 71,
    trendingScore: 73,
    latitude: 28.4681,
    longitude: 77.0810,
    openUntil: '10:30 PM',
    menu: menuFor('cakecity-galleria'),
  ),
  Bakery(
    id: 'harish-bakery-old-railway',
    name: 'Harish Bakery',
    description:
        'Old-school neighborhood bakery for rusks, breads, puffs, and snack bites.',
    address: 'Old Railway Road, Gurugram',
    category: 'Bread',
    mood: 'Family Bakery',
    imageUrls: const [
      'https://images.unsplash.com/photo-1589367920969-ab8e050eb0e9?w=1200&q=85',
      'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=1200&q=85',
    ],
    rating: 4.1,
    reviewCount: 238,
    popularity: 66,
    trendingScore: 67,
    latitude: 28.4641,
    longitude: 77.0298,
    openUntil: '9:30 PM',
    menu: menuFor('harish-bakery-old-railway'),
  ),
  Bakery(
    id: 'miam-patisserie-chakkarpur',
    name: 'Miam Patisserie',
    description:
        'Fine dessert studio serving modern pastry plates and curated coffee pairings.',
    address: 'Chakkarpur, Gurugram',
    category: 'Pastries',
    mood: 'Date Spot',
    imageUrls: const [
      'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=1200&q=85',
      'https://images.unsplash.com/photo-1464305795204-6f5bbfc7fb81?w=1200&q=85',
    ],
    rating: 4.6,
    reviewCount: 211,
    popularity: 80,
    trendingScore: 84,
    latitude: 28.4859,
    longitude: 77.0912,
    openUntil: '11:00 PM',
    menu: menuFor('miam-patisserie-chakkarpur'),
  ),
  Bakery(
    id: 'oh-boy-patisserie-66',
    name: 'Oh Boy Patisserie',
    description:
        'Small-batch pastry kitchen with flaky bakes, tartlets, and signature desserts.',
    address: 'Sector 66, Gurugram',
    category: 'Pastries',
    mood: 'Date Spot',
    imageUrls: const [
      'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=1200&q=85',
      'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=1200&q=85',
    ],
    rating: 4.5,
    reviewCount: 146,
    popularity: 74,
    trendingScore: 79,
    latitude: 28.3985,
    longitude: 77.0686,
    openUntil: '10:30 PM',
    menu: menuFor('oh-boy-patisserie-66'),
  ),
  Bakery(
    id: 'sibang-bakery-south-point',
    name: 'Sibang Bakery South Point',
    description:
        'Korean-style bakery cafe with soft breads, cream buns, and coffee.',
    address: 'South Point Mall, Golf Course Road, Gurugram',
    category: 'Bread',
    mood: 'Cozy Study Cafe',
    imageUrls: const [
      'https://images.unsplash.com/photo-1517433670267-08bbd4be890f?w=1200&q=85',
      'https://images.unsplash.com/photo-1589367920969-ab8e050eb0e9?w=1200&q=85',
    ],
    rating: 4.6,
    reviewCount: 302,
    popularity: 83,
    trendingScore: 86,
    latitude: 28.4476,
    longitude: 77.0978,
    openUntil: '11:00 PM',
    menu: menuFor('sibang-bakery-south-point'),
  ),
  Bakery(
    id: 'nik-bakers-56',
    name: "Nik Baker's Sector 56",
    description:
        'Cafe bakery serving breads, puff bakes, cookies, and coffee all day.',
    address: 'Sector 56 Market, Gurugram',
    category: 'Bread',
    mood: 'Cozy Study Cafe',
    imageUrls: const [
      'https://images.unsplash.com/photo-1589367920969-ab8e050eb0e9?w=1200&q=85',
      'https://images.unsplash.com/photo-1517433670267-08bbd4be890f?w=1200&q=85',
    ],
    rating: 4.3,
    reviewCount: 171,
    popularity: 73,
    trendingScore: 75,
    latitude: 28.4360,
    longitude: 77.1068,
    openUntil: '10:30 PM',
    menu: menuFor('nik-bakers-56'),
  ),
  Bakery(
    id: 'parisian-bakery-galleria',
    name: 'Parisian Bakery Galleria',
    description:
        'Boutique pastry corner for tartlets, eclairs, and premium tea-time desserts.',
    address: 'Galleria Market, Gurugram',
    category: 'Pastries',
    mood: 'Date Spot',
    imageUrls: const [
      'https://images.unsplash.com/photo-1464305795204-6f5bbfc7fb81?w=1200&q=85',
      'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=1200&q=85',
    ],
    rating: 4.4,
    reviewCount: 132,
    popularity: 69,
    trendingScore: 74,
    latitude: 28.4687,
    longitude: 77.0814,
    openUntil: '10:30 PM',
    menu: menuFor('parisian-bakery-galleria'),
  ),
  Bakery(
    id: 'decakery-sector57',
    name: 'Decakery Studio',
    description:
        'Design-forward cake studio for custom orders, premium pastries, and gifting.',
    address: 'Sector 57, Gurugram',
    category: 'Cakes',
    mood: 'Family Bakery',
    imageUrls: const [
      'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=1200&q=85',
      'https://images.unsplash.com/photo-1559620192-032c4bc4674e?w=1200&q=85',
    ],
    rating: 4.4,
    reviewCount: 115,
    popularity: 68,
    trendingScore: 72,
    latitude: 28.4218,
    longitude: 77.0708,
    openUntil: '10:00 PM',
    menu: menuFor('decakery-sector57'),
  ),
  Bakery(
    id: 'whipped-sector51',
    name: 'Whipped Dessert Boutique',
    description:
        'Dessert-focused boutique with mousse jars, cakes, and seasonal specials.',
    address: 'Sector 51, Gurugram',
    category: 'Desserts',
    mood: 'Date Spot',
    imageUrls: const [
      'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=1200&q=85',
      'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=1200&q=85',
    ],
    rating: 4.5,
    reviewCount: 143,
    popularity: 72,
    trendingScore: 78,
    latitude: 28.4198,
    longitude: 77.0547,
    openUntil: '11:00 PM',
    menu: menuFor('whipped-sector51'),
  ),
  Bakery(
    id: 'starbucks-cyber-hub',
    name: 'Starbucks Cyber Hub',
    description:
        'Busy coffee stop for espresso drinks, quick desserts, and workday meetups.',
    address: 'Cyber Hub, DLF Phase 2, Gurugram',
    category: 'Coffee',
    mood: 'Late Night Coffee',
    imageUrls: const [
      'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=1200&q=85',
      'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=1200&q=85',
    ],
    rating: 4.4,
    reviewCount: 684,
    popularity: 93,
    trendingScore: 89,
    latitude: 28.4954,
    longitude: 77.0889,
    openUntil: '12:00 AM',
    menu: menuFor('starbucks-cyber-hub'),
  ),
  Bakery(
    id: 'starbucks-galleria',
    name: 'Starbucks Galleria',
    description:
        'Neighborhood coffee lounge with cold brews, sandwiches, and pastry counters.',
    address: 'Galleria Market, DLF Phase 4, Gurugram',
    category: 'Coffee',
    mood: 'Cozy Study Cafe',
    imageUrls: const [
      'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=1200&q=85',
      'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=1200&q=85',
    ],
    rating: 4.3,
    reviewCount: 521,
    popularity: 88,
    trendingScore: 84,
    latitude: 28.4689,
    longitude: 77.0811,
    openUntil: '11:30 PM',
    menu: menuFor('starbucks-galleria'),
  ),
  Bakery(
    id: 'chaayos-cyber-city',
    name: 'Chaayos Cyber City',
    description:
        'Tea cafe known for custom chai, snacks, and quick evening catchups.',
    address: 'Cyber City, Gurugram',
    category: 'Coffee',
    mood: 'Late Night Coffee',
    imageUrls: const [
      'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=1200&q=85',
      'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=1200&q=85',
    ],
    rating: 4.2,
    reviewCount: 437,
    popularity: 85,
    trendingScore: 80,
    latitude: 28.4948,
    longitude: 77.0878,
    openUntil: '12:00 AM',
    menu: menuFor('chaayos-cyber-city'),
  ),
  Bakery(
    id: 'chaayos-golf-course-road',
    name: 'Chaayos Golf Course Road',
    description:
        'Comfort cafe for chai lovers with bakery snacks and relaxed seating.',
    address: 'Golf Course Road, Gurugram',
    category: 'Coffee',
    mood: 'Cozy Study Cafe',
    imageUrls: const [
      'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=1200&q=85',
      'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=1200&q=85',
    ],
    rating: 4.1,
    reviewCount: 318,
    popularity: 79,
    trendingScore: 76,
    latitude: 28.4494,
    longitude: 77.0986,
    openUntil: '11:00 PM',
    menu: menuFor('chaayos-golf-course-road'),
  ),
  Bakery(
    id: 'cafe-dori-sector-43',
    name: 'Cafe Dori Sector 43',
    description:
        'Design-led cafe space with artisanal coffee, plated bakes, and calm interiors.',
    address: 'Sector 43, Gurugram',
    category: 'Coffee',
    mood: 'Date Spot',
    imageUrls: const [
      'https://images.unsplash.com/photo-1517433670267-08bbd4be890f?w=1200&q=85',
      'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=1200&q=85',
    ],
    rating: 4.5,
    reviewCount: 266,
    popularity: 82,
    trendingScore: 85,
    latitude: 28.4501,
    longitude: 77.0918,
    openUntil: '11:00 PM',
    menu: menuFor('cafe-dori-sector-43'),
  ),
  Bakery(
    id: 'cafe-di-ghent-cross-point',
    name: 'Cafe Di Ghent Cross Point',
    description:
        'European-style cafe bakery with all-day breakfasts, breads, and coffee.',
    address: 'Cross Point Mall, DLF Phase 4, Gurugram',
    category: 'Bread',
    mood: 'Cozy Study Cafe',
    imageUrls: const [
      'https://images.unsplash.com/photo-1517433670267-08bbd4be890f?w=1200&q=85',
      'https://images.unsplash.com/photo-1589367920969-ab8e050eb0e9?w=1200&q=85',
    ],
    rating: 4.6,
    reviewCount: 492,
    popularity: 90,
    trendingScore: 87,
    latitude: 28.4668,
    longitude: 77.0755,
    openUntil: '11:30 PM',
    menu: menuFor('cafe-di-ghent-cross-point'),
  ),
  Bakery(
    id: 'another-fine-day-galleria',
    name: 'Another Fine Day Galleria',
    description:
        'A modern cafe for handcrafted coffee, brunch plates, and casual work sessions.',
    address: 'Galleria Market, Gurugram',
    category: 'Coffee',
    mood: 'Cozy Study Cafe',
    imageUrls: const [
      'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=1200&q=85',
      'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=1200&q=85',
    ],
    rating: 4.5,
    reviewCount: 279,
    popularity: 81,
    trendingScore: 83,
    latitude: 28.4684,
    longitude: 77.0819,
    openUntil: '11:00 PM',
    menu: menuFor('another-fine-day-galleria'),
  ),
  Bakery(
    id: 'greenr-cafe-galleria',
    name: 'Greenr Cafe Galleria',
    description:
        'Plant-forward cafe with coffee blends, bowls, and healthy dessert options.',
    address: 'Galleria Market, Gurugram',
    category: 'Coffee',
    mood: 'Date Spot',
    imageUrls: const [
      'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=1200&q=85',
      'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=1200&q=85',
    ],
    rating: 4.4,
    reviewCount: 244,
    popularity: 78,
    trendingScore: 82,
    latitude: 28.4683,
    longitude: 77.0816,
    openUntil: '11:00 PM',
    menu: menuFor('greenr-cafe-galleria'),
  ),
  Bakery(
    id: 'hamoni-cafe-sector-23',
    name: 'Hamoni Cafe Sector 23',
    description:
        'Leisure cafe with broad menus, coffee staples, and roomy outdoor seating.',
    address: 'Sector 23A, Gurugram',
    category: 'Coffee',
    mood: 'Family Bakery',
    imageUrls: const [
      'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=1200&q=85',
      'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=1200&q=85',
    ],
    rating: 4.3,
    reviewCount: 331,
    popularity: 80,
    trendingScore: 78,
    latitude: 28.5139,
    longitude: 77.0229,
    openUntil: '11:30 PM',
    menu: menuFor('hamoni-cafe-sector-23'),
  ),
  Bakery(
    id: 'roots-cafe-sector-29',
    name: 'Roots Cafe Sector 29',
    description:
        'Lively cafe with coffee, bakery sides, and a social evening vibe.',
    address: 'Sector 29, Gurugram',
    category: 'Coffee',
    mood: 'Late Night Coffee',
    imageUrls: const [
      'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=1200&q=85',
      'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=1200&q=85',
    ],
    rating: 4.2,
    reviewCount: 289,
    popularity: 77,
    trendingScore: 76,
    latitude: 28.4677,
    longitude: 77.0644,
    openUntil: '12:00 AM',
    menu: menuFor('roots-cafe-sector-29'),
  ),
  Bakery(
    id: 'fig-at-museo-sector-43',
    name: 'Fig at Museo Sector 43',
    description:
        'A polished cafe known for specialty coffee, desserts, and intimate seating.',
    address: 'Sector 43, Gurugram',
    category: 'Coffee',
    mood: 'Date Spot',
    imageUrls: const [
      'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=1200&q=85',
      'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=1200&q=85',
    ],
    rating: 4.6,
    reviewCount: 205,
    popularity: 79,
    trendingScore: 84,
    latitude: 28.4527,
    longitude: 77.0913,
    openUntil: '11:30 PM',
    menu: menuFor('fig-at-museo-sector-43'),
  ),
  Bakery(
    id: 'comorin-two-horizon',
    name: 'Comorin Two Horizon',
    description:
        'Contemporary cafe-dining spot with coffee programs and creative dessert plates.',
    address: 'Two Horizon Center, Golf Course Road, Gurugram',
    category: 'Coffee',
    mood: 'Date Spot',
    imageUrls: const [
      'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=1200&q=85',
      'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=1200&q=85',
    ],
    rating: 4.6,
    reviewCount: 347,
    popularity: 86,
    trendingScore: 88,
    latitude: 28.4376,
    longitude: 77.1051,
    openUntil: '11:30 PM',
    menu: menuFor('comorin-two-horizon'),
  ),
];
