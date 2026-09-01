// ============================================================================
// PocketDay
// File: add_to_goal_sheet.dart
// Purpose: Form sheet for adding a monetary contribution transaction to a goal.
// Architecture: Presentation Layer
// State Management: Riverpod
// Storage: Cloud Firestore with Native Offline Cache
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../features/transactions/providers/transactions_provider.dart';
import '../../../features/goals/providers/goals_provider.dart';
import '../../../features/dashboard/providers/dashboard_provider.dart';

class AddToGoalSheet extends ConsumerStatefulWidget {
  final GoalModel goal;
  final double currentAmount;

  const AddToGoalSheet({
    super.key,
    required this.goal,
    required this.currentAmount,
  });

  @override
  ConsumerState<AddToGoalSheet> createState() => _AddToGoalSheetState();
}

class _AddToGoalSheetState extends ConsumerState<AddToGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  void _submit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.trim());
      final notes = _notesController.text.trim();

      final txn = TransactionModel(
        id: const Uuid().v4(),
        title: 'Added to ${widget.goal.name}',
        amount: amount,
        type: TransactionType.income,
        categoryId: 'goal_contribution',
        categoryName: 'Goal Contribution',
        date: DateTime.now(),
        notes: notes.isNotEmpty ? notes : null,
        goalId: widget.goal.id,
      );

      await ref.read(transactionsProvider.notifier).addTransaction(txn);
      await ref.read(goalsProvider.notifier).loadGoals();
      await ref.read(dashboardProvider.notifier).loadDashboardData();

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add to goal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enteredAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final remainingAmount = widget.goal.calculateRemainingAmount(
      widget.currentAmount,
    );

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Text(widget.goal.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add to ${widget.goal.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Context info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(widget.currentAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Remaining',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      Text(
                        remainingAmount > 0
                            ? CurrencyFormatter.format(remainingAmount)
                            : 'Goal reached!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: remainingAmount <= 0
                              ? AppColors.primary
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Amount input
              AppTextField(
                controller: _amountController,
                label: 'Amount to add',
                hint: 'Enter amount (₹)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixIcon: Icons.currency_rupee_rounded,
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) {
                    return 'Enter a valid positive amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes
              AppTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'e.g., Monthly contribution',
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              AppButton(
                text: enteredAmount > 0
                    ? 'Add ${CurrencyFormatter.format(enteredAmount)}'
                    : 'Add Money',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
