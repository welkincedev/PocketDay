import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/goal_model.dart';
import '../providers/goals_provider.dart';

class EditGoalSheet extends ConsumerStatefulWidget {
  final GoalModel goal;

  const EditGoalSheet({super.key, required this.goal});

  @override
  ConsumerState<EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends ConsumerState<EditGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  DateTime? _selectedDate;
  late String _selectedEmoji;

  final List<String> _emojiPresets = ['🎯', '💰', '📱', '✈️', '🏠', '🚗', '🎓', '🛟', '🎁', '🏖️'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal.name);
    _amountController = TextEditingController(
      text: widget.goal.targetAmount.toStringAsFixed(0),
    );
    _selectedDate = widget.goal.targetDate;
    _selectedEmoji = widget.goal.emoji;
  }

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
    final updated = widget.goal.copyWith(
      name: _nameController.text.trim(),
      targetAmount: double.parse(_amountController.text.trim()),
      emoji: _selectedEmoji,
      targetDate: _selectedDate,
    );
    ref.read(goalsProvider.notifier).updateGoal(updated);
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
                'Edit Goal',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              AppTextField(
                controller: _nameController,
                label: 'Goal name',
                hint: 'e.g. Trip to Goa',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Goal name is required';
                  if (val.trim().length > 30) return 'Too long (max 30 chars)';
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
                  if (val == null || val.trim().isEmpty) return 'Target amount is required';
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) return 'Enter a valid positive amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Icon Selection
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
                  separatorBuilder: (_, i) => const SizedBox(width: 8),
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
                        child: Text(emoji, style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Target Date
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
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
                        GestureDetector(
                          onTap: () => setState(() => _selectedDate = null),
                          child: const Icon(Icons.clear_rounded, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              AppButton(text: 'Save Changes', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
