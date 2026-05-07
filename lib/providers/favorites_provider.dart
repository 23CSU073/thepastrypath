import 'package:flutter/material.dart';

import '../data/models/bakery.dart';
import '../data/repositories/favorites_repository.dart';

class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider({FavoritesRepository? repository}) : _repository = repository ?? FavoritesRepository();

  final FavoritesRepository _repository;
  final Set<String> _favoriteIds = {};
  bool isLoading = false;

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  bool isFavorite(String bakeryId) => _favoriteIds.contains(bakeryId);

  List<Bakery> favoritesFrom(List<Bakery> bakeries) {
    return bakeries.where((bakery) => _favoriteIds.contains(bakery.id)).toList();
  }

  Future<void> load(String? userId) async {
    isLoading = true;
    notifyListeners();
    final ids = await _repository.fetchFavoriteIds(userId);
    _favoriteIds
      ..clear()
      ..addAll(ids);
    isLoading = false;
    notifyListeners();
  }

  Future<void> toggle(String? userId, String bakeryId) async {
    final favorite = !_favoriteIds.contains(bakeryId);
    favorite ? _favoriteIds.add(bakeryId) : _favoriteIds.remove(bakeryId);
    notifyListeners();
    await _repository.toggleFavorite(userId: userId, bakeryId: bakeryId, favorite: favorite);
  }
}
