import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: isFavorite ? 1.12 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isFavorite ? AppColors.orange : Colors.white.withValues(alpha: 0.86),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.espresso.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? Colors.white : AppColors.warmBrown,
          ),
        ),
      ),
    );
  }
}
