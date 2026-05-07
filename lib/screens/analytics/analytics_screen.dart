import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/bakery_provider.dart';
import '../../providers/favorites_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bakeries = context.watch<BakeryProvider>().bakeries;
    final favorites = context.watch<FavoritesProvider>().favoritesFrom(bakeries);
    final categoryCounts = {for (final category in AppConstants.categories) category: favorites.where((b) => b.category == category).length};
    final trending = [...bakeries]..sort((a, b) => b.trendingScore.compareTo(a.trendingScore));

    return Scaffold(
      appBar: AppBar(title: const Text('Bakery Insights')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          _InsightCard(
            title: 'Smart insight',
            child: const Text('You mostly prefer coffee cafes and pastry spots during relaxed evening windows.', style: TextStyle(color: AppColors.muted, height: 1.4)),
          ),
          const SizedBox(height: 18),
          _InsightCard(
            title: 'Favorite category distribution',
            child: SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: categoryCounts.entries
                      .where((entry) => entry.value > 0)
                      .map((entry) => PieChartSectionData(
                            value: entry.value.toDouble(),
                            title: entry.key,
                            radius: 72,
                            color: _colorFor(entry.key),
                            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                          ))
                      .toList(),
                  sectionsSpace: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _InsightCard(
            title: 'Weekly bakery visits',
            child: SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(leftTitles: AxisTitles(), topTitles: AxisTitles(), rightTitles: AxisTitles()),
                  barGroups: List.generate(7, (i) {
                    final value = [2, 1, 3, 2, 4, 6, 5][i].toDouble();
                    return BarChartGroupData(x: i, barRods: [BarChartRodData(toY: value, width: 18, color: AppColors.warmBrown, borderRadius: BorderRadius.circular(8))]);
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _InsightCard(
            title: 'Trending bakeries',
            child: SizedBox(
              height: 230,
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.cream, strokeWidth: 1)),
                  titlesData: const FlTitlesData(leftTitles: AxisTitles(), topTitles: AxisTitles(), rightTitles: AxisTitles(), bottomTitles: AxisTitles()),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trending.take(5).toList().asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.trendingScore)).toList(),
                      isCurved: true,
                      color: AppColors.orange,
                      barWidth: 4,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _InsightCard(
            title: 'Most visited types',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppConstants.categories.map((category) => Chip(label: Text(category), avatar: const Icon(Icons.local_cafe_rounded, size: 18))).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(String category) {
    return switch (category) {
      'Cakes' => AppColors.orange,
      'Coffee' => AppColors.espresso,
      'Pastries' => AppColors.warmBrown,
      'Bread' => AppColors.sage,
      _ => AppColors.muted,
    };
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: AppColors.espresso.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 10))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 12), child]),
    );
  }
}
