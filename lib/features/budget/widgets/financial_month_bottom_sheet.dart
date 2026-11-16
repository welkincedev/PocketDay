// ============================================================
// PocketDay — FinancialMonthBottomSheet
// ============================================================
//
// Purpose:
// Interactive settings sheet for configuring Custom Financial Month (pay cycle).
// Allows users to toggle custom cycle on/off, pick the salary start day (1 to 31),
// and inspect a live preview of their calculated financial period.
//
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../providers/financial_month_provider.dart';

class FinancialMonthBottomSheet extends ConsumerStatefulWidget {
  const FinancialMonthBottomSheet({super.key});

  @override
  ConsumerState<FinancialMonthBottomSheet> createState() =>
      _FinancialMonthBottomSheetState();
}

class _FinancialMonthBottomSheetState
    extends ConsumerState<FinancialMonthBottomSheet> {
  late bool _isCustom;
  late int _startDay;

  @override
  void initState() {
    super.initState();
    final finState = ref.read(financialMonthProvider);
    _isCustom = finState.isCustomEnabled;
    _startDay = finState.startDay;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final finState = ref.watch(financialMonthProvider);
    final notifier = ref.read(financialMonthProvider.notifier);

    // Compute preview dynamically with local temporary or saved values
    final previewPeriod = finState.periodForDate(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 20,
        left: 24,
        right: 24,
      ),
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Month',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Explanatory Subtitle
          Text(
            'Your financial month follows your salary or income date instead of the calendar month.',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Toggle Switch Tile
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custom Financial Month',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isCustom
                            ? 'Cycle starts on day $_startDay'
                            : 'Uses normal calendar month (1st – end)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isCustom,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _isCustom = val;
                    });
                    notifier.setCustomEnabled(val);
                  },
                ),
              ],
            ),
          ),

          if (_isCustom) ...[
            const SizedBox(height: 20),

            // Start Day Picker Section
            Text(
              'Select Start Day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Quick Selection Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [1, 5, 10, 15, 20, 25, 28].map((day) {
                final isSelected = _startDay == day;
                return ChoiceChip(
                  label: Text('Day $day'),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withAlpha(40),
                  backgroundColor: isDark
                      ? AppColors.darkBackground
                      : AppColors.lightBackground,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _startDay = day;
                    });
                    notifier.setStartDay(day);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Precise Slider
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _startDay.toDouble(),
                    min: 1,
                    max: 31,
                    divisions: 30,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      final day = val.round();
                      setState(() {
                        _startDay = day;
                      });
                      notifier.setStartDay(day);
                    },
                  ),
                ),
                Container(
                  width: 52,
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withAlpha(60)),
                  ),
                  child: Text(
                    '$_startDay',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            if (_startDay > 28) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'Note: In months with fewer days (like February), the cycle automatically adjusts to the last day of the month without altering your saved preference.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: 20),

          // Period Preview Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withAlpha(50),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.event_repeat_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Current Financial Period Preview',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  previewPeriod.previewLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isCustom && _startDay > 1
                      ? 'Transactions and budgets will group using this active cycle.'
                      : 'Standard calendar month grouping active.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Close button
          AppButton(
            text: 'Done',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
