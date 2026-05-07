import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class OfferBanner extends StatelessWidget {
  const OfferBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.espresso, AppColors.warmBrown, AppColors.orange]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmBrown.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: const Icon(Icons.local_offer_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Bakery Deal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                SizedBox(height: 3),
                Text('Free mocha upgrade on reservations after 6 PM.', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
