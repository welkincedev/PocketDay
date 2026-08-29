import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../features/goals/widgets/goal_selector.dart';

class AddTransactionBottomSheet extends ConsumerStatefulWidget {
  final TransactionType initialType;
  final TransactionModel? transactionToEdit;
  final Function(TransactionModel)? onAdd;

  const AddTransactionBottomSheet({
    super.key,
    required this.initialType,
    this.transactionToEdit,
    this.onAdd,
  });

  @override
  ConsumerState<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState
    extends ConsumerState<AddTransactionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late TransactionType _type;
  late String _selectedCategoryId;
  late DateTime _selectedDate;
  String? _selectedGoalId;

  @override
  void initState() {
    super.initState();
    final editTxn = widget.transactionToEdit;
    if (editTxn != null) {
      _type = editTxn.type;
      _selectedCategoryId = editTxn.categoryId;
      _selectedDate = editTxn.date;
      _titleController.text = editTxn.title;
      _amountController.text = editTxn.amount % 1 == 0
          ? editTxn.amount.toInt().toString()
          : editTxn.amount.toString();
      _notesController.text = editTxn.notes ?? '';
      _selectedGoalId = editTxn.goalId;
    } else {
      _type = widget.initialType;
      _selectedCategoryId = _type == TransactionType.income ? 'salary' : 'food';
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _type == TransactionType.income
                  ? AppColors.income
                  : AppColors.expense,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final categoryMeta = AppConstants.defaultCategories.firstWhere(
        (c) => c['id'] == _selectedCategoryId,
        orElse: () => {'name': 'Other'},
      );

      final txn = TransactionModel(
        id: widget.transactionToEdit?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        type: _type,
        categoryId: _selectedCategoryId,
        categoryName: categoryMeta['name'] as String,
        date: _selectedDate,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        goalId: _type == TransactionType.expense ? _selectedGoalId : null,
      );

      final repo = ref.read(transactionRepositoryProvider);
      if (widget.transactionToEdit != null) {
        await repo.updateTransaction(txn);
      } else {
        await repo.addTransaction(txn);
      }

      if (widget.onAdd != null) {
        widget.onAdd!(txn);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _type == TransactionType.income
        ? AppColors.income
        : AppColors.expense;

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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Drag Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header Title & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _type == TransactionType.income
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: accentColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.transactionToEdit != null
                              ? (_type == TransactionType.income
                                    ? 'Edit Income'
                                    : 'Edit Expense')
                              : (_type == TransactionType.income
                                    ? 'Add Income'
                                    : 'Add Expense'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Transaction Type Selector Chip Row
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(
                          child: Text(
                            'Income',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        selected: _type == TransactionType.income,
                        selectedColor: AppColors.income.withAlpha(40),
                        side: BorderSide(
                          color: _type == TransactionType.income
                              ? AppColors.income
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _type = TransactionType.income;
                              _selectedCategoryId = 'salary';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(
                          child: Text(
                            'Expense',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        selected: _type == TransactionType.expense,
                        selectedColor: AppColors.expense.withAlpha(40),
                        side: BorderSide(
                          color: _type == TransactionType.expense
                              ? AppColors.expense
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _type = TransactionType.expense;
                              _selectedCategoryId = 'food';
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Title Input
                AppTextField(
                  label: 'Title',
                  hint: _type == TransactionType.income
                      ? 'e.g., Monthly Salary'
                      : 'e.g., Swiggy Food Order',
                  controller: _titleController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Amount Input (₹)
                AppTextField(
                  label: 'Amount (₹)',
                  hint: '0.00',
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icons.currency_rupee_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    if (double.tryParse(val.trim()) == null ||
                        double.parse(val.trim()) <= 0) {
                      return 'Enter a valid positive amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                  ),
                  dropdownColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  items: AppConstants.defaultCategories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat['id'] as String,
                      child: Row(
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            color: cat['color'] as Color,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            cat['name'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategoryId = val);
                  },
                ),
                const SizedBox(height: 16),

                // Date Picker Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      icon: Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: accentColor,
                      ),
                      label: Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes Input (Optional)
                AppTextField(
                  label: 'Notes (Optional)',
                  hint: 'Add additional details...',
                  controller: _notesController,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Goal Selector (expenses only)
                if (_type == TransactionType.expense) ...[
                  GoalSelector(
                    selectedGoalId: _selectedGoalId,
                    onChanged: (val) => setState(() => _selectedGoalId = val),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 8),

                // Save Transaction Button
                AppButton(
                  text: widget.transactionToEdit != null
                      ? 'Save Changes'
                      : 'Save Transaction',
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
