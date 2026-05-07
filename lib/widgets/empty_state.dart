import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message, this.icon = Icons.bakery_dining});

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 54, color: AppColors.warmBrown),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
