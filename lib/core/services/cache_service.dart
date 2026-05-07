import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const _favoriteIdsKey = 'favorite_bakery_ids';
  static const _cachedBakeriesKey = 'cached_bakeries';
  static const _visitedCategoriesKey = 'visited_categories';
  static const _recentlyViewedKey = 'recently_viewed';
  static const _recentSearchesKey = 'recent_searches';
  static const _rememberLoginKey = 'remember_login';

  Future<void> saveFavoriteIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoriteIdsKey, ids);
  }

  Future<List<String>> favoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoriteIdsKey) ?? [];
  }

  Future<void> cacheBakeries(List<Map<String, dynamic>> bakeries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedBakeriesKey, jsonEncode(bakeries));
  }

  Future<List<Map<String, dynamic>>> cachedBakeries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedBakeriesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<Map<String, int>> visitedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_visitedCategoriesKey);
    if (raw == null) return {};
    return Map<String, int>.from(jsonDecode(raw));
  }

  Future<void> bumpCategory(String category) async {
    final counts = await visitedCategories();
    counts[category] = (counts[category] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_visitedCategoriesKey, jsonEncode(counts));
  }

  Future<List<String>> recentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentlyViewedKey) ?? [];
  }

  Future<void> addRecentlyViewed(String bakeryId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await recentlyViewed();
    ids.remove(bakeryId);
    ids.insert(0, bakeryId);
    await prefs.setStringList(_recentlyViewedKey, ids.take(6).toList());
  }

  Future<List<String>> recentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentSearchesKey) ?? [];
  }

  Future<void> addRecentSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) return;
    final prefs = await SharedPreferences.getInstance();
    final searches = await recentSearches();
    searches.removeWhere((item) => item.toLowerCase() == cleanQuery.toLowerCase());
    searches.insert(0, cleanQuery);
    await prefs.setStringList(_recentSearchesKey, searches.take(8).toList());
  }

  Future<void> setRememberLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberLoginKey, value);
  }

  Future<bool> rememberLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberLoginKey) ?? false;
  }
}
