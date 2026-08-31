// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: budget_screen.dart
//
// Purpose:
// Main budget management screen displaying month navigation, overall monthly budget card, and category budgets.
//
// Responsibilities:
// - Render top persistent month navigation bar (`_buildMonthSelector`).
// - Display overall monthly budget summary card and category budget cards.
// - Trigger modal bottom sheet for creating new budgets or inspecting budget details.
//
// Data Flow:
// budgetProvider → BudgetScreen → BudgetCardWidget / AddBudgetBottomSheet / BudgetDetailBottomSheet
//
// Important Rules:
// - overallBudget is identified by `categoryId == null`.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/budget_model.dart';
import '../providers/budget_provider.dart';
import '../widgets/add_budget_bottom_sheet.dart';
import '../widgets/budget_card_widget.dart';
import '../widgets/budget_detail_bottom_sheet.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  void _openAddBudgetSheet(BuildContext context, DateTime selectedMonth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddBudgetBottomSheet(month: selectedMonth),
    );
  }

  void _showDetailBottomSheet(BuildContext context, BudgetModel budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BudgetDetailBottomSheet(budget: budget),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(budgetProvider);
    final notifier = ref.read(budgetProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    BudgetModel? overallBudget;
    try {
      overallBudget = state.currentBudgets.firstWhere(
        (b) => b.categoryId == null,
      );
    } catch (_) {
      overallBudget = null;
    }

    final categoryBudgets = state.currentBudgets
        .where((b) => b.categoryId != null)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets'), elevation: 0),
      body: Column(
        children: [
          // Persistent Month Selector
          _buildMonthSelector(context, state, notifier, isDark),

          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.currentBudgets.isEmpty
                ? _buildEmptyState(context, state.selectedMonth)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // 1. Overall Budget Summary Card
                      if (overallBudget != null) ...[
                        _buildSectionHeader(context, 'Monthly Summary', isDark),
                        BudgetCardWidget(
                          title: 'Overall Limit',
                          budgetAmount: overallBudget.amount,
                          spentAmount: state.categorySpending[null] ?? 0.0,
                          icon: Icons.all_inclusive_rounded,
                          iconColor: AppColors.primary,
                          onTap: () =>
                              _showDetailBottomSheet(context, overallBudget!),
                        ),
                        const SizedBox(height: 24),
                      ] else ...[
                        _buildSectionHeader(context, 'Monthly Summary', isDark),
                        _buildAddOverallPrompt(
                          context,
                          state.selectedMonth,
                          isDark,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 2. Category Budgets Section
                      if (categoryBudgets.isNotEmpty) ...[
                        _buildSectionHeader(context, 'Category Limits', isDark),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: categoryBudgets.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final budget = categoryBudgets[index];
                            final spent =
                                state.categorySpending[budget.categoryId] ??
                                0.0;
                            final catMeta = AppConstants.defaultCategories
                                .firstWhere(
                                  (c) => c['id'] == budget.categoryId,
                                  orElse: () => {
                                    'icon': Icons.category_rounded,
                                    'color': AppColors.primary,
                                  },
                                );
                            return BudgetCardWidget(
                              title: budget.categoryName ?? '',
                              budgetAmount: budget.amount,
                              spentAmount: spent,
                              icon: catMeta['icon'] as IconData,
                              iconColor: catMeta['color'] as Color,
                              onTap: () =>
                                  _showDetailBottomSheet(context, budget),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddBudgetSheet(context, state.selectedMonth),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildMonthSelector(
    BuildContext context,
    BudgetState state,
    BudgetNotifier notifier,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              final prev = DateTime(
                state.selectedMonth.year,
                state.selectedMonth.month - 1,
                1,
              );
              notifier.setSelectedMonth(prev);
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(state.selectedMonth),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              final next = DateTime(
                state.selectedMonth.year,
                state.selectedMonth.month + 1,
                1,
              );
              notifier.setSelectedMonth(next);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildAddOverallPrompt(
    BuildContext context,
    DateTime selectedMonth,
    bool isDark,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.all_inclusive_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No Overall Limit Set',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Set an overall monthly budget to track your complete spending pace and remain on target.',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _openAddBudgetSheet(context, selectedMonth),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Set Overall Budget'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DateTime selectedMonth) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyStateWidget(
              icon: Icons.pie_chart_rounded,
              title:
                  'No budget for ${DateFormat('MMMM').format(selectedMonth)}',
              description:
                  'Set spending limits for this month to monitor your category expenses.',
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openAddBudgetSheet(context, selectedMonth),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Set Monthly Budget'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
