import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../models/grok_place.dart';

class GrokApiKeyMissingException implements Exception {
  const GrokApiKeyMissingException();

  @override
  String toString() =>
      'Missing Groq API key. Set GROQ_API_KEY or provide a bundled fallback key.';
}

class GrokRequestException implements Exception {
  const GrokRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GrokRepository {
  GrokRepository({http.Client? client}) : _client = client ?? http.Client();

  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = String.fromEnvironment(
    'GROQ_MODEL',
    defaultValue: 'llama-3.3-70b-versatile',
  );
  static const String _apiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: AppConstants.groqApiKey,
  );

  final http.Client _client;

  Future<List<GrokPlace>> suggestCoffeePlaces({
    required String prompt,
    double? latitude,
    double? longitude,
  }) async {
    final apiKey = _apiKey.trim();
    if (apiKey.isEmpty) {
      throw const GrokApiKeyMissingException();
    }

    final locationContext = latitude == null || longitude == null
        ? 'User location is unavailable. Suggest places likely near the user based on the prompt.'
        : 'User location: latitude ${latitude.toStringAsFixed(5)}, longitude ${longitude.toStringAsFixed(5)}. Prioritize close places.';

    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'stream': false,
        'temperature': 0.4,
        'messages': [
          {
            'role': 'system',
            'content':
                'You recommend nearby coffee shops and cafes. Return only valid JSON with this schema: {"places":[{"name":"", "area":"", "why":"", "maps_query":""}]}. Return 4 to 6 places. Keep why under 18 words. No markdown or extra keys.',
          },
          {'role': 'user', 'content': '$prompt\n$locationContext'},
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractApiErrorMessage(response.body);
      throw GrokRequestException(
        'Groq request failed (${response.statusCode}): $message',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractMessageContent(body);
    final places = _parsePlaces(content);

    if (places.isEmpty) {
      throw const GrokRequestException(
        'Groq did not return any place suggestions.',
      );
    }

    return places;
  }

  String _extractMessageContent(Map<String, dynamic> payload) {
    final choices = payload['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const GrokRequestException(
        'Groq response did not include choices.',
      );
    }

    final first = choices.first;
    if (first is! Map<String, dynamic>) {
      throw const GrokRequestException('Unexpected Groq choice format.');
    }

    final message = first['message'];
    if (message is! Map<String, dynamic>) {
      throw const GrokRequestException(
        'Groq response did not include a message.',
      );
    }

    final content = message['content'];
    if (content is String) return content;

    throw const GrokRequestException('Groq message content was not text.');
  }

  List<GrokPlace> _parsePlaces(String rawContent) {
    final cleaned = _cleanJson(rawContent);
    final decoded = jsonDecode(cleaned);

    if (decoded is Map<String, dynamic>) {
      final places = decoded['places'];
      if (places is List) {
        return places
            .whereType<Map<String, dynamic>>()
            .map(GrokPlace.fromMap)
            .where((item) => item.isValid)
            .toList();
      }
    }

    throw const GrokRequestException(
      'Groq returned data in an unexpected format.',
    );
  }

  String _cleanJson(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith('```')) return trimmed;

    final withoutFenceStart = trimmed.replaceFirst(
      RegExp(r'^```(?:json)?\s*', caseSensitive: false),
      '',
    );
    return withoutFenceStart.replaceFirst(RegExp(r'\s*```$'), '').trim();
  }

  String _extractApiErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final directError = decoded['error'];
        if (directError is String && directError.trim().isNotEmpty) {
          return directError.trim();
        }
        if (directError is Map<String, dynamic>) {
          final msg = directError['message'];
          if (msg is String && msg.trim().isNotEmpty) return msg.trim();
        }
      }
    } catch (_) {
      // Fall back to raw body when parsing fails.
    }
    return body;
  }
}
