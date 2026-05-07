import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({super.key, this.height = 160, this.width = double.infinity});

  final double height;
  final double width;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 950))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.cream.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }
}
