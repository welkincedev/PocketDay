import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/subscription_model.dart';
import '../providers/subscription_provider.dart';

/// # Developer Notes
///
/// Bottom sheet form for adding or editing a Subscription in PocketDay.
///
/// Features preset quick-fill chips for popular services (Netflix, Spotify, etc.)
/// and auto-calculates the next payment date based on billing cycle.
class AddSubscriptionSheet extends ConsumerStatefulWidget {
  final SubscriptionModel? subscriptionToEdit;

  const AddSubscriptionSheet({super.key, this.subscriptionToEdit});

  @override
  ConsumerState<AddSubscriptionSheet> createState() =>
      _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends ConsumerState<AddSubscriptionSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  late SubscriptionBillingCycle _billingCycle;
  late DateTime _startDate;
  late DateTime _nextPaymentDate;
  late String _category;
  late String _paymentMethod;
  late SubscriptionStatus _status;
  late bool _autoRecordExpense;

  static const List<String> _categories = [
    'Entertainment',
    'Utilities',
    'Fitness',
    'Software',
    'Services',
    'Cloud',
    'Other',
  ];

  static const List<String> _paymentMethods = [
    'UPI',
    'Cash',
    'Bank Transfer',
    'Card',
    'Auto-Debit',
    'Other',
  ];

  static const List<Map<String, dynamic>> _presets = [
    {
      'name': 'Netflix',
      'amount': '649',
      'cycle': SubscriptionBillingCycle.monthly,
      'category': 'Entertainment',
    },
    {
      'name': 'Spotify',
      'amount': '119',
      'cycle': SubscriptionBillingCycle.monthly,
      'category': 'Entertainment',
    },
    {
      'name': 'YouTube Premium',
      'amount': '149',
      'cycle': SubscriptionBillingCycle.monthly,
      'category': 'Entertainment',
    },
    {
      'name': 'Amazon Prime',
      'amount': '1499',
      'cycle': SubscriptionBillingCycle.yearly,
      'category': 'Entertainment',
    },
    {
      'name': 'Google One',
      'amount': '130',
      'cycle': SubscriptionBillingCycle.monthly,
      'category': 'Cloud',
    },
    {
      'name': 'Gym Membership',
      'amount': '1500',
      'cycle': SubscriptionBillingCycle.monthly,
      'category': 'Fitness',
    },
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.subscriptionToEdit;
    _nameController = TextEditingController(text: edit?.name ?? '');
    _amountController = TextEditingController(
      text: edit != null ? edit.amount.toStringAsFixed(0) : '',
    );
    _notesController = TextEditingController(text: edit?.notes ?? '');

    _billingCycle = edit?.billingCycle ?? SubscriptionBillingCycle.monthly;
    _startDate = edit?.startDate ?? DateTime.now();
    _nextPaymentDate =
        edit?.nextPaymentDate ??
        SubscriptionModel.calculateNextDate(DateTime.now(), _billingCycle);
    _category = edit?.category ?? 'Entertainment';
    _paymentMethod = edit?.paymentMethod ?? 'UPI';
    _status = edit?.status ?? SubscriptionStatus.active;
    _autoRecordExpense = edit?.autoRecordExpense ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _nameController.text = preset['name'];
      _amountController.text = preset['amount'];
      _billingCycle = preset['cycle'];
      _category = preset['category'];
      _nextPaymentDate = SubscriptionModel.calculateNextDate(
        _startDate,
        _billingCycle,
      );
    });
  }

  Future<void> _selectDate(BuildContext context, bool isNextPayment) async {
    final initial = isNextPayment ? _nextPaymentDate : _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isNextPayment) {
          _nextPaymentDate = picked;
        } else {
          _startDate = picked;
          _nextPaymentDate = SubscriptionModel.calculateNextDate(
            picked,
            _billingCycle,
          );
        }
      });
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
      final notes = _notesController.text.trim();

      if (widget.subscriptionToEdit != null) {
        final updated = widget.subscriptionToEdit!.copyWith(
          name: name,
          amount: amount,
          billingCycle: _billingCycle,
          nextPaymentDate: _nextPaymentDate,
          startDate: _startDate,
          category: _category,
          paymentMethod: _paymentMethod,
          status: _status,
          autoRecordExpense: _autoRecordExpense,
          notes: notes.isNotEmpty ? notes : null,
        );
        ref.read(subscriptionProvider.notifier).updateSubscription(updated);
      } else {
        ref
            .read(subscriptionProvider.notifier)
            .addSubscription(
              name: name,
              amount: amount,
              billingCycle: _billingCycle,
              nextPaymentDate: _nextPaymentDate,
              startDate: _startDate,
              category: _category,
              paymentMethod: _paymentMethod,
              status: _status,
              autoRecordExpense: _autoRecordExpense,
              notes: notes.isNotEmpty ? notes : null,
            );
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.subscriptionToEdit != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
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

                // Sheet Title
                Text(
                  isEditing ? 'Edit Subscription' : 'Add Subscription',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Presets Quick-Fill Bar (Only on new subscription)
                if (!isEditing) ...[
                  Text(
                    'QUICK PRESETS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _presets.map((preset) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(preset['name']),
                            avatar: const Icon(
                              Icons.flash_on_rounded,
                              size: 14,
                            ),
                            onPressed: () => _applyPreset(preset),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Name Input
                AppTextField(
                  label: 'Subscription Name',
                  hint: 'e.g. Netflix, Spotify, Internet',
                  controller: _nameController,
                  prefixIcon: Icons.subscriptions_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a subscription name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Amount Input
                AppTextField(
                  label: 'Amount (₹)',
                  hint: '0.00',
                  controller: _amountController,
                  prefixIcon: Icons.currency_rupee_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter amount';
                    }
                    if (double.tryParse(val.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Billing Cycle Selection
                Text(
                  'Billing Cycle',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SubscriptionBillingCycle.values.map((cycle) {
                    final selected = _billingCycle == cycle;
                    return ChoiceChip(
                      showCheckmark: false,
                      label: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(cycle.label),
                      ),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      backgroundColor: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.withAlpha(30),
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary
                            : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                      ),
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary),
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _billingCycle = cycle;
                            _nextPaymentDate =
                                SubscriptionModel.calculateNextDate(
                                  _startDate,
                                  cycle,
                                );
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Dates Row: Start Date & Next Payment Date
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, false),
                        icon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                        ),
                        label: Text(
                          'Start: ${DateFormat('dd MMM yyyy').format(_startDate)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, true),
                        icon: const Icon(Icons.event_rounded, size: 16),
                        label: Text(
                          'Next: ${DateFormat('dd MMM yyyy').format(_nextPaymentDate)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category & Payment Method Row
                Row(
                  children: [
                    // Category Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _categories.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Payment Method Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _paymentMethod,
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _paymentMethods.map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text(
                              m,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _paymentMethod = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status Dropdown
                DropdownButtonFormField<SubscriptionStatus>(
                  initialValue: _status,
                  decoration: InputDecoration(
                    labelText: 'Subscription Status',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: SubscriptionStatus.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: s.color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(s.label, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
                const SizedBox(height: 14),

                // Auto-record expense switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Automatic Expense',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Automatically record expense when due date arrives',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _autoRecordExpense,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _autoRecordExpense = val);
                  },
                ),
                const SizedBox(height: 14),

                // Notes Optional Input
                AppTextField(
                  label: 'Notes (Optional)',
                  hint: 'Plan type, account email, etc.',
                  controller: _notesController,
                  prefixIcon: Icons.notes_rounded,
                ),
                const SizedBox(height: 24),

                // Submit Button
                AppButton(
                  text: isEditing ? 'Save Changes' : 'Add Subscription',
                  onPressed: _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
