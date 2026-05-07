import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/open_street_map_place_search_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/bakery.dart';
import '../../data/models/open_street_map_place.dart';
import '../../providers/bakery_provider.dart';
import '../bakery_details/bakery_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  late final OpenStreetMapPlaceSearchService _placesService;

  Bakery? _selectedBakery;
  OpenStreetMapPlace? _selectedPlace;

  String _mapQuery = '';
  bool _isSearchingPlaces = false;
  String? _placesError;
  List<OpenStreetMapPlace> _placesResults = const [];

  @override
  void initState() {
    super.initState();
    _placesService = OpenStreetMapPlaceSearchService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _placesService.dispose();
    super.dispose();
  }

  void _openDetails(Bakery bakery) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BakeryDetailsScreen(bakery: bakery)),
    );
  }

  Future<void> _openPlaceInOpenStreetMap(OpenStreetMapPlace place) async {
    final uri = Uri.parse(place.openStreetMapUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _moveCamera({
    required LatLng center,
    required double zoom,
    Bakery? bakery,
    OpenStreetMapPlace? place,
  }) {
    setState(() {
      _selectedBakery = bakery;
      _selectedPlace = place;
    });

    try {
      _mapController.move(center, zoom);
    } catch (_) {
      // Map controller can throw before initial render on slower devices.
    }
  }

  Future<void> _focusOnPlace(OpenStreetMapPlace place) async {
    _moveCamera(
      center: LatLng(place.latitude, place.longitude),
      zoom: 14.8,
      place: place,
    );
  }

  Future<void> _focusOnBakery(Bakery bakery) async {
    _moveCamera(
      center: LatLng(bakery.latitude, bakery.longitude),
      zoom: 14.2,
      bakery: bakery,
    );
  }

  Future<void> _focusOnCenter(LatLng target) async {
    _moveCamera(center: target, zoom: 12);
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

    setState(() {
      _isSearchingPlaces = true;
      _placesError = null;
      _selectedBakery = null;
    });

    try {
      final position = provider.userPosition;
      final results = await _placesService.search(
        query: query,
        latitude: position?.latitude,
        longitude: position?.longitude,
        limit: 20,
      );

      if (!mounted) return;
      setState(() {
        _placesResults = results;
        _placesError = results.isEmpty ? 'No places found for "$query".' : null;
      });

      if (results.isNotEmpty) {
        await _focusOnPlace(results.first);
      }
    } on OpenStreetMapPlaceSearchException catch (error) {
      if (!mounted) return;
      setState(() {
        _placesError = error.message;
        _placesResults = const [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _placesError = 'Could not search OpenStreetMap places right now.';
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
        ? const LatLng(
            AppConstants.gurugramLatitude,
            AppConstants.gurugramLongitude,
          )
        : LatLng(
            provider.userPosition!.latitude,
            provider.userPosition!.longitude,
          );

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
      final isSelected = selectedBakery?.id == bakery.id;
      return Marker(
        point: LatLng(bakery.latitude, bakery.longitude),
        width: 46,
        height: 46,
        child: _MapMarker(
          icon: Icons.bakery_dining_rounded,
          color: AppColors.warmBrown,
          isSelected: isSelected,
          onTap: () => _focusOnBakery(bakery),
        ),
      );
    });

    final placeMarkers = _placesResults.map((place) {
      final isSelected = selectedPlace?.id == place.id;
      return Marker(
        point: LatLng(place.latitude, place.longitude),
        width: 46,
        height: 46,
        child: _MapMarker(
          icon: Icons.place_rounded,
          color: Colors.blue.shade700,
          isSelected: isSelected,
          onTap: () => _focusOnPlace(place),
        ),
      );
    });

    final userMarker = provider.userPosition == null
        ? const <Marker>[]
        : <Marker>[
            Marker(
              point: LatLng(
                provider.userPosition!.latitude,
                provider.userPosition!.longitude,
              ),
              width: 24,
              height: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ];

    final allMarkers = <Marker>[
      ...localMarkers,
      ...placeMarkers,
      ...userMarker,
    ];
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
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: target,
                          initialZoom: 12,
                          onTap: (tapPosition, point) => setState(() {
                            _selectedBakery = null;
                            _selectedPlace = null;
                          }),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.example.thepastrypath',
                            maxNativeZoom: 19,
                          ),
                          MarkerLayer(markers: allMarkers),
                          RichAttributionWidget(
                            attributions: [
                              TextSourceAttribution(
                                'OpenStreetMap contributors',
                                onTap: () => launchUrl(
                                  Uri.parse(
                                    'https://www.openstreetmap.org/copyright',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
                            child: _OpenStreetMapPlacePreview(
                              place: selectedPlace,
                              onOpenMaps: () =>
                                  _openPlaceInOpenStreetMap(selectedPlace),
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
        hintText: 'Search any cafe/place on OpenStreetMap',
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
                    tooltip: 'Search on OpenStreetMap',
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
  final List<OpenStreetMapPlace> places;
  final String? selectedId;
  final ValueChanged<OpenStreetMapPlace> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (isLoading) {
      content = const Text(
        'Searching OpenStreetMap places...',
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
            return ChoiceChip(
              label: Text(
                place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
            'OpenStreetMap search: "$query"',
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

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: isSelected ? 2.4 : 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: isSelected ? 24 : 22),
      ),
    );
  }
}

class _OpenStreetMapPlacePreview extends StatelessWidget {
  const _OpenStreetMapPlacePreview({
    required this.place,
    required this.onOpenMaps,
  });

  final OpenStreetMapPlace place;
  final VoidCallback onOpenMaps;

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
            child: const Icon(Icons.place_rounded, color: AppColors.warmBrown),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                Text(place.subtitle, style: const TextStyle(color: AppColors.muted)),
                if (place.category != null)
                  Text(
                    place.category!,
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
