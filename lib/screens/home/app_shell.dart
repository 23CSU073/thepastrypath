import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bakery_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/recommendation_provider.dart';
import '../analytics/analytics_screen.dart';
import '../favorites/favorites_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AppAuthProvider>().user?.uid;
    await context.read<BakeryProvider>().load();
    if (!mounted) return;
    await context.read<FavoritesProvider>().load(userId);
    if (!mounted) return;
    await context.read<RecommendationProvider>().compute(
          bakeries: context.read<BakeryProvider>().bakeries,
          favoriteIds: context.read<FavoritesProvider>().favoriteIds,
        );
  }

  @override
  Widget build(BuildContext context) {
    final screens = const [HomeScreen(), MapScreen(), FavoritesScreen(), AnalyticsScreen(), ProfileScreen()];
    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: AppColors.espresso.withValues(alpha: 0.14), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          height: 62,
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.cream,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded), label: 'Map'),
            NavigationDestination(icon: Icon(Icons.favorite_border_rounded), selectedIcon: Icon(Icons.favorite_rounded), label: 'Saved'),
            NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Insights'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
