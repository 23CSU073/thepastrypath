import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/services/cache_service.dart';
import '../data/repositories/auth_repository.dart';

class AppAuthProvider extends ChangeNotifier {
  AppAuthProvider({AuthRepository? repository, CacheService? cacheService})
      : _repository = repository ?? AuthRepository(),
        _cache = cacheService ?? CacheService();

  final AuthRepository _repository;
  final CacheService _cache;
  bool isLoading = false;
  String? errorMessage;
  bool rememberLogin = false;

  User? get user => _repository.currentUser;
  Stream<User?> get authStateChanges => _repository.authStateChanges();

  Future<void> loadRememberLogin() async {
    rememberLogin = await _cache.rememberLogin();
    notifyListeners();
  }

  Future<bool> signIn(String email, String password, bool remember) async {
    return _runAuth(() async {
      await _repository.signIn(email.trim(), password);
      await _cache.setRememberLogin(remember);
      rememberLogin = remember;
    });
  }

  Future<bool> signUp(String email, String password, bool remember) async {
    return _runAuth(() async {
      await _repository.signUp(email.trim(), password);
      await _cache.setRememberLogin(remember);
      rememberLogin = remember;
    });
  }

  Future<void> signOut() async {
    await _repository.signOut();
    notifyListeners();
  }

  Future<bool> _runAuth(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (error) {
      errorMessage = error.message ?? 'Authentication failed.';
      return false;
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
