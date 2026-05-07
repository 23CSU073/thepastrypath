import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AnimatedSearchBar extends StatefulWidget {
  const AnimatedSearchBar({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: _focused ? 1 : 0.82),
        borderRadius: BorderRadius.circular(_focused ? 24 : 18),
        border: Border.all(color: _focused ? AppColors.orange : Colors.transparent, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmBrown.withValues(alpha: _focused ? 0.15 : 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.warmBrown),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: const ValueKey('bakery-search-field'),
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              maxLines: 1,
              style: const TextStyle(fontSize: 16, height: 1.1),
              decoration: const InputDecoration(
                isCollapsed: true,
                hintText: 'Search bakeries, cafes, coffee...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
