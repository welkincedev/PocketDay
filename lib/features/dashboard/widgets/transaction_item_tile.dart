import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/transaction_model.dart';

class TransactionItemTile extends ConsumerWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionItemTile({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = transaction.type == TransactionType.income;

    // Category metadata lookup
    final categoryMeta = AppConstants.defaultCategories.firstWhere(
      (cat) => cat['id'] == transaction.categoryId,
      orElse: () => {
        'icon': isIncome
            ? Icons.account_balance_wallet_rounded
            : Icons.shopping_bag_rounded,
        'color': isIncome ? AppColors.income : AppColors.expense,
      },
    );

    final categoryColor = categoryMeta['color'] as Color;
    final categoryIcon = categoryMeta['icon'] as IconData;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            // Category Icon Container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: categoryColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(categoryIcon, color: categoryColor, size: 20),
            ),
            const SizedBox(width: 14),

            // Title (Primary), Category (Subtitle), Date & Time (Caption)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.categoryName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.formatRelative(transaction.date),
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary)
                              .withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Amount Aligned to Right
            Text(
              '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isIncome
                    ? AppColors.income
                    : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
