import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/models/bakery.dart';
import 'favorite_button.dart';
import 'rating_badge.dart';

class BakeryCard extends StatelessWidget {
  const BakeryCard({
    super.key,
    required this.bakery,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
    this.heroPrefix = 'bakery',
    this.compact = false,
  });

  final Bakery bakery;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final String heroPrefix;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        width: compact ? 260 : 310,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.espresso.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: '$heroPrefix-${bakery.id}',
                  child: CachedNetworkImage(
                    imageUrl: bakery.imageUrls.first,
                    height: compact ? 132 : 168,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.cream),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.cream,
                      child: const Icon(Icons.bakery_dining, color: AppColors.warmBrown, size: 44),
                    ),
                  ),
                ),
                Positioned(top: 12, left: 12, child: RatingBadge(rating: bakery.rating)),
                Positioned(top: 10, right: 10, child: FavoriteButton(isFavorite: isFavorite, onTap: onFavorite)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bakery.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bakery.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, height: 1.25),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, size: 16, color: AppColors.warmBrown),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          bakery.distanceKm == null ? bakery.address : '${bakery.distanceKm!.toStringAsFixed(1)} km away',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.warmBrown),
                        ),
                      ),
                      Text(bakery.openUntil, style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
