import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/goals_provider.dart';

class CreateGoalSheet extends ConsumerStatefulWidget {
  const CreateGoalSheet({super.key});

  @override
  ConsumerState<CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends ConsumerState<CreateGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedEmoji = '🎯';

  final List<String> _emojiPresets = ['🎯', '💰', '📱', '✈️', '🏠', '🚗', '🎓', '🛟', '🎁', '🏖️'];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year, now.month + 1, 1),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.darkBackground,
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppColors.lightTextPrimary,
                  ),
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final targetAmount = double.parse(_amountController.text.trim());

    ref.read(goalsProvider.notifier).addGoal(
          name: name,
          targetAmount: targetAmount,
          emoji: _selectedEmoji,
          targetDate: _selectedDate,
        );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Create Goal',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
              ),
              const SizedBox(height: 20),

              AppTextField(
                controller: _nameController,
                label: 'What are you working toward?',
                hint: 'e.g. Trip to Goa, New Phone',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Goal name is required';
                  }
                  if (val.trim().length > 30) {
                    return 'Goal name is too long (max 30 chars)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _amountController,
                label: 'Target amount',
                hint: 'Enter target amount (₹)',
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                prefixIcon: Icons.currency_rupee_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Target amount is required';
                  }
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) {
                    return 'Enter a valid amount greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Icon Emoji Row
              Text(
                'Icon',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _emojiPresets.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final emoji = _emojiPresets[index];
                    final isSelected = emoji == _selectedEmoji;
                    return InkWell(
                      onTap: () => setState(() => _selectedEmoji = emoji),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withAlpha(40)
                              : (isDark ? AppColors.darkCard : AppColors.lightCard),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Date Selector
              Text(
                'Target Date (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('MMMM dd, yyyy').format(_selectedDate!)
                              : 'No target date selected',
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedDate != null
                                ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ),
                      if (_selectedDate != null)
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(() => _selectedDate = null),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              AppButton(
                text: 'Create Goal',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
