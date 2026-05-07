import 'package:flutter/material.dart';

import '../core/services/cache_service.dart';
import '../core/utils/distance_utils.dart';
import '../data/models/bakery.dart';

class RecommendationProvider extends ChangeNotifier {
  RecommendationProvider({CacheService? cacheService}) : _cache = cacheService ?? CacheService();

  final CacheService _cache;
  List<Bakery> recommendations = [];
  String smartSuggestion = 'Start exploring bakeries to unlock smarter suggestions.';

  Future<void> compute({
    required List<Bakery> bakeries,
    required Set<String> favoriteIds,
  }) async {
    final categoryVisits = await _cache.visitedCategories();
    recommendations = rankBakeries(
      bakeries: bakeries,
      favoriteIds: favoriteIds,
      categoryVisits: categoryVisits,
    ).take(5).toList();
    smartSuggestion = _buildSuggestion(recommendations, favoriteIds, categoryVisits);
    notifyListeners();
  }

  static List<Bakery> rankBakeries({
    required List<Bakery> bakeries,
    required Set<String> favoriteIds,
    required Map<String, int> categoryVisits,
  }) {
    final favoriteCategories = bakeries
        .where((bakery) => favoriteIds.contains(bakery.id))
        .map((bakery) => bakery.category)
        .toSet();
    final maxVisits = categoryVisits.values.fold<int>(1, (max, value) => value > max ? value : max);

    final scored = bakeries.map((bakery) {
      final ratingScore = bakery.rating / 5;
      final popularityScore = bakery.popularity / 100;
      final trendScore = bakery.trendingScore / 100;
      final preferenceScore = _preferenceScore(bakery, favoriteCategories, categoryVisits, maxVisits);
      final distanceScore = DistanceUtils.distanceWeight(bakery.distanceKm);

      final score = (ratingScore * 0.4) +
          (popularityScore * 0.2) +
          (trendScore * 0.1) +
          (preferenceScore * 0.2) +
          (distanceScore * 0.1);
      return MapEntry(bakery, score);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return scored.map((entry) => entry.key).toList();
  }

  static double _preferenceScore(
    Bakery bakery,
    Set<String> favoriteCategories,
    Map<String, int> categoryVisits,
    int maxVisits,
  ) {
    final favoriteBoost = favoriteCategories.contains(bakery.category) ? 0.6 : 0;
    final visitBoost = (categoryVisits[bakery.category] ?? 0) / maxVisits * 0.4;
    return (favoriteBoost + visitBoost).clamp(0, 1);
  }

  String _buildSuggestion(
    List<Bakery> ranked,
    Set<String> favoriteIds,
    Map<String, int> categoryVisits,
  ) {
    if (ranked.isEmpty) return 'No bakeries found yet. Pull to refresh when you are online.';
    final top = ranked.first;
    if (favoriteIds.isEmpty && categoryVisits.isEmpty) {
      return 'Popular near you: try ${top.name} for ${top.category.toLowerCase()} and ${top.mood.toLowerCase()} vibes.';
    }
    return 'Since you like ${top.category.toLowerCase()}, try ${top.name}; it balances rating, trend, and distance best.';
  }
}
