import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/bakery.dart';
import '../../providers/bakery_provider.dart';
import '../bakery_details/bakery_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  Bakery? _selected;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BakeryProvider>();
    final bakeries = provider.filtered.isEmpty
        ? provider.bakeries
        : provider.filtered;
    final target = provider.userPosition == null
        ? AppConstants.gurugramCenter
        : LatLng(
            provider.userPosition!.latitude,
            provider.userPosition!.longitude,
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Bakery Map')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                if (kIsWeb)
                  _BakeryMapFallback(
                    bakeries: bakeries,
                    selected: _selected,
                    onSelect: (bakery) => setState(() => _selected = bakery),
                  )
                else
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: target,
                      zoom: 12,
                    ),
                    myLocationEnabled: provider.userPosition != null,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: true,
                    markers: bakeries.map((bakery) {
                      return Marker(
                        markerId: MarkerId(bakery.id),
                        position: bakery.position,
                        infoWindow: InfoWindow(
                          title: bakery.name,
                          snippet: bakery.distanceKm == null
                              ? '${bakery.rating} stars'
                              : '${bakery.rating} stars - ${bakery.distanceKm!.toStringAsFixed(1)} km away',
                        ),
                        onTap: () => setState(() => _selected = bakery),
                      );
                    }).toSet(),
                    onMapCreated: (controller) => _controller = controller,
                  ),
                Positioned(
                  top: 18,
                  left: 18,
                  right: 18,
                  child: _MapHint(count: bakeries.length),
                ),
                if (_selected != null)
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 22,
                    child: _MapPreview(
                      bakery: _selected!,
                      onOpen: () => _openDetails(_selected!),
                    ),
                  ),
              ],
            ),
    );
  }

  void _openDetails(Bakery bakery) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BakeryDetailsScreen(bakery: bakery)),
    );
  }
}

class _BakeryMapFallback extends StatelessWidget {
  const _BakeryMapFallback({
    required this.bakeries,
    required this.selected,
    required this.onSelect,
  });

  final List<Bakery> bakeries;
  final Bakery? selected;
  final ValueChanged<Bakery> onSelect;

  @override
  Widget build(BuildContext context) {
    if (bakeries.isEmpty) {
      return const Center(child: Text('No bakeries to show on the map yet.'));
    }

    final minLat = bakeries
        .map((bakery) => bakery.latitude)
        .reduce((a, b) => a < b ? a : b);
    final maxLat = bakeries
        .map((bakery) => bakery.latitude)
        .reduce((a, b) => a > b ? a : b);
    final minLng = bakeries
        .map((bakery) => bakery.longitude)
        .reduce((a, b) => a < b ? a : b);
    final maxLng = bakeries
        .map((bakery) => bakery.longitude)
        .reduce((a, b) => a > b ? a : b);
    final latSpan = (maxLat - minLat).abs() < 0.001 ? 0.001 : maxLat - minLat;
    final lngSpan = (maxLng - minLng).abs() < 0.001 ? 0.001 : maxLng - minLng;

    return Container(
      color: const Color(0xFFE8EDF0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          const edgePadding = 58.0;
          final usableWidth = (width - edgePadding * 2).clamp(
            1.0,
            double.infinity,
          );
          final usableHeight = (height - edgePadding * 2).clamp(
            1.0,
            double.infinity,
          );

          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _MapGridPainter())),
              ...bakeries.map((bakery) {
                final left =
                    edgePadding +
                    ((bakery.longitude - minLng) / lngSpan) * usableWidth;
                final top =
                    edgePadding +
                    ((maxLat - bakery.latitude) / latSpan) * usableHeight;
                final isSelected = selected?.id == bakery.id;

                return Positioned(
                  left: left - 22,
                  top: top - 46,
                  child: Tooltip(
                    message: bakery.name,
                    child: GestureDetector(
                      onTap: () => onSelect(bakery),
                      child: AnimatedScale(
                        scale: isSelected ? 1.16 : 1,
                        duration: const Duration(milliseconds: 180),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.espresso
                                    : AppColors.warmBrown,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.espresso.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 14,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.bakery_dining_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: isSelected
                                  ? AppColors.espresso
                                  : AppColors.warmBrown,
                              size: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..strokeWidth = 2;
    const gap = 86.0;
    for (var x = -gap; x < size.width + gap; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.28, size.height),
        paint,
      );
    }
    for (var y = gap * 0.5; y < size.height + gap; y += gap) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y - size.width * 0.14),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapHint extends StatelessWidget {
  const _MapHint({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.espresso.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: AppColors.warmBrown),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count bakeries near Gurugram',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
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
