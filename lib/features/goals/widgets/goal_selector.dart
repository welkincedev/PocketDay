// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: goal_selector.dart
//
// Purpose:
// Dropdown form widget for selecting an optional target `GoalModel` to link when logging an expense.
//
// Responsibilities:
// - Render list of available goals from `goalsProvider`.
// - Allow selecting 'None' (null) or a specific goal ID.
//
// Data Flow:
// goalsProvider → GoalSelector → AddTransactionBottomSheet form state
//
// Important Rules:
// - If no goals exist in state, renders `SizedBox.shrink()`.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/goal_model.dart';
import '../providers/goals_provider.dart';

/// A dropdown/selector widget for linking a transaction to a Goal.
/// Used in expense forms. Returns null for "None" selection.
class GoalSelector extends ConsumerWidget {
  final String? selectedGoalId;
  final ValueChanged<String?> onChanged;

  const GoalSelector({
    super.key,
    required this.selectedGoalId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goalsState = ref.watch(goalsProvider);
    final goals = goalsState.goals;

    if (goals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: DropdownButtonFormField<String?>(
            initialValue: selectedGoalId,
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
            ),
            dropdownColor: isDark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            hint: Text(
              'None',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  'None',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              ...goals.map((GoalModel goal) {
                return DropdownMenuItem<String?>(
                  value: goal.id,
                  child: Row(
                    children: [
                      Text(goal.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          goal.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
