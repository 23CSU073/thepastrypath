import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../../data/models/open_street_map_place.dart';

class OpenStreetMapPlaceSearchException implements Exception {
  OpenStreetMapPlaceSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OpenStreetMapPlaceSearchService {
  OpenStreetMapPlaceSearchService({http.Client? client})
      : _client = client ?? http.Client();

  static const _nominatimBaseUri = 'https://nominatim.openstreetmap.org/search';
  static const _photonBaseUri = 'https://photon.komoot.io/api';
  static const _minGap = Duration(seconds: 1);
  static const _normalizedRadiusKm = 25.0;

  final http.Client _client;
  DateTime? _lastNominatimSearchTime;

  Future<List<OpenStreetMapPlace>> search({
    required String query,
    double? latitude,
    double? longitude,
    int limit = 20,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return const [];
    final effectiveLatitude = latitude ?? AppConstants.gurugramLatitude;
    final effectiveLongitude = longitude ?? AppConstants.gurugramLongitude;

    final safeLimit = limit.clamp(1, 25);
    final collected = <OpenStreetMapPlace>[];
    Object? photonError;
    Object? nominatimError;

    try {
      final photonResults = await _searchPhoton(
        query: normalizedQuery,
        latitude: effectiveLatitude,
        longitude: effectiveLongitude,
        limit: safeLimit,
      );
      collected.addAll(photonResults);
    } catch (error) {
      photonError = error;
    }

    try {
      final nominatimResults = await _searchNominatim(
        query: normalizedQuery,
        latitude: effectiveLatitude,
        longitude: effectiveLongitude,
        limit: safeLimit,
      );
      collected.addAll(nominatimResults);
    } catch (error) {
      nominatimError = error;
    }

    final merged = _dedupeAndLimit(collected, safeLimit);
    if (merged.isNotEmpty) return merged;

    if (photonError != null && nominatimError != null) {
      throw OpenStreetMapPlaceSearchException(
        'Could not reach map search services right now.',
      );
    }

    return const [];
  }

  Future<List<OpenStreetMapPlace>> _searchPhoton({
    required String query,
    required double latitude,
    required double longitude,
    required int limit,
  }) async {
    final bbox = _bboxFor(
      latitude: latitude,
      longitude: longitude,
      radiusKm: _normalizedRadiusKm,
    );
    final params = <String, String>{
      'q': query,
      'lang': 'en',
      'limit': '$limit',
      'lat': latitude.toStringAsFixed(6),
      'lon': longitude.toStringAsFixed(6),
      'bbox': bbox,
    };

    final uri = Uri.parse(_photonBaseUri).replace(queryParameters: params);
    final response = await _client.get(uri, headers: const {
      'Accept': 'application/json',
    });
    if (response.statusCode != 200) {
      throw OpenStreetMapPlaceSearchException(
        'Photon search failed (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw OpenStreetMapPlaceSearchException(
        'Unexpected Photon response format.',
      );
    }

    final features = decoded['features'];
    if (features is! List) return const [];

    return features
        .whereType<Map<String, dynamic>>()
        .map(OpenStreetMapPlace.fromPhoton)
        .where((place) => place.latitude != 0 || place.longitude != 0)
        .toList(growable: false);
  }

  Future<List<OpenStreetMapPlace>> _searchNominatim({
    required String query,
    required double latitude,
    required double longitude,
    required int limit,
  }) async {
    await _respectNominatimRateLimit();

    final params = <String, String>{
      'q': query,
      'format': 'jsonv2',
      'addressdetails': '1',
      'namedetails': '1',
      'dedupe': '1',
      'limit': '$limit',
      'viewbox': _viewBoxFor(
        latitude: latitude,
        longitude: longitude,
        radiusKm: _normalizedRadiusKm,
      ),
      'bounded': '1',
    };

    final uri = Uri.parse(_nominatimBaseUri).replace(queryParameters: params);
    final response = await _client.get(uri, headers: {
      'Accept': 'application/json',
      'Accept-Language': 'en',
      if (!kIsWeb) 'User-Agent': 'ThePastryPath/1.0 (Flutter app)',
    });

    if (response.statusCode != 200) {
      throw OpenStreetMapPlaceSearchException(
        'Nominatim search failed (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw OpenStreetMapPlaceSearchException(
        'Unexpected Nominatim response format.',
      );
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(OpenStreetMapPlace.fromNominatim)
        .where((place) => place.latitude != 0 || place.longitude != 0)
        .toList(growable: false);
  }

  Future<void> _respectNominatimRateLimit() async {
    final now = DateTime.now();
    final last = _lastNominatimSearchTime;
    if (last != null) {
      final elapsed = now.difference(last);
      if (elapsed < _minGap) {
        await Future<void>.delayed(_minGap - elapsed);
      }
    }
    _lastNominatimSearchTime = DateTime.now();
  }

  List<OpenStreetMapPlace> _dedupeAndLimit(
    List<OpenStreetMapPlace> places,
    int limit,
  ) {
    final seen = <String>{};
    final merged = <OpenStreetMapPlace>[];
    for (final place in places) {
      final key =
          '${_normalize(place.name)}_${place.latitude.toStringAsFixed(4)}_${place.longitude.toStringAsFixed(4)}';
      if (!seen.add(key)) continue;
      merged.add(place);
      if (merged.length >= limit) break;
    }
    return merged;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _viewBoxFor({
    required double latitude,
    required double longitude,
    double radiusKm = 15,
  }) {
    final bbox = _bboxFor(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    ).split(',');
    final minLon = bbox[0];
    final minLat = bbox[1];
    final maxLon = bbox[2];
    final maxLat = bbox[3];
    return '$minLon,$maxLat,$maxLon,$minLat';
  }

  String _bboxFor({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    final latDelta = radiusKm / 111.0;
    final cosLat = math.cos(latitude * math.pi / 180).abs().clamp(0.2, 1.0);
    final lonDelta = radiusKm / (111.0 * cosLat);

    final minLat = latitude - latDelta;
    final maxLat = latitude + latDelta;
    final minLon = longitude - lonDelta;
    final maxLon = longitude + lonDelta;

    return '${minLon.toStringAsFixed(6)},${minLat.toStringAsFixed(6)},${maxLon.toStringAsFixed(6)},${maxLat.toStringAsFixed(6)}';
  }

  void dispose() {
    _client.close();
  }
}
