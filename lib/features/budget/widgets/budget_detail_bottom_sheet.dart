import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';

import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../dashboard/widgets/transaction_item_tile.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../providers/budget_provider.dart';
import 'add_budget_bottom_sheet.dart';

class BudgetDetailBottomSheet extends ConsumerWidget {
  final BudgetModel budget;

  const BudgetDetailBottomSheet({
    super.key,
    required this.budget,
  });

  void _openEditSheet(BuildContext context, DateTime selectedMonth) {
    Navigator.pop(context); // Close details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddBudgetBottomSheet(
        month: selectedMonth,
        budgetToEdit: budget,
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          title: Text(
            budget.categoryId == null ? 'Delete Overall Budget?' : 'Delete Category Budget?',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this budget? Your transaction history will not be deleted.',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(budgetProvider.notifier).deleteBudget(budget.id);
                Navigator.pop(ctx); // Close Dialog
                Navigator.pop(context); // Close Detail sheet
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final budgetState = ref.watch(budgetProvider);
    final txnsState = ref.watch(transactionsProvider);

    final spent = budgetState.categorySpending[budget.categoryId] ?? 0.0;
    final remaining = budget.amount - spent;
    final percent = budget.amount > 0 ? (spent / budget.amount) : 0.0;
    final displayPercent = (percent * 100).toStringAsFixed(0);

    // Look up category metadata
    final isOverall = budget.categoryId == null;
    final categoryMeta = isOverall
        ? null
        : AppConstants.defaultCategories.firstWhere(
            (c) => c['id'] == budget.categoryId,
            orElse: () => {'name': 'Other', 'icon': Icons.category_rounded, 'color': AppColors.primary},
          );

    final title = isOverall ? 'Overall Monthly Budget' : (budget.categoryName ?? categoryMeta?['name'] as String);
    final icon = isOverall ? Icons.all_inclusive_rounded : (categoryMeta?['icon'] as IconData);
    final color = isOverall ? AppColors.primary : (categoryMeta?['color'] as Color);

    // Filter transactions for this month & category scope
    final expenses = txnsState.transactions.where((t) {
      final tMonth = DateFormat('yyyy-MM').format(t.date);
      final monthMatches = tMonth == budget.month;
      final typeMatches = t.type == TransactionType.expense;
      final scopeMatches = isOverall || t.categoryId == budget.categoryId;
      return monthMatches && typeMatches && scopeMatches;
    }).toList();

    // Determine status description
    Color statusColor;
    String statusText;
    if (percent >= 1.0) {
      statusColor = AppColors.expense;
      statusText = 'Budget exceeded by ${CurrencyFormatter.format(spent - budget.amount)}';
    } else if (percent >= 0.90) {
      statusColor = Colors.orange;
      statusText = 'Almost used up • ${CurrencyFormatter.format(remaining)} left';
    } else if (percent >= 0.70) {
      statusColor = Colors.amber;
      statusText = 'Getting close • ${CurrencyFormatter.format(remaining)} left';
    } else {
      statusColor = AppColors.primary;
      statusText = 'On track • ${CurrencyFormatter.format(remaining)} left';
    }

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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
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
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Budget Scope for ${DateFormat('MMMM yyyy').format(budgetState.selectedMonth)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats Block
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  'Budget Limit',
                  CurrencyFormatter.format(budget.amount),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  context,
                  'Spent',
                  CurrencyFormatter.format(spent),
                  isDark,
                  valueColor: percent >= 1.0 ? AppColors.expense : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress and Warning
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: percent >= 1.0 ? AppColors.expense : statusColor,
                      ),
                    ),
                    Text(
                      '$displayPercent%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      FractionallySizedBox(
                        widthFactor: percent.clamp(0.0, 1.0),
                        child: Container(
                          height: 6,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Edit/Delete buttons row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openEditSheet(context, budgetState.selectedMonth),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit Budget'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, ref),
                  icon: const Icon(Icons.delete_forever_rounded, size: 18, color: AppColors.expense),
                  label: const Text('Delete', style: TextStyle(color: AppColors.expense)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.expense),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Recent transactions title
          Text(
            'Related Expenses (${expenses.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
          ),
          const SizedBox(height: 10),

          // Scrollable transaction list
          Expanded(
            child: expenses.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No spending transactions this month.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final txn = expenses[index];
                      return TransactionItemTile(transaction: txn);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context,
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
          ),
        ],
      ),
    );
  }
}
