import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/bakery.dart';
import '../../data/models/review.dart';
import '../../data/repositories/bakery_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/rating_badge.dart';

class BakeryDetailsScreen extends StatefulWidget {
  const BakeryDetailsScreen({super.key, required this.bakery});

  final Bakery bakery;

  @override
  State<BakeryDetailsScreen> createState() => _BakeryDetailsScreenState();
}

class _BakeryDetailsScreenState extends State<BakeryDetailsScreen> {
  late final Future<List<Review>> _reviews = BakeryRepository().fetchReviews(
    widget.bakery.id,
  );

  Future<void> _openMaps() async {
    final uri = Uri.parse(
      'https://www.openstreetmap.org/?mlat=${widget.bakery.latitude}&mlon=${widget.bakery.longitude}#map=16/${widget.bakery.latitude}/${widget.bakery.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final isFavorite = favorites.isFavorite(widget.bakery.id);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FavoriteButton(
                  isFavorite: isFavorite,
                  onTap: () => favorites.toggle(
                    context.read<AppAuthProvider>().user?.uid,
                    widget.bakery.id,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'bakery-${widget.bakery.id}',
                    child: CachedNetworkImage(
                      imageUrl: widget.bakery.imageUrls.first,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RatingBadge(rating: widget.bakery.rating),
                        const SizedBox(height: 10),
                        Text(
                          widget.bakery.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        Text(
                          widget.bakery.address,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _InfoStrip(bakery: widget.bakery, onMaps: _openMaps),
                const SizedBox(height: 22),
                _Section(
                  title: 'About',
                  child: Text(
                    widget.bakery.description,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _Gallery(images: widget.bakery.imageUrls),
                const SizedBox(height: 22),
                _Section(
                  title: 'Popular menu',
                  child: _MenuGrid(items: widget.bakery.menu),
                ),
                const SizedBox(height: 22),
                _Section(
                  title: 'Reviews',
                  child: _Reviews(reviews: _reviews),
                ),
              ]),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        color: Colors.white,
        child: SafeArea(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.event_available_rounded),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => ReservationSheet(bakery: widget.bakery),
            ),
            label: const Text('Reserve Table'),
          ),
        ),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.bakery, required this.onMaps});

  final Bakery bakery;
  final VoidCallback onMaps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Pill(
            icon: Icons.people_alt_rounded,
            text: '${bakery.reviewCount} reviews',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Pill(
            icon: Icons.schedule_rounded,
            text: 'Until ${bakery.openUntil}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Pill(
            icon: Icons.directions_rounded,
            text: 'Maps',
            onTap: onMaps,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.warmBrown),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: CachedNetworkImage(
            imageUrl: images[index],
            width: 132,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.items});

  final List<MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    '₹${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.warmBrown,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Reviews extends StatelessWidget {
  const _Reviews({required this.reviews});

  final Future<List<Review>> reviews;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Review>>(
      future: reviews,
      builder: (_, snapshot) {
        final data = snapshot.data ?? [];
        if (!snapshot.hasData) return const LinearProgressIndicator();
        return Column(
          children: data
              .map(
                (review) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.cream,
                        child: Text(review.userName.characters.first),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              review.comment,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class ReservationSheet extends StatefulWidget {
  const ReservationSheet({super.key, required this.bakery});

  final Bakery bakery;

  @override
  State<ReservationSheet> createState() => _ReservationSheetState();
}

class _ReservationSheetState extends State<ReservationSheet> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _slot = '6:30 PM';
  int _guests = 2;
  bool _done = false;
  String? _confirmationNote;

  @override
  Widget build(BuildContext context) {
    final slots = ['10:30 AM', '1:00 PM', '4:30 PM', '6:30 PM', '8:00 PM'];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _done
            ? Column(
                key: const ValueKey('success'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.sage,
                    size: 84,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Reservation confirmed',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    _confirmationNote ??
                        'Your table is mocked, polished, and ready.',
                  ),
                ],
              )
            : Column(
                key: const ValueKey('form'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reserve at ${widget.bakery.name}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month_rounded),
                    title: Text(DateFormat('EEE, MMM d').format(_date)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        initialDate: _date,
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                  ),
                  Wrap(
                    spacing: 8,
                    children: slots
                        .map(
                          (slot) => ChoiceChip(
                            label: Text(slot),
                            selected: _slot == slot,
                            onSelected: (_) => setState(() => _slot = slot),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text(
                        'Guests',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _guests > 1
                            ? () => setState(() => _guests--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$_guests'),
                      IconButton(
                        onPressed: () => setState(() => _guests++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Consumer<ReservationProvider>(
                    builder: (context, provider, child) => ElevatedButton(
                      onPressed: provider.isSaving
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final userId =
                                  context.read<AppAuthProvider>().user?.uid ??
                                  'guest';
                              final confirmed = await provider.reserve(
                                userId: userId,
                                bakery: widget.bakery,
                                date: _date,
                                timeSlot: _slot,
                                guests: _guests,
                              );
                              if (!mounted) return;
                              if (confirmed) {
                                setState(() {
                                  _confirmationNote =
                                      'Your table has been reserved.';
                                  _done = true;
                                });
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      provider.errorMessage ??
                                          'Could not confirm your reservation.',
                                    ),
                                  ),
                                );
                              }
                            },
                      child: provider.isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Confirm Reservation'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
