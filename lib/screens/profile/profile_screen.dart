import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/bakery.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bakery_provider.dart';
import '../../routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final bakeryProvider = context.watch<BakeryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.warmBrown, AppColors.espresso],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.cream,
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.warmBrown,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bakery Explorer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        auth.user?.email ?? 'Guest profile',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ActionTile(
            icon: Icons.history_rounded,
            title: 'Recent searches',
            subtitle: bakeryProvider.recentSearches.isEmpty
                ? 'No searches yet'
                : bakeryProvider.recentSearches.take(3).join(', '),
            onTap: () => _showRecentSearches(context, bakeryProvider),
          ),
          _ActionTile(
            icon: Icons.badge_rounded,
            title: 'View profile',
            subtitle: 'Account, taste notes, saved activity',
            onTap: () => _showProfileDetails(context, auth, bakeryProvider),
          ),
          _ActionTile(
            icon: Icons.rate_review_rounded,
            title: 'Leave a review',
            subtitle: 'Rate a cafe or bakery you visited',
            onTap: () => _showReviewSheet(context, bakeryProvider.bakeries),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.auth);
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showRecentSearches(BuildContext context, BakeryProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent searches',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if (provider.recentSearches.isEmpty)
              const Text(
                'Search for a cafe or bakery and it will appear here.',
                style: TextStyle(color: AppColors.muted),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.recentSearches.map((query) {
                  return ActionChip(
                    avatar: const Icon(Icons.search_rounded, size: 18),
                    label: Text(query),
                    onPressed: () {
                      provider.setSearch(query);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _showProfileDetails(
    BuildContext context,
    AppAuthProvider auth,
    BakeryProvider bakeryProvider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            _ProfileRow(label: 'Email', value: auth.user?.email ?? 'Guest'),
            _ProfileRow(
              label: 'Recently viewed',
              value: '${bakeryProvider.recentlyViewed.length} places',
            ),
            _ProfileRow(
              label: 'Searches saved',
              value: '${bakeryProvider.recentSearches.length} searches',
            ),
            const SizedBox(height: 12),
            const Text(
              'Taste note: You are building a soft spot for coffee cafes, pastry counters, and cozy tables.',
              style: TextStyle(color: AppColors.muted, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewSheet(BuildContext context, List<Bakery> bakeries) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReviewSheet(bakeries: bakeries),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: CircleAvatar(
        backgroundColor: AppColors.cream,
        child: Icon(icon, color: AppColors.warmBrown),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewSheet extends StatefulWidget {
  const ReviewSheet({super.key, required this.bakeries});

  final List<Bakery> bakeries;

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  Bakery? _selected;
  int _rating = 5;
  final _comment = TextEditingController();
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.bakeries.isEmpty ? null : widget.bakeries.first;
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: _submitted
            ? const Column(
                key: ValueKey('review-success'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.sage,
                    size: 76,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Review saved',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  Text('Thanks for helping other pastry people choose well.'),
                ],
              )
            : Column(
                key: const ValueKey('review-form'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Leave a review',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<Bakery>(
                    initialValue: _selected,
                    decoration: const InputDecoration(
                      labelText: 'Cafe or bakery',
                    ),
                    items: widget.bakeries.map((bakery) {
                      return DropdownMenuItem(
                        value: bakery,
                        child: Text(bakery.name),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selected = value),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      return IconButton(
                        onPressed: () => setState(() => _rating = value),
                        icon: Icon(
                          value <= _rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: AppColors.orange,
                          size: 30,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _comment,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'What did you try? How was the vibe?',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _selected == null
                        ? null
                        : () {
                            setState(() => _submitted = true);
                          },
                    icon: const Icon(Icons.rate_review_rounded),
                    label: const Text('Submit Review'),
                  ),
                ],
              ),
      ),
    );
  }
}
