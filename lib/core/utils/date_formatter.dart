// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: date_formatter.dart
//
// Purpose:
// Centralized date and time formatting utilities for PocketDay.
//
// Responsibilities:
// - Format short dates (`Aug 31, 2026`).
// - Format full dates (`Monday, August 31, 2026`).
// - Format time (`2:30 PM`).
// - Format relative dates (`Today, 2:30 PM`, `Yesterday, 10:15 AM`).
// - Format month and year (`August 2026`).
//
// Data Flow:
// DateTime object → DateFormatter method → UI display
//
// Important Rules:
// - All date display formatting in views and list tiles should use DateFormatter.
//
// Main Operations:
// - formatShort(date)
// - formatFull(date)
// - formatTime(date)
// - formatRelative(date)
// - formatMonthYear(date)
// ============================================================

import 'package:intl/intl.dart';

class DateFormatter {
  static String formatShort(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatFull(DateTime date) {
    return DateFormat('EEEE, MMMM dd, yyyy').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return 'Today, ${formatTime(date)}';
    } else if (target == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${formatTime(date)}';
    } else {
      return '${formatShort(date)} • ${formatTime(date)}';
    }
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }
}
