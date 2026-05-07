import 'package:flutter/material.dart';

import '../data/models/grok_place.dart';
import '../data/repositories/grok_repository.dart';

class GrokProvider extends ChangeNotifier {
  GrokProvider({GrokRepository? repository})
    : _repository = repository ?? GrokRepository();

  final GrokRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  List<GrokPlace> places = const [];
  String lastPrompt = '';

  Future<void> fetchCoffeeSuggestions({
    required String prompt,
    double? latitude,
    double? longitude,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await _repository.suggestCoffeePlaces(
        prompt: prompt,
        latitude: latitude,
        longitude: longitude,
      );
      places = results;
      lastPrompt = prompt;
    } on GrokApiKeyMissingException catch (error) {
      errorMessage = error.toString();
      places = const [];
    } on GrokRequestException catch (error) {
      errorMessage = error.message;
      places = const [];
    } catch (_) {
      errorMessage = 'Something went wrong while contacting Groq.';
      places = const [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    places = const [];
    errorMessage = null;
    lastPrompt = '';
    notifyListeners();
  }
}
