import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/cache_service.dart';

class FavoritesRepository {
  FavoritesRepository({FirebaseFirestore? firestore, CacheService? cacheService})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _cache = cacheService ?? CacheService();

  final FirebaseFirestore _firestore;
  final CacheService _cache;

  Future<List<String>> fetchFavoriteIds(String? userId) async {
    final cached = await _cache.favoriteIds();
    if (userId == null) return cached;
    try {
      final snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();
      final ids = snapshot.docs.map((doc) => doc.data()['bakeryId'] as String).toList();
      await _cache.saveFavoriteIds(ids);
      return ids;
    } catch (_) {
      return cached;
    }
  }

  Future<void> toggleFavorite({
    required String? userId,
    required String bakeryId,
    required bool favorite,
  }) async {
    final ids = await _cache.favoriteIds();
    favorite ? ids.add(bakeryId) : ids.remove(bakeryId);
    await _cache.saveFavoriteIds(ids.toSet().toList());
    if (userId == null) return;

    final query = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('bakeryId', isEqualTo: bakeryId)
        .get();
    if (favorite && query.docs.isEmpty) {
      await _firestore.collection('favorites').add({
        'userId': userId,
        'bakeryId': bakeryId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    if (!favorite) {
      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    }
  }
}
