// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: app_card.dart
//
// Purpose:
// Reusable surface container card widget with uniform borders, subtle shadows, and InkWell tap feedback.
//
// Responsibilities:
// - Render rounded containers with Material 3 surface styling for dashboard cards, budget cards, and goal cards.
// - Handle light/dark mode background and border colors automatically.
// - Provide touch ripples via Material InkWell when `onTap` is supplied.
//
// Data Flow:
// Child Widgets → AppCard container → UI Screen
//
// Important Rules:
// - Uses 20px corner radius across PocketDay design system.
//
// Main Operations:
// - AppCard(child, padding, onTap, backgroundColor, border)
// ============================================================

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderSide? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              border?.color ??
              (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: border?.width ?? 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}
