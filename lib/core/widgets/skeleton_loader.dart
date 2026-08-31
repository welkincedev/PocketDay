// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: skeleton_loader.dart
//
// Purpose:
// Shimmer pulse animation widget for content loading placeholder states.
//
// Responsibilities:
// - Render smooth opacity pulsing animation during initial data fetch operations.
// - Support custom height, width, and border radii matching standard card shapes.
//
// Data Flow:
// Loading State → SkeletonLoader → UI Skeleton Placeholder
//
// Important Rules:
// - Cleanly disposes AnimationController when unmounted.
//
// Main Operations:
// - SkeletonLoader(width, height, borderRadius)
// ============================================================

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color:
                (isDark
                        ? AppColors.shimmerBaseDark
                        : AppColors.shimmerBaseLight)
                    .withAlpha((_animation.value * 255).round()),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
