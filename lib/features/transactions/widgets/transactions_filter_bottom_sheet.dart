// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: transactions_filter_bottom_sheet.dart
//
// Purpose:
// Modal bottom sheet for configuring transaction filtering, sorting, category selection, and date presets.
//
// Responsibilities:
// - Render transaction type filter chips (All, Income, Expense).
// - Render category filter chips based on `AppConstants.defaultCategories`.
// - Render date range presets (Today, Week, Month, Custom Range via `showDateRangePicker`).
// - Render sorting order options (Newest/Oldest First, Highest/Lowest Amount).
// - Update `transactionsProvider` state as chips are selected.
//
// Data Flow:
// User ChoiceChip Taps → transactionsProvider.notifier setters → TransactionsState updated
//
// Important Rules:
// - Tapping 'Clear all' resets filters back to default values.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/transaction_model.dart';
import '../providers/transactions_provider.dart';

class TransactionsFilterBottomSheet extends ConsumerWidget {
  const TransactionsFilterBottomSheet({super.key});

  Future<void> _pickCustomDateRange(BuildContext context, WidgetRef ref) async {
    final state = ref.read(transactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: state.selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.darkSurface,
                    onSurface: AppColors.darkTextPrimary,
                    secondary: AppColors.primary,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.lightSurface,
                    onSurface: AppColors.lightTextPrimary,
                    secondary: AppColors.primary,
                  ),
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(transactionsProvider.notifier).setSelectedDateRange(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasActiveFilters =
        state.selectedCategoryId != null ||
        state.selectedType != null ||
        state.selectedDateRange != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 20,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  if (hasActiveFilters)
                    TextButton(
                      onPressed: () {
                        ref.read(transactionsProvider.notifier).resetFilters();
                      },
                      child: const Text(
                        'Clear all',
                        style: TextStyle(
                          color: AppColors.expense,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Transaction Type
                  _buildSectionHeader(context, 'Transaction Type'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildChip(
                        label: 'All Types',
                        selected: state.selectedType == null,
                        onSelected: (_) => ref
                            .read(transactionsProvider.notifier)
                            .setSelectedType(null),
                      ),
                      _buildChip(
                        label: 'Income',
                        selected: state.selectedType == TransactionType.income,
                        activeColor: AppColors.income,
                        onSelected: (_) => ref
                            .read(transactionsProvider.notifier)
                            .setSelectedType(TransactionType.income),
                      ),
                      _buildChip(
                        label: 'Expense',
                        selected: state.selectedType == TransactionType.expense,
                        activeColor: AppColors.expense,
                        onSelected: (_) => ref
                            .read(transactionsProvider.notifier)
                            .setSelectedType(TransactionType.expense),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Category
                  _buildSectionHeader(context, 'Category'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildChip(
                        label: 'All Categories',
                        selected: state.selectedCategoryId == null,
                        onSelected: (_) => ref
                            .read(transactionsProvider.notifier)
                            .setSelectedCategory(null),
                      ),
                      ...AppConstants.defaultCategories.map((cat) {
                        final id = cat['id'] as String;
                        final name = cat['name'] as String;
                        final color = cat['color'] as Color;
                        return _buildChip(
                          label: name,
                          selected: state.selectedCategoryId == id,
                          activeColor: color,
                          icon: cat['icon'] as IconData,
                          onSelected: (_) => ref
                              .read(transactionsProvider.notifier)
                              .setSelectedCategory(id),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Date Filter
                  _buildSectionHeader(context, 'Date Filter'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildChip(
                        label: 'All Dates',
                        selected: state.datePreset == 'all',
                        onSelected: (_) => ref
                            .read(transactionsProvider.notifier)
                            .setDatePreset('all'),
                      ),
                      _buildChip(
                        label: 'Today',
                        selected: state.datePreset == 'today',
                        onSelected: (_) => ref
                            .read(transactionsProvider.notifier)
                            .setDatePreset('today'),
                      ),
                      _buildChip(
                        label: 'This Week',
                        selected: state.datePreset == 'week',
                        onSelected: (_) => ref
                            .read(transactionsProvider.notifier)
                            .setDatePreset('week'),
                      ),
                      _buildChip(
                        label: 'This Month',
                        selected: state.datePreset == 'month',
                        onSelected: (_) => ref
                            .read(transactionsProvider.notifier)
                            .setDatePreset('month'),
                      ),
                      _buildChip(
                        label: 'Custom Range',
                        selected: state.datePreset == 'custom',
                        onSelected: (_) => _pickCustomDateRange(context, ref),
                      ),
                    ],
                  ),
                  if (state.selectedDateRange != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.date_range_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${DateFormat('MMM dd, yyyy').format(state.selectedDateRange!.start)}  →  ${DateFormat('MMM dd, yyyy').format(state.selectedDateRange!.end)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // 4. Sort By
                  _buildSectionHeader(context, 'Sort By'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildChip(
                        label: 'Newest First',
                        selected: state.sortBy == TransactionSortBy.dateDesc,
                        onSelected: (_) => ref
                            .read(transactionsProvider.notifier)
                            .setSortBy(TransactionSortBy.dateDesc),
                      ),
                      _buildChip(
                        label: 'Oldest First',
                        selected: state.sortBy == TransactionSortBy.dateAsc,
                        onSelected: (_) => ref
                            .read(transactionsProvider.notifier)
                            .setSortBy(TransactionSortBy.dateAsc),
                      ),
                      _buildChip(
                        label: 'Highest Amount',
                        selected: state.sortBy == TransactionSortBy.amountDesc,
                        onSelected: (_) => ref
                            .read(transactionsProvider.notifier)
                            .setSortBy(TransactionSortBy.amountDesc),
                      ),
                      _buildChip(
                        label: 'Lowest Amount',
                        selected: state.sortBy == TransactionSortBy.amountAsc,
                        onSelected: (_) => ref
                            .read(transactionsProvider.notifier)
                            .setSortBy(TransactionSortBy.amountAsc),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // Apply Button
          AppButton(
            text: 'Apply Filters',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    Color? activeColor,
    IconData? icon,
  }) {
    return ChoiceChip(
      avatar: icon != null
          ? Icon(
              icon,
              size: 14,
              color: selected
                  ? Colors.white
                  : (activeColor ?? AppColors.primary),
            )
          : null,
      label: Text(label),
      selected: selected,
      selectedColor:
          activeColor?.withAlpha(40) ?? AppColors.primary.withAlpha(40),
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected ? (activeColor ?? AppColors.primary) : null,
      ),
      side: BorderSide(
        color: selected
            ? (activeColor ?? AppColors.primary)
            : Colors.transparent,
      ),
      onSelected: onSelected,
    );
  }
}
