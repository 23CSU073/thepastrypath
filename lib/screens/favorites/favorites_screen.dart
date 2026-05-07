import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/bakery_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/bakery_card.dart';
import '../../widgets/empty_state.dart';
import '../bakery_details/bakery_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bakeries = context.watch<BakeryProvider>().bakeries;
    final favorites = context.watch<FavoritesProvider>();
    final saved = favorites.favoritesFrom(bakeries);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Bakeries')),
      body: saved.isEmpty
          ? const EmptyState(title: 'No favorites yet', message: 'Tap the heart on a bakery card and it will stay available offline.')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              itemCount: saved.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final bakery = saved[index];
                return BakeryCard(
                  bakery: bakery,
                  compact: true,
                  isFavorite: true,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BakeryDetailsScreen(bakery: bakery))),
                  onFavorite: () => favorites.toggle(context.read<AppAuthProvider>().user?.uid, bakery.id),
                );
              },
            ),
    );
  }
}
