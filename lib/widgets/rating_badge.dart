import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating, this.compact = false});

  final double rating;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 5 : 7),
      decoration: BoxDecoration(
        color: AppColors.espresso.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.orange, size: 16),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
