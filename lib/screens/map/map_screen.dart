import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_sdk_flutter/google_places_sdk_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/google_maps_web_bootstrap.dart';
import '../../data/models/bakery.dart';
import '../../providers/bakery_provider.dart';
import '../bakery_details/bakery_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: AppConstants.mapsApiKeyPlaceholder,
  );

  GoogleMapController? _controller;
  Bakery? _selectedBakery;
  PlaceData? _selectedPlace;
  final TextEditingController _searchController = TextEditingController();
  late final PlacesClient _placesClient;

  String _mapQuery = '';
  bool _isSearchingPlaces = false;
  String? _placesError;
  List<PlaceData> _placesResults = const [];

  @override
  void initState() {
    super.initState();
    _placesClient = PlacesClient(apiKey: _googleMapsApiKey);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _placesClient.close();
    _controller?.dispose();
    super.dispose();
  }

  void _openDetails(Bakery bakery) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BakeryDetailsScreen(bakery: bakery)),
    );
  }

  Future<void> _openPlaceInGoogleMaps(PlaceData place) async {
    final uriString =
        place.googleMapsUri ??
        _fallbackMapsUri(
          name: place.displayName?.text,
          coordinates: place.location,
        );
    final uri = Uri.parse(uriString);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _fallbackMapsUri({
    required String? name,
    required PlaceCoordinates? coordinates,
  }) {
    final query = (name ?? 'cafe').trim();
    if (coordinates == null) {
      return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
    }
    return 'https://www.google.com/maps/search/?api=1&query=${coordinates.latitude},${coordinates.longitude}';
  }

  Future<void> _focusOnPlace(PlaceData place) async {
    final location = place.location;
    if (location == null) return;
    setState(() {
      _selectedPlace = place;
      _selectedBakery = null;
    });

    final controller = _controller;
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(location.latitude, location.longitude),
          zoom: 14.8,
        ),
      ),
    );
  }

  Future<void> _focusOnCenter(LatLng target) async {
    final controller = _controller;
    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 12)),
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _mapQuery = value;
      _placesError = null;
      if (value.trim().isEmpty) {
        _placesResults = const [];
        _selectedPlace = null;
      }
    });
  }

  Future<void> _searchAnyPlace(BakeryProvider provider) async {
    final query = _mapQuery.trim();
    if (query.isEmpty) {
      setState(() {
        _placesResults = const [];
        _placesError = null;
        _selectedPlace = null;
      });
      return;
    }

    if (_googleMapsApiKey.trim().isEmpty ||
        _googleMapsApiKey.contains(AppConstants.mapsApiKeyPlaceholder)) {
      setState(() {
        _placesError =
            'Google Maps key is missing for place search. Add GOOGLE_MAPS_API_KEY.';
        _placesResults = const [];
      });
      return;
    }

    setState(() {
      _isSearchingPlaces = true;
      _placesError = null;
      _selectedBakery = null;
    });

    try {
      final position = provider.userPosition;
      final bias = position == null
          ? null
          : LocationBias.circle(
              center: PlaceCoordinates(
                latitude: position.latitude,
                longitude: position.longitude,
              ),
              radiusMeters: 15000,
            );

      final results = await _placesClient.searchText(
        TextSearchRequest(
          textQuery: query,
          fields: const {
            PlaceField.id,
            PlaceField.displayName,
            PlaceField.formattedAddress,
            PlaceField.location,
            PlaceField.googleMapsUri,
            PlaceField.rating,
            PlaceField.userRatingCount,
            PlaceField.primaryType,
            PlaceField.primaryTypeDisplayName,
          },
          locationBias: bias,
          maxResultCount: 20,
        ),
      );

      final placesWithLocation = results
          .where((place) => place.location != null)
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _placesResults = placesWithLocation;
        _placesError = placesWithLocation.isEmpty
            ? 'No places found for "$query".'
            : null;
      });

      if (placesWithLocation.isNotEmpty) {
        await _focusOnPlace(placesWithLocation.first);
      }
    } on PlacesException catch (error) {
      if (!mounted) return;
      setState(() {
        _placesError = error.message;
        _placesResults = const [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _placesError = 'Could not search Google Maps places right now.';
        _placesResults = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _isSearchingPlaces = false);
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _mapQuery = '';
      _placesResults = const [];
      _placesError = null;
      _selectedPlace = null;
    });
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<Bakery> _applyMapSearch(List<Bakery> bakeries, String query) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return bakeries;
    final queryWords = normalizedQuery
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();

    return bakeries.where((bakery) {
      final searchable = _normalize(
        [
          bakery.name,
          bakery.description,
          bakery.address,
          bakery.category,
          bakery.mood,
        ].join(' '),
      );
      return searchable.contains(normalizedQuery) ||
          queryWords.every(searchable.contains);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BakeryProvider>();
    final baseBakeries = provider.filtered.isEmpty
        ? provider.bakeries
        : provider.filtered;

    final isRemoteSearchMode = _mapQuery.trim().isNotEmpty;
    final visibleBakeries = isRemoteSearchMode
        ? const <Bakery>[]
        : _applyMapSearch(baseBakeries, _mapQuery);

    final target = provider.userPosition == null
        ? AppConstants.gurugramCenter
        : LatLng(
            provider.userPosition!.latitude,
            provider.userPosition!.longitude,
          );
    final isWebMapsUnavailable = kIsWeb && !hasGoogleMapsJsApi();
    final hasPlaceholderKey = kIsWeb && hasPlaceholderGoogleMapsKey();

    final selectedBakery =
        _selectedBakery != null &&
            visibleBakeries.any((bakery) => bakery.id == _selectedBakery!.id)
        ? _selectedBakery
        : null;

    final selectedPlace =
        _selectedPlace != null &&
            _placesResults.any((place) => place.id == _selectedPlace!.id)
        ? _selectedPlace
        : null;

    final localMarkers = visibleBakeries.map((bakery) {
      return Marker(
        markerId: MarkerId('local_${bakery.id}'),
        position: bakery.position,
        infoWindow: InfoWindow(
          title: bakery.name,
          snippet: bakery.distanceKm == null
              ? '${bakery.rating} stars'
              : '${bakery.rating} stars - ${bakery.distanceKm!.toStringAsFixed(1)} km away',
        ),
        onTap: () => setState(() {
          _selectedBakery = bakery;
          _selectedPlace = null;
        }),
      );
    });

    final placesMarkers = _placesResults
        .where((place) => place.location != null)
        .map((place) {
          final location = place.location!;
          return Marker(
            markerId: MarkerId('place_${place.id}'),
            position: LatLng(location.latitude, location.longitude),
            infoWindow: InfoWindow(
              title: place.displayName?.text ?? 'Place',
              snippet:
                  place.formattedAddress ??
                  place.primaryType ??
                  'Google Maps place',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            onTap: () => setState(() {
              _selectedPlace = place;
              _selectedBakery = null;
            }),
          );
        });

    final allMarkers = <Marker>{...localMarkers, ...placesMarkers};
    final hasPreview = selectedPlace != null || selectedBakery != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bakery Map'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _MapSearchField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSubmitted: (_) => _searchAnyPlace(provider),
              onSearchTap: () => _searchAnyPlace(provider),
              onClear: _clearSearch,
            ),
          ),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : isWebMapsUnavailable
          ? _WebMapsSetupError(hasPlaceholderKey: hasPlaceholderKey)
          : Column(
              children: [
                if (isRemoteSearchMode)
                  _PlaceResultStrip(
                    query: _mapQuery.trim(),
                    isLoading: _isSearchingPlaces,
                    errorMessage: _placesError,
                    places: _placesResults,
                    selectedId: selectedPlace?.id,
                    onSelect: _focusOnPlace,
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: target,
                          zoom: 12,
                        ),
                        myLocationEnabled: provider.userPosition != null,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: true,
                        markers: allMarkers,
                        onTap: (_) => setState(() {
                          _selectedBakery = null;
                          _selectedPlace = null;
                        }),
                        onMapCreated: (controller) => _controller = controller,
                      ),
                      Positioned(
                        right: 18,
                        bottom: hasPreview ? 130 : 24,
                        child: PointerInterceptor(
                          child: FloatingActionButton.small(
                            heroTag: 'recenter-map',
                            onPressed: () => _focusOnCenter(target),
                            child: const Icon(Icons.my_location_rounded),
                          ),
                        ),
                      ),
                      if (selectedPlace != null)
                        Positioned(
                          left: 18,
                          right: 18,
                          bottom: 22,
                          child: PointerInterceptor(
                            child: _GooglePlacePreview(
                              place: selectedPlace,
                              onOpenMaps: () =>
                                  _openPlaceInGoogleMaps(selectedPlace),
                            ),
                          ),
                        )
                      else if (selectedBakery != null)
                        Positioned(
                          left: 18,
                          right: 18,
                          bottom: 22,
                          child: PointerInterceptor(
                            child: _MapPreview(
                              bakery: selectedBakery,
                              onOpen: () => _openDetails(selectedBakery),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _MapSearchField extends StatelessWidget {
  const _MapSearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onSearchTap,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearchTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: 'Search any cafe/place on Google Maps',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onSearchTap,
                    icon: const Icon(Icons.travel_explore_rounded),
                    tooltip: 'Search on Google Maps',
                  ),
                  IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Clear search',
                  ),
                ],
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _PlaceResultStrip extends StatelessWidget {
  const _PlaceResultStrip({
    required this.query,
    required this.isLoading,
    required this.errorMessage,
    required this.places,
    required this.selectedId,
    required this.onSelect,
  });

  final String query;
  final bool isLoading;
  final String? errorMessage;
  final List<PlaceData> places;
  final String? selectedId;
  final ValueChanged<PlaceData> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (isLoading) {
      content = const Text(
        'Searching Google Maps places...',
        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
      );
    } else if (errorMessage != null) {
      content = Text(
        errorMessage!,
        style: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w700,
        ),
      );
    } else if (places.isEmpty) {
      content = const Text(
        'No matching places found.',
        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
      );
    } else {
      content = SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: places.length,
          separatorBuilder: (_, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final place = places[index];
            final name = place.displayName?.text ?? 'Place';
            return ChoiceChip(
              label: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
              selected: place.id == selectedId,
              onSelected: (_) => onSelect(place),
            );
          },
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      color: AppColors.cream.withValues(alpha: 0.32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Google Maps search: "$query"',
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          content,
        ],
      ),
    );
  }
}

class _WebMapsSetupError extends StatelessWidget {
  const _WebMapsSetupError({required this.hasPlaceholderKey});

  final bool hasPlaceholderKey;

  @override
  Widget build(BuildContext context) {
    final keyMessage = hasPlaceholderKey
        ? 'Replace YOUR_GOOGLE_MAPS_API_KEY in web/index.html with your real key.'
        : 'Check the web key in web/index.html and verify Maps JavaScript API is enabled.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.espresso.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.map_rounded, color: AppColors.warmBrown),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Google Maps JS failed to load',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                keyMessage,
                style: const TextStyle(
                  color: AppColors.espresso,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Make sure Maps JavaScript API and Places API (New) are enabled, and localhost is allowed in key restrictions.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GooglePlacePreview extends StatelessWidget {
  const _GooglePlacePreview({required this.place, required this.onOpenMaps});

  final PlaceData place;
  final VoidCallback onOpenMaps;

  @override
  Widget build(BuildContext context) {
    final placeName = place.displayName?.text ?? 'Google Maps place';
    final subtitle =
        place.formattedAddress ??
        place.primaryTypeDisplayName?.text ??
        place.primaryType ??
        'Open in Google Maps';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withValues(alpha: 0.2),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.place_rounded, color: AppColors.warmBrown),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  placeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                Text(subtitle, style: const TextStyle(color: AppColors.muted)),
                if (place.rating != null)
                  Text(
                    '${place.rating!.toStringAsFixed(1)} stars${place.userRatingCount == null ? '' : ' (${place.userRatingCount})'}',
                    style: const TextStyle(
                      color: AppColors.espresso,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: onOpenMaps,
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.bakery, required this.onOpen});

  final Bakery bakery;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withValues(alpha: 0.2),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bakery_dining_rounded,
              color: AppColors.warmBrown,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bakery.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                Text(
                  bakery.distanceKm == null
                      ? bakery.address
                      : '${bakery.distanceKm!.toStringAsFixed(1)} km away',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: onOpen,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}
