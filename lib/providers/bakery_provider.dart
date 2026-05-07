import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/services/cache_service.dart';
import '../core/services/location_service.dart';
import '../core/utils/distance_utils.dart';
import '../data/models/bakery.dart';
import '../data/repositories/bakery_repository.dart';

class BakeryProvider extends ChangeNotifier {
  BakeryProvider({
    BakeryRepository? repository,
    LocationService? locationService,
    CacheService? cacheService,
  })  : _repository = repository ?? BakeryRepository(),
        _locationService = locationService ?? LocationService(),
        _cache = cacheService ?? CacheService();

  final BakeryRepository _repository;
  final LocationService _locationService;
  final CacheService _cache;

  List<Bakery> bakeries = [];
  List<String> recentlyViewedIds = [];
  List<String> recentSearches = [];
  Position? userPosition;
  String searchQuery = '';
  String selectedCategory = 'All';
  String selectedMood = 'All';
  bool isLoading = false;
  String? errorMessage;

  List<Bakery> get featured => bakeries.where((b) => b.rating >= 4.7).take(5).toList();

  List<Bakery> get trending {
    final data = [...bakeries]..sort((a, b) => b.trendingScore.compareTo(a.trendingScore));
    return data.take(5).toList();
  }

  List<Bakery> get recentlyViewed {
    return recentlyViewedIds
        .map(_findById)
        .whereType<Bakery>()
        .toList();
  }

  List<Bakery> get filtered {
    final normalizedQuery = _normalize(searchQuery);
    final queryWords = normalizedQuery.split(' ').where((word) => word.isNotEmpty).toList();
    return bakeries.where((bakery) {
      final searchable = _normalize([
        bakery.name,
        bakery.description,
        bakery.address,
        bakery.category,
        bakery.mood,
        ...bakery.menu.map((item) => '${item.name} ${item.category}'),
      ].join(' '));
      final queryMatch = normalizedQuery.isEmpty ||
          searchable.contains(normalizedQuery) ||
          queryWords.every(searchable.contains);
      final categoryMatch = selectedCategory == 'All' || bakery.category == selectedCategory;
      final moodMatch = selectedMood == 'All' || bakery.mood == selectedMood;
      return queryMatch && categoryMatch && moodMatch;
    }).toList();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      userPosition = await _locationService.currentPosition();
      final data = await _repository.fetchBakeries();
      bakeries = data.map(_withDistance).toList();
      recentlyViewedIds = await _cache.recentlyViewed();
      recentSearches = await _cache.recentSearches();
    } catch (_) {
      errorMessage = 'Could not refresh bakery data. Showing cached picks.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSearch(String value) async {
    searchQuery = value;
    if (value.trim().length >= 2) {
      await _cache.addRecentSearch(value);
      recentSearches = await _cache.recentSearches();
    }
    notifyListeners();
  }

  Future<void> setCategory(String value) async {
    selectedCategory = value;
    if (value != 'All') await _cache.bumpCategory(value);
    notifyListeners();
  }

  void setMood(String value) {
    selectedMood = value;
    notifyListeners();
  }

  Future<void> markViewed(Bakery bakery) async {
    await _cache.addRecentlyViewed(bakery.id);
    await _cache.bumpCategory(bakery.category);
    recentlyViewedIds = await _cache.recentlyViewed();
    notifyListeners();
  }

  Bakery _withDistance(Bakery bakery) {
    final position = userPosition;
    if (position == null) return bakery;
    return bakery.copyWith(
      distanceKm: DistanceUtils.kilometersBetween(
        fromLat: position.latitude,
        fromLng: position.longitude,
        toLat: bakery.latitude,
        toLng: bakery.longitude,
      ),
    );
  }

  Bakery? _findById(String id) {
    for (final bakery in bakeries) {
      if (bakery.id == id) return bakery;
    }
    return null;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
