// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: empty_state_widget.dart
//
// Purpose:
// Reusable placeholder view displayed when lists or tabs have zero entries.
//
// Responsibilities:
// - Render clean empty state illustration with icon, title, description, and optional call-to-action button.
// - Provide consistent visual feedback when no transactions, budgets, goals, or subscriptions exist.
//
// Data Flow:
// Parent State (empty list) → EmptyStateWidget → UI Display
//
// Important Rules:
// - Always render EmptyStateWidget instead of displaying blank screens when data sets are empty.
//
// Main Operations:
// - EmptyStateWidget(title, description, icon, actionText, onActionPressed)
// ============================================================

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onActionPressed;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.inbox_rounded,
    this.actionText,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onActionPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
