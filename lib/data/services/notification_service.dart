// ============================================================
// PocketDay — NotificationService
// ============================================================
//
// Purpose:
// Low-level wrapper service for flutter_local_notifications and timezone
// scheduling. Handles channel setup, permissions, daily reminders, and alert popups.
//
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Stable notification IDs
  static const int dailySpendingReminderId = 101;
  static const int budgetAlertId = 102;
  static const int goalReminderId = 103;

  // Channel IDs
  static const String dailyChannelId = 'daily_reminder_channel';
  static const String budgetChannelId = 'budget_alert_channel';
  static const String goalChannelId = 'goal_reminder_channel';

  /// Initialize local notification plugin, timezones, and Android notification channels.
  Future<bool> init() async {
    if (_isInitialized) return true;

    try {
      // 1. Initialize timezone database & local location
      tz.initializeTimeZones();
      try {
        final String timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        try {
          tz.setLocalLocation(tz.getLocation('UTC'));
        } catch (_) {}
      }

      // 2. Android & iOS initialization settings
      const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInitSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: iosInitSettings,
      );

      final initialized = await _notificationsPlugin.initialize(initSettings);

      // 3. Create Android notification channels
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            dailyChannelId,
            'Daily Reminders',
            description: 'Daily spending reminder notifications',
            importance: Importance.high,
          ),
        );

        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            budgetChannelId,
            'Budget Alerts',
            description: 'Budget threshold notifications',
            importance: Importance.high,
          ),
        );

        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            goalChannelId,
            'Goal Reminders',
            description: 'Savings goal milestone notifications',
            importance: Importance.high,
          ),
        );
      }

      _isInitialized = initialized ?? true;
      return _isInitialized;
    } catch (_) {
      return false;
    }
  }

  /// Request runtime permissions on Android 13+ and iOS.
  Future<bool> requestPermissions() async {
    try {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      bool granted = false;
      if (androidImplementation != null) {
        final notificationPermission =
            await androidImplementation.requestNotificationsPermission();
        final exactAlarmPermission =
            await androidImplementation.requestExactAlarmsPermission();
        granted = (notificationPermission ?? false) && (exactAlarmPermission ?? true);
      }

      final iosImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        final iosGranted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = granted || (iosGranted ?? false);
      }

      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Schedule a daily recurring spending reminder at the target [hour] and [minute].
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) await init();

    try {
      await cancelNotification(dailySpendingReminderId);

      final scheduledTime = _nextInstanceOfTime(hour, minute);

      const androidDetails = AndroidNotificationDetails(
        dailyChannelId,
        'Daily Reminders',
        channelDescription: 'Daily spending reminder notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.zonedSchedule(
        dailySpendingReminderId,
        'PocketDay',
        "Take a moment to check today's spending.",
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  /// Show an immediate budget alert notification when a category budget exceeds a threshold.
  Future<void> showBudgetAlert({
    required String categoryName,
    required int percentageUsed,
  }) async {
    if (!_isInitialized) await init();

    try {
      const androidDetails = AndroidNotificationDetails(
        budgetChannelId,
        'Budget Alerts',
        channelDescription: 'Budget threshold notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(
        budgetAlertId,
        'Budget Update',
        "You've used $percentageUsed% of your $categoryName budget.",
        notificationDetails,
      );
    } catch (_) {}
  }

  /// Show an immediate goal progress reminder notification.
  Future<void> showGoalReminder({required String goalName}) async {
    if (!_isInitialized) await init();

    try {
      const androidDetails = AndroidNotificationDetails(
        goalChannelId,
        'Goal Reminders',
        channelDescription: 'Savings goal milestone notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(
        goalReminderId,
        'Savings Goal',
        "You're getting closer to your $goalName savings goal.",
        notificationDetails,
      );
    } catch (_) {}
  }

  /// Cancel a specific notification by ID.
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (_) {}
  }

  /// Cancel all scheduled notifications for PocketDay.
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (_) {}
  }

  /// Computes the next occurrence of [hour]:[minute] in local timezone.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    tz.Location location;
    try {
      location = tz.local;
    } catch (_) {
      location = tz.UTC;
    }
    final tz.TZDateTime now = tz.TZDateTime.now(location);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
