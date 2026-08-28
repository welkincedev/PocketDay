import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/budget_model.dart';
import '../providers/budget_provider.dart';

class AddBudgetBottomSheet extends ConsumerStatefulWidget {
  final DateTime month;
  final BudgetModel? budgetToEdit;

  const AddBudgetBottomSheet({
    super.key,
    required this.month,
    this.budgetToEdit,
  });

  @override
  ConsumerState<AddBudgetBottomSheet> createState() => _AddBudgetBottomSheetState();
}

class _AddBudgetBottomSheetState extends ConsumerState<AddBudgetBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late DateTime _selectedMonth;
  String? _selectedCategoryId;
  BudgetModel? _existingBudget;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.month;
    _selectedCategoryId = widget.budgetToEdit?.categoryId;

    final amountStr = widget.budgetToEdit != null ? widget.budgetToEdit!.amount.toStringAsFixed(0) : '';
    _amountController = TextEditingController(text: amountStr);

    if (widget.budgetToEdit != null) {
      final parts = widget.budgetToEdit!.month.split('-');
      if (parts.length == 2) {
        _selectedMonth = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
      }
    }
    
    _checkExistingBudget();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _checkExistingBudget() {
    if (widget.budgetToEdit != null) {
      _existingBudget = null;
      return;
    }

    final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);
    final allBudgets = ref.read(budgetProvider).allBudgets;
    
    try {
      _existingBudget = allBudgets.firstWhere(
        (b) => b.month == monthStr && b.categoryId == _selectedCategoryId,
      );
    } catch (_) {
      _existingBudget = null;
    }
  }

  List<DateTime> _getMonthOptions() {
    final now = DateTime.now();
    final List<DateTime> options = [];
    for (int i = -6; i <= 6; i++) {
      options.add(DateTime(now.year, now.month + i, 1));
    }
    // Ensure currently selected month is included in options
    final selectedStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    if (!options.any((d) => d.year == selectedStart.year && d.month == selectedStart.month)) {
      options.add(selectedStart);
      options.sort();
    }
    return options;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text.trim());
      final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);

      final categoryMeta = _selectedCategoryId != null
          ? AppConstants.defaultCategories.firstWhere(
              (c) => c['id'] == _selectedCategoryId,
              orElse: () => {'name': 'Other'},
            )
          : null;

      final budget = BudgetModel(
        id: widget.budgetToEdit?.id ?? _existingBudget?.id ?? const Uuid().v4(),
        amount: amount,
        period: 'monthly',
        month: monthStr,
        categoryId: _selectedCategoryId,
        categoryName: categoryMeta?['name'] as String?,
        createdAt: widget.budgetToEdit?.createdAt ?? _existingBudget?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(budgetProvider.notifier).saveBudget(budget);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.budgetToEdit != null || _existingBudget != null;

    final monthOptions = _getMonthOptions();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 12,
        left: 24,
        right: 24,
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
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

              // Title
              Text(
                isEditing ? 'Edit Budget' : 'New Budget',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
              ),
              const SizedBox(height: 20),

              // Amount Input
              AppTextField(
                controller: _amountController,
                label: 'Budget Amount (₹)',
                hint: 'Enter monthly spending limit',
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
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

              // Category Selector
              DropdownButtonFormField<String?>(
                initialValue: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Budget Scope / Category',
                  labelStyle: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(
                          Icons.all_inclusive_rounded,
                          size: 18,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Overall Budget',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...AppConstants.defaultCategories.map((cat) {
                    final id = cat['id'] as String;
                    final name = cat['name'] as String;
                    final color = cat['color'] as Color;
                    final icon = cat['icon'] as IconData;
                    return DropdownMenuItem<String?>(
                      value: id,
                      child: Row(
                        children: [
                          Icon(icon, size: 18, color: color),
                          const SizedBox(width: 8),
                          Text(
                            name,
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                    _checkExistingBudget();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Month Selector
              DropdownButtonFormField<DateTime>(
                initialValue: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
                decoration: InputDecoration(
                  labelText: 'Budget Month',
                  labelStyle: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                items: monthOptions.map((date) {
                  final text = DateFormat('MMMM yyyy').format(date);
                  return DropdownMenuItem<DateTime>(
                    value: DateTime(date.year, date.month, 1),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedMonth = val;
                      _checkExistingBudget();
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Existing budget warning
              if (_existingBudget != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'A budget for this month & scope already exists. Saving will overwrite it (currently ₹${_existingBudget!.amount.toStringAsFixed(0)}).',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.amber[200] : Colors.amber[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Save Button
              AppButton(
                text: isEditing ? 'Update Budget' : 'Save Budget',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
