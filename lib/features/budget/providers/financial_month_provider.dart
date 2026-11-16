// ============================================================
// PocketDay — FinancialMonthProvider
// ============================================================
//
// Purpose:
// State management and persistence for the Custom Financial Month feature.
// Enables users to define a pay-cycle-based budgeting month (e.g. 10th to 9th)
// and persists preferences across app restarts via SharedPreferences.
//
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/financial_period.dart';

class FinancialMonthState {
  final bool isCustomEnabled;
  final int startDay; // 1 to 31
  final bool isInitialized;

  const FinancialMonthState({
    this.isCustomEnabled = false,
    this.startDay = 1,
    this.isInitialized = false,
  });

  /// The active financial period containing the current instant in time.
  FinancialPeriod get currentPeriod => FinancialPeriod.fromDateTime(
        DateTime.now(),
        startDay: startDay,
        isCustom: isCustomEnabled,
      );

  /// Computes the financial period containing the specified [date].
  FinancialPeriod periodForDate(DateTime date) =>
      FinancialPeriod.fromDateTime(
        date,
        startDay: startDay,
        isCustom: isCustomEnabled,
      );

  /// Computes the financial period for a given [year] and [month] cycle.
  FinancialPeriod periodForCycle(int year, int month) =>
      FinancialPeriod.fromCycle(
        year,
        month,
        startDay: startDay,
        isCustom: isCustomEnabled,
      );

  FinancialMonthState copyWith({
    bool? isCustomEnabled,
    int? startDay,
    bool? isInitialized,
  }) {
    return FinancialMonthState(
      isCustomEnabled: isCustomEnabled ?? this.isCustomEnabled,
      startDay: startDay ?? this.startDay,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FinancialMonthState &&
        other.isCustomEnabled == isCustomEnabled &&
        other.startDay == startDay &&
        other.isInitialized == isInitialized;
  }

  @override
  int get hashCode => Object.hash(isCustomEnabled, startDay, isInitialized);
}

final financialMonthProvider =
    StateNotifierProvider<FinancialMonthNotifier, FinancialMonthState>((ref) {
  return FinancialMonthNotifier();
});

class FinancialMonthNotifier extends StateNotifier<FinancialMonthState> {
  static const String _keyCustomEnabled = 'financial_month_custom_enabled';
  static const String _keyStartDay = 'financial_month_start_day';

  FinancialMonthNotifier() : super(const FinancialMonthState()) {
    init();
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_keyCustomEnabled) ?? false;
      final startDay = prefs.getInt(_keyStartDay) ?? 1;

      state = FinancialMonthState(
        isCustomEnabled: enabled,
        startDay: (startDay >= 1 && startDay <= 31) ? startDay : 1,
        isInitialized: true,
      );
    } catch (_) {
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<void> setCustomEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyCustomEnabled, enabled);
    } catch (_) {}
    state = state.copyWith(isCustomEnabled: enabled);
  }

  Future<void> setStartDay(int day) async {
    final clamped = (day >= 1 && day <= 31) ? day : 1;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyStartDay, clamped);
    } catch (_) {}
    state = state.copyWith(startDay: clamped);
  }

  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCustomEnabled);
      await prefs.remove(_keyStartDay);
    } catch (_) {}
    state = const FinancialMonthState(
      isCustomEnabled: false,
      startDay: 1,
      isInitialized: true,
    );
  }
}
