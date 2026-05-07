import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/bakery.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bakery_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/grok_provider.dart';
import '../../providers/recommendation_provider.dart';
import '../../widgets/animated_search_bar.dart';
import '../../widgets/bakery_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/offer_banner.dart';
import '../../widgets/skeleton_loader.dart';
import '../bakery_details/bakery_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String _defaultGroqPrompt = 'Good cafes near me';

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
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: BakeryDetailsScreen(bakery: bakery),
        ),
      ),
    );
  }

  Future<void> _fetchGrokCoffeeSuggestions(
    BuildContext context,
    String prompt,
  ) async {
    final bakeryProvider = context.read<BakeryProvider>();
    final position = bakeryProvider.userPosition;
    final promptText = prompt.trim().isEmpty
        ? _defaultGroqPrompt
        : prompt.trim();
    await context.read<GrokProvider>().fetchCoffeeSuggestions(
      prompt: promptText,
      latitude: position?.latitude,
      longitude: position?.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().user;
    final bakeryProvider = context.watch<BakeryProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final grok = context.watch<GrokProvider>();
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
                padding: EdgeInsets.fromLTRB(
                  22,
                  MediaQuery.paddingOf(context).top + 22,
                  22,
                  20,
                ),
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
                sliver: SliverToBoxAdapter(
                  child: _Chips(provider: bakeryProvider),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _GrokCoffeeSection(
                    provider: grok,
                    onFetch: (prompt) =>
                        _fetchGrokCoffeeSuggestions(context, prompt),
                  ),
                ),
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
                    child: _SmartSuggestion(
                      text: recommendations.smartSuggestion,
                    ),
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
                    ? const SliverToBoxAdapter(
                        child: EmptyState(
                          title: 'No bakeries match',
                          message:
                              'Try another category, mood, or search term.',
                        ),
                      )
                    : SliverList.separated(
                        itemCount: bakeryProvider.filtered.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final bakery = bakeryProvider.filtered[index];
                          return BakeryCard(
                            bakery: bakery,
                            compact: true,
                            isFavorite: favorites.isFavorite(bakery.id),
                            onFavorite: () async {
                              await favorites.toggle(
                                context.read<AppAuthProvider>().user?.uid,
                                bakery.id,
                              );
                              if (context.mounted) {
                                await context
                                    .read<RecommendationProvider>()
                                    .compute(
                                      bakeries: context
                                          .read<BakeryProvider>()
                                          .bakeries,
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
  const _HorizontalSection({
    required this.title,
    required this.bakeries,
    required this.favorites,
    required this.onTap,
  });

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
            child: Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 330,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: bakeries.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final bakery = bakeries[index];
                return BakeryCard(
                  bakery: bakery,
                  isFavorite: favorites.isFavorite(bakery.id),
                  onFavorite: () => favorites.toggle(
                    context.read<AppAuthProvider>().user?.uid,
                    bakery.id,
                  ),
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
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.espresso,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrokCoffeeSection extends StatefulWidget {
  const _GrokCoffeeSection({required this.provider, required this.onFetch});

  final GrokProvider provider;
  final Future<void> Function(String prompt) onFetch;

  @override
  State<_GrokCoffeeSection> createState() => _GrokCoffeeSectionState();
}

class _GrokCoffeeSectionState extends State<_GrokCoffeeSection> {
  static const String _defaultPrompt = '';
  late final TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: _defaultPrompt);
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _submitPrompt() {
    return widget.onFetch(_promptController.text);
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.coffee_rounded, color: AppColors.warmBrown),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Ask Groq for nearby coffee',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              FilledButton.icon(
                onPressed: provider.isLoading ? null : _submitPrompt,
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: const Text('Find'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _promptController,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submitPrompt(),
            decoration: InputDecoration(
              hintText: 'Type a custom prompt for Groq...',
              filled: true,
              fillColor: AppColors.cream.withValues(alpha: 0.45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.edit_note_rounded),
            ),
          ),
          if (provider.lastPrompt.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Prompt: ${provider.lastPrompt}',
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              provider.errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (provider.places.isNotEmpty) ...[
            const SizedBox(height: 12),
            ListView.separated(
              itemCount: provider.places.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final place = provider.places[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cream.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (place.area.isNotEmpty)
                        Text(
                          place.area,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (place.why.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          place.why,
                          style: const TextStyle(
                            color: AppColors.espresso,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
