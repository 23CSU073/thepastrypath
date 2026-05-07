import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/bakery.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bakery_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/recommendation_provider.dart';
import '../../widgets/animated_search_bar.dart';
import '../../widgets/bakery_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/offer_banner.dart';
import '../../widgets/skeleton_loader.dart';
import '../bakery_details/bakery_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(BuildContext context) async {
    await context.read<BakeryProvider>().load();
    if (!context.mounted) return;
    await context.read<RecommendationProvider>().compute(
          bakeries: context.read<BakeryProvider>().bakeries,
          favoriteIds: context.read<FavoritesProvider>().favoriteIds,
        );
  }

  void _openDetails(BuildContext context, Bakery bakery) {
    context.read<BakeryProvider>().markViewed(bakery);
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: BakeryDetailsScreen(bakery: bakery)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().user;
    final bakeryProvider = context.watch<BakeryProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final recommendations = context.watch<RecommendationProvider>();
    final isSearching = bakeryProvider.searchQuery.trim().isNotEmpty;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(22, MediaQuery.paddingOf(context).top + 22, 22, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.cream, AppColors.blush],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hi ${user?.email?.split('@').first ?? 'friend'}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Find your next warm table',
                      style: TextStyle(
                        fontSize: 30,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    AnimatedSearchBar(onChanged: bakeryProvider.setSearch),
                  ],
                ),
              ),
            ),
            if (bakeryProvider.isLoading)
              const SliverPadding(
                padding: EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(child: SkeletonLoader(height: 320)),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(child: _Chips(provider: bakeryProvider)),
              ),
              if (!isSearching) ...[
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
                  sliver: SliverToBoxAdapter(child: OfferBanner()),
                ),
                SliverToBoxAdapter(
                  child: _HorizontalSection(
                    title: 'Featured nearby',
                    bakeries: bakeryProvider.featured,
                    favorites: favorites,
                    onTap: (bakery) => _openDetails(context, bakery),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SmartSuggestion(text: recommendations.smartSuggestion),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _HorizontalSection(
                    title: 'Personalized picks',
                    bakeries: recommendations.recommendations,
                    favorites: favorites,
                    onTap: (bakery) => _openDetails(context, bakery),
                  ),
                ),
                if (bakeryProvider.recentlyViewed.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _HorizontalSection(
                      title: 'Recently viewed',
                      bakeries: bakeryProvider.recentlyViewed,
                      favorites: favorites,
                      onTap: (bakery) => _openDetails(context, bakery),
                    ),
                  ),
              ],
              if (isSearching)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      '${bakeryProvider.filtered.length} result${bakeryProvider.filtered.length == 1 ? '' : 's'} for "${bakeryProvider.searchQuery.trim()}"',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
                sliver: bakeryProvider.filtered.isEmpty
                    ? const SliverToBoxAdapter(child: EmptyState(title: 'No bakeries match', message: 'Try another category, mood, or search term.'))
                    : SliverList.separated(
                        itemCount: bakeryProvider.filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final bakery = bakeryProvider.filtered[index];
                          return BakeryCard(
                            bakery: bakery,
                            compact: true,
                            isFavorite: favorites.isFavorite(bakery.id),
                            onFavorite: () async {
                              await favorites.toggle(context.read<AppAuthProvider>().user?.uid, bakery.id);
                              if (context.mounted) {
                                await context.read<RecommendationProvider>().compute(
                                      bakeries: context.read<BakeryProvider>().bakeries,
                                      favoriteIds: favorites.favoriteIds,
                                    );
                              }
                            },
                            onTap: () => _openDetails(context, bakery),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.provider});

  final BakeryProvider provider;

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...AppConstants.categories];
    final moods = ['All', ...AppConstants.moods];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: provider.selectedCategory == category,
                  onSelected: (_) => provider.setCategory(category),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: moods.map((mood) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(mood),
                  selected: provider.selectedMood == mood,
                  onSelected: (_) => provider.setMood(mood),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _HorizontalSection extends StatelessWidget {
  const _HorizontalSection({required this.title, required this.bakeries, required this.favorites, required this.onTap});

  final String title;
  final List<Bakery> bakeries;
  final FavoritesProvider favorites;
  final ValueChanged<Bakery> onTap;

  @override
  Widget build(BuildContext context) {
    if (bakeries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 330,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: bakeries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final bakery = bakeries[index];
                return BakeryCard(
                  bakery: bakery,
                  isFavorite: favorites.isFavorite(bakery.id),
                  onFavorite: () => favorites.toggle(context.read<AppAuthProvider>().user?.uid, bakery.id),
                  onTap: () => onTap(bakery),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartSuggestion extends StatelessWidget {
  const _SmartSuggestion({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.espresso))),
        ],
      ),
    );
  }
}
