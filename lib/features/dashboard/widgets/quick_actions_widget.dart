// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: quick_actions_widget.dart
//
// Purpose:
// Quick action buttons bar rendering '+ Add Income' and '- Add Expense' buttons on the dashboard.
//
// Responsibilities:
// - Render styled action buttons with green and red accent themes.
// - Trigger modal bottom sheet for entering income or expense records.
//
// Data Flow:
// DashboardScreen → QuickActionsWidget → onAddTransaction callback
//
// Important Rules:
// - Desaturated tones are applied dynamically depending on active light/dark theme.
// ============================================================

import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/transaction_model.dart';

class QuickActionsWidget extends StatelessWidget {
  final Function(TransactionType) onAddTransaction;

  const QuickActionsWidget({super.key, required this.onAddTransaction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Desaturated green tones for Income
    final incomeBgColor = isDark
        ? const Color(0xFF064E3B).withAlpha(120)
        : const Color(0xFFD1FAE5);
    final incomeTextColor = isDark
        ? const Color(0xFF34D399)
        : const Color(0xFF065F46);

    // Desaturated red tones for Expense
    final expenseBgColor = isDark
        ? const Color(0xFF7F1D1D).withAlpha(120)
        : const Color(0xFFFEE2E2);
    final expenseTextColor = isDark
        ? const Color(0xFFF87171)
        : const Color(0xFF991B1B);

    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context: context,
            label: AppStrings.addIncome,
            icon: Icons.add_circle_rounded,
            bgColor: incomeBgColor,
            textColor: incomeTextColor,
            onTap: () => onAddTransaction(TransactionType.income),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildActionButton(
            context: context,
            label: AppStrings.addExpense,
            icon: Icons.remove_circle_rounded,
            bgColor: expenseBgColor,
            textColor: expenseTextColor,
            onTap: () => onAddTransaction(TransactionType.expense),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      elevation: 2,
      shadowColor: Colors.black.withAlpha(20),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: textColor.withAlpha(60), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
