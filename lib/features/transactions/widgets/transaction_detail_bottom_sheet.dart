import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/transaction_model.dart';
import '../../dashboard/widgets/add_transaction_bottom_sheet.dart';
import '../providers/transactions_provider.dart';

class TransactionDetailBottomSheet extends ConsumerWidget {
  final TransactionModel transaction;

  const TransactionDetailBottomSheet({
    super.key,
    required this.transaction,
  });

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text(
          'Are you sure you want to permanently delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close details sheet
              ref.read(transactionsProvider.notifier).deleteTransaction(transaction.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditSheet(BuildContext context, WidgetRef ref) {
    Navigator.pop(context); // Close details sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionBottomSheet(
        initialType: transaction.type,
        transactionToEdit: transaction,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hideBalance = ref.watch(hideBalanceProvider);
    final isIncome = transaction.type == TransactionType.income;

    // Category metadata lookup
    final categoryMeta = AppConstants.defaultCategories.firstWhere(
      (cat) => cat['id'] == transaction.categoryId,
      orElse: () => {
        'icon': isIncome ? Icons.account_balance_wallet_rounded : Icons.shopping_bag_rounded,
        'color': isIncome ? AppColors.income : AppColors.expense,
      },
    );

    final categoryColor = categoryMeta['color'] as Color;
    final categoryIcon = categoryMeta['icon'] as IconData;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.only(
        top: 12,
        bottom: 28,
        left: 24,
        right: 24,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Category Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: categoryColor.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        categoryIcon,
                        color: categoryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      transaction.categoryName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isIncome ? AppColors.income : AppColors.expense).withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isIncome ? 'Income' : 'Expense',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isIncome ? AppColors.income : AppColors.expense,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Transaction Title
            Text(
              transaction.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // Date & Time
            Text(
              '${DateFormatter.formatFull(transaction.date)} at ${DateFormatter.formatTime(transaction.date)}',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Amount Display
            Text(
              'Amount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withAlpha(180),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount, isHidden: hideBalance)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: isIncome ? AppColors.income : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),

            // Notes Block (if any notes exist)
            if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withAlpha(180),
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 16,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transaction.notes!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmDelete(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.expense,
                      side: const BorderSide(color: AppColors.expense),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    text: 'Edit',
                    onPressed: () => _openEditSheet(context, ref),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
