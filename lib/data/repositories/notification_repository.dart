// ============================================================
// PocketDay — NotificationRepositoryImpl
// ============================================================
//
// Purpose:
// Repository managing persistent storage of notification preferences using SharedPreferences,
// and triggering NotificationService background scheduling / cancellation logic.
//
// Storage Keys:
// - notification_daily_reminder_enabled (bool, default false)
// - notification_daily_reminder_hour (int, default 21)
// - notification_daily_reminder_minute (int, default 0)
// - notification_budget_alerts_enabled (bool, default false)
// - notification_goal_reminders_enabled (bool, default false)
//
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl();
});

abstract class NotificationRepository {
  Future<void> init();
  bool getDailyReminderEnabled();
  int getDailyReminderHour();
  int getDailyReminderMinute();
  bool getBudgetAlertsEnabled();
  bool getGoalRemindersEnabled();

  Future<void> setDailyReminderEnabled(bool enabled);
  Future<void> setDailyReminderTime(int hour, int minute);
  Future<void> setBudgetAlertsEnabled(bool enabled);
  Future<void> setGoalRemindersEnabled(bool enabled);
  Future<void> resetNotificationPreferences();
}

class NotificationRepositoryImpl implements NotificationRepository {
  SharedPreferences? _prefs;
  final NotificationService _service = NotificationService.instance;

  static const String _keyDailyReminderEnabled = 'notification_daily_reminder_enabled';
  static const String _keyDailyReminderHour = 'notification_daily_reminder_hour';
  static const String _keyDailyReminderMinute = 'notification_daily_reminder_minute';
  static const String _keyBudgetAlertsEnabled = 'notification_budget_alerts_enabled';
  static const String _keyGoalRemindersEnabled = 'notification_goal_reminders_enabled';

  @override
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _service.init();
    } catch (_) {}
  }

  @override
  bool getDailyReminderEnabled() {
    return _prefs?.getBool(_keyDailyReminderEnabled) ?? false;
  }

  @override
  int getDailyReminderHour() {
    return _prefs?.getInt(_keyDailyReminderHour) ?? 21;
  }

  @override
  int getDailyReminderMinute() {
    return _prefs?.getInt(_keyDailyReminderMinute) ?? 0;
  }

  @override
  bool getBudgetAlertsEnabled() {
    return _prefs?.getBool(_keyBudgetAlertsEnabled) ?? false;
  }

  @override
  bool getGoalRemindersEnabled() {
    return _prefs?.getBool(_keyGoalRemindersEnabled) ?? false;
  }

  @override
  Future<void> setDailyReminderEnabled(bool enabled) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setBool(_keyDailyReminderEnabled, enabled);

    if (enabled) {
      final hour = getDailyReminderHour();
      final minute = getDailyReminderMinute();
      await _service.scheduleDailyReminder(hour: hour, minute: minute);
    } else {
      await _service.cancelNotification(NotificationService.dailySpendingReminderId);
    }
  }

  @override
  Future<void> setDailyReminderTime(int hour, int minute) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setInt(_keyDailyReminderHour, hour);
    await _prefs?.setInt(_keyDailyReminderMinute, minute);

    if (getDailyReminderEnabled()) {
      await _service.scheduleDailyReminder(hour: hour, minute: minute);
    }
  }

  @override
  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setBool(_keyBudgetAlertsEnabled, enabled);
  }

  @override
  Future<void> setGoalRemindersEnabled(bool enabled) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setBool(_keyGoalRemindersEnabled, enabled);
  }

  @override
  Future<void> resetNotificationPreferences() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_keyDailyReminderEnabled);
    await _prefs?.remove(_keyDailyReminderHour);
    await _prefs?.remove(_keyDailyReminderMinute);
    await _prefs?.remove(_keyBudgetAlertsEnabled);
    await _prefs?.remove(_keyGoalRemindersEnabled);

    await _service.cancelAllNotifications();
  }
}
