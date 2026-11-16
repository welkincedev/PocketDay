// ============================================================
// PocketDay — FinancialPeriod
// ============================================================
//
// Purpose:
// Centralized immutable model and calculator representing a budgeting cycle / financial period.
// Supports both standard calendar months and custom pay-cycle-based financial months
// (e.g. salary date on the 10th: Nov 10 – Dec 9).
//
// Responsibilities:
// - Determine start and end date boundaries for any given date or cycle.
// - Evaluate whether a transaction date belongs to this financial period.
// - Provide formatted display labels for UI headers, selectors, and previews.
// - Navigate sequentially between previous and next financial periods.
// - Handle edge cases: month length clamping, leap years, and year boundaries.
//
// ============================================================

import 'package:intl/intl.dart';

class FinancialPeriod {
  final DateTime startDate;
  final DateTime endDate;
  final int cycleYear;
  final int cycleMonth;
  final int startDay;
  final bool isCustom;

  const FinancialPeriod({
    required this.startDate,
    required this.endDate,
    required this.cycleYear,
    required this.cycleMonth,
    required this.startDay,
    required this.isCustom,
  });

  /// Standard 'yyyy-MM' key for matching monthly budget documents.
  String get cycleKey =>
      '${cycleYear.toString().padLeft(4, '0')}-${cycleMonth.toString().padLeft(2, '0')}';

  /// Named cycle representation, e.g. "November cycle".
  String get cycleName =>
      '${DateFormat('MMMM').format(DateTime(cycleYear, cycleMonth, 1))} cycle';

  /// Number of days in the specified year and month.
  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Evaluates whether a transaction [date] falls into this financial period (inclusive).
  bool contains(DateTime date) {
    return !date.isBefore(startDate) && !date.isAfter(endDate);
  }

  /// Creates a [FinancialPeriod] that contains the given [date].
  /// If [isCustom] is true and [startDay] > 1, computes the custom salary-cycle period.
  factory FinancialPeriod.fromDateTime(
    DateTime date, {
    int startDay = 1,
    bool isCustom = false,
  }) {
    final effectiveStartDay =
        (isCustom && startDay >= 1 && startDay <= 31) ? startDay : 1;
    final actuallyCustom = isCustom && effectiveStartDay > 1;

    if (!actuallyCustom) {
      final y = date.year;
      final m = date.month;
      final maxDays = daysInMonth(y, m);
      return FinancialPeriod(
        startDate: DateTime(y, m, 1, 0, 0, 0, 0, 0),
        endDate: DateTime(y, m, maxDays, 23, 59, 59, 999),
        cycleYear: y,
        cycleMonth: m,
        startDay: 1,
        isCustom: false,
      );
    }

    int cycleYear;
    int cycleMonth;

    if (date.day >= effectiveStartDay) {
      cycleYear = date.year;
      cycleMonth = date.month;
    } else {
      if (date.month == 1) {
        cycleYear = date.year - 1;
        cycleMonth = 12;
      } else {
        cycleYear = date.year;
        cycleMonth = date.month - 1;
      }
    }

    return FinancialPeriod.fromCycle(
      cycleYear,
      cycleMonth,
      startDay: effectiveStartDay,
      isCustom: true,
    );
  }

  /// Creates a [FinancialPeriod] anchored to a specific [year] and [month] cycle.
  factory FinancialPeriod.fromCycle(
    int year,
    int month, {
    int startDay = 1,
    bool isCustom = false,
  }) {
    final effectiveStartDay =
        (isCustom && startDay >= 1 && startDay <= 31) ? startDay : 1;
    final actuallyCustom = isCustom && effectiveStartDay > 1;

    if (!actuallyCustom) {
      final maxDays = daysInMonth(year, month);
      return FinancialPeriod(
        startDate: DateTime(year, month, 1, 0, 0, 0, 0, 0),
        endDate: DateTime(year, month, maxDays, 23, 59, 59, 999),
        cycleYear: year,
        cycleMonth: month,
        startDay: 1,
        isCustom: false,
      );
    }

    // Start date in cycle month (clamped if month has fewer days)
    final startClamped = effectiveStartDay.clamp(1, daysInMonth(year, month));
    final startDate = DateTime(year, month, startClamped, 0, 0, 0, 0, 0);

    // End date is 1ms before next cycle start
    final nextYear = month == 12 ? year + 1 : year;
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextClamped =
        effectiveStartDay.clamp(1, daysInMonth(nextYear, nextMonth));
    final nextCycleStart =
        DateTime(nextYear, nextMonth, nextClamped, 0, 0, 0, 0, 0);
    final endDate = nextCycleStart.subtract(const Duration(milliseconds: 1));

    return FinancialPeriod(
      startDate: startDate,
      endDate: endDate,
      cycleYear: year,
      cycleMonth: month,
      startDay: effectiveStartDay,
      isCustom: true,
    );
  }

  /// Returns the financial period immediately preceding this one.
  FinancialPeriod previousPeriod() {
    final prevYear = cycleMonth == 1 ? cycleYear - 1 : cycleYear;
    final prevMonth = cycleMonth == 1 ? 12 : cycleMonth - 1;
    return FinancialPeriod.fromCycle(
      prevYear,
      prevMonth,
      startDay: startDay,
      isCustom: isCustom,
    );
  }

  /// Returns the financial period immediately following this one.
  FinancialPeriod nextPeriod() {
    final nextYear = cycleMonth == 12 ? cycleYear + 1 : cycleYear;
    final nextMonth = cycleMonth == 12 ? 1 : cycleMonth + 1;
    return FinancialPeriod.fromCycle(
      nextYear,
      nextMonth,
      startDay: startDay,
      isCustom: isCustom,
    );
  }

  /// Standard display label for headers and selectors.
  /// Calendar: "November 2026"
  /// Custom: "Nov 10 – Dec 9, 2026" (or "Dec 10, 2026 – Jan 9, 2027")
  String get displayLabel {
    if (!isCustom || startDay == 1) {
      return DateFormat('MMMM yyyy').format(startDate);
    }

    if (startDate.year == endDate.year) {
      return '${DateFormat('MMM d').format(startDate)} – ${DateFormat('MMM d, yyyy').format(endDate)}';
    } else {
      return '${DateFormat('MMM d, yyyy').format(startDate)} – ${DateFormat('MMM d, yyyy').format(endDate)}';
    }
  }

  /// Full preview label for settings UI.
  /// E.g. "November 10, 2026 – December 9, 2026"
  String get previewLabel {
    if (!isCustom || startDay == 1) {
      return '${DateFormat('MMMM d, yyyy').format(startDate)} – ${DateFormat('MMMM d, yyyy').format(endDate)}';
    }

    if (startDate.year == endDate.year) {
      return '${DateFormat('MMMM d').format(startDate)} – ${DateFormat('MMMM d, yyyy').format(endDate)}';
    } else {
      return '${DateFormat('MMMM d, yyyy').format(startDate)} – ${DateFormat('MMMM d, yyyy').format(endDate)}';
    }
  }

  /// Short label for compact chips and tight layouts.
  /// E.g. "Nov 10 – Dec 9" or "Nov 2026"
  String get shortLabel {
    if (!isCustom || startDay == 1) {
      return DateFormat('MMM yyyy').format(startDate);
    }
    return '${DateFormat('MMM d').format(startDate)} – ${DateFormat('MMM d').format(endDate)}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FinancialPeriod &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.cycleYear == cycleYear &&
        other.cycleMonth == cycleMonth &&
        other.startDay == startDay &&
        other.isCustom == isCustom;
  }

  @override
  int get hashCode => Object.hash(
        startDate,
        endDate,
        cycleYear,
        cycleMonth,
        startDay,
        isCustom,
      );

  @override
  String toString() =>
      'FinancialPeriod($displayLabel, start: $startDate, end: $endDate, cycleKey: $cycleKey)';
}
