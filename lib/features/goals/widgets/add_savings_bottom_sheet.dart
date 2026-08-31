// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: add_savings_bottom_sheet.dart
//
// Purpose:
// Modal bottom sheet component for depositing money into a `SavingsGoalModel`.
//
// Responsibilities:
// - Collect savings amount in ₹.
// - Calculate preview of new total savings balance.
// - Warn user and require explicit confirmation (`_confirmOverTarget`) if deposit exceeds goal target.
// - Save deposit via `savingsGoalsProvider.addSavings()`.
//
// Data Flow:
// User Deposit Form → addSavings() → savingsGoalsProvider → Hive (`goalsBox`)
//
// Important Rules:
// - Deposits exceeding target amount trigger a two-stage tap confirmation flow.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/savings_goal_model.dart';
import '../providers/savings_goals_provider.dart';

class AddSavingsBottomSheet extends ConsumerStatefulWidget {
  final SavingsGoalModel goal;

  const AddSavingsBottomSheet({super.key, required this.goal});

  @override
  ConsumerState<AddSavingsBottomSheet> createState() =>
      _AddSavingsBottomSheetState();
}

class _AddSavingsBottomSheetState extends ConsumerState<AddSavingsBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  double _enteredAmount = 0.0;
  bool _confirmOverTarget = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final text = _amountController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _enteredAmount = 0.0;
        _confirmOverTarget = false;
      });
      return;
    }

    final val = double.tryParse(text);
    setState(() {
      _enteredAmount = val ?? 0.0;
      if (widget.goal.savedAmount + _enteredAmount <=
          widget.goal.targetAmount) {
        _confirmOverTarget = false;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final totalFutureAmount = widget.goal.savedAmount + _enteredAmount;
    final isOverTarget = totalFutureAmount > widget.goal.targetAmount;

    if (isOverTarget && !_confirmOverTarget) {
      setState(() {
        _confirmOverTarget = true;
      });
      return;
    }

    ref
        .read(savingsGoalsProvider.notifier)
        .addSavings(widget.goal.id, _enteredAmount);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentSaved = widget.goal.savedAmount;
    final targetAmount = widget.goal.targetAmount;
    final totalFutureAmount = currentSaved + _enteredAmount;
    final isOverTarget = totalFutureAmount > targetAmount;

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
              // Header bar
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

              // Title block
              Row(
                children: [
                  Text(widget.goal.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add to ${widget.goal.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
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
              const SizedBox(height: 20),

              // Display metrics comparison
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Savings',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(currentSaved),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'New Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(totalFutureAmount),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isOverTarget
                                  ? Colors.orange
                                  : AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Input field
              AppTextField(
                controller: _amountController,
                label: 'Add Savings Amount',
                hint: 'Enter amount to save (₹)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixIcon: Icons.currency_rupee_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) {
                    return 'Enter a valid amount greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Warning alert box if over budget
              if (isOverTarget) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withAlpha(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Limit Warning',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.orange[300]
                              : Colors.orange[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${CurrencyFormatter.format(_enteredAmount)} will take this goal over its ${CurrencyFormatter.format(targetAmount)} target.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Confirm button
              AppButton(
                text: isOverTarget && !_confirmOverTarget
                    ? 'Confirm Over Target'
                    : 'Add Savings',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
