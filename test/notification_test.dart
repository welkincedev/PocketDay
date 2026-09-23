import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketday/data/repositories/notification_repository.dart';
import 'package:pocketday/features/profile/providers/notification_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notification System Unit Tests', () {
    late NotificationRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repository = NotificationRepositoryImpl();
      await repository.init();
    });

    test('Initial notification preferences return defaults', () {
      expect(repository.getDailyReminderEnabled(), false);
      expect(repository.getDailyReminderHour(), 21);
      expect(repository.getDailyReminderMinute(), 0);
      expect(repository.getBudgetAlertsEnabled(), false);
      expect(repository.getGoalRemindersEnabled(), false);
    });

    test('Setting daily reminder preference persists correctly', () async {
      await repository.setDailyReminderEnabled(true);
      await repository.setDailyReminderTime(20, 30);

      expect(repository.getDailyReminderEnabled(), true);
      expect(repository.getDailyReminderHour(), 20);
      expect(repository.getDailyReminderMinute(), 30);
    });

    test('Setting budget and goal alert preferences persists correctly', () async {
      await repository.setBudgetAlertsEnabled(true);
      await repository.setGoalRemindersEnabled(true);

      expect(repository.getBudgetAlertsEnabled(), true);
      expect(repository.getGoalRemindersEnabled(), true);
    });

    test('Resetting notification preferences clears storage back to defaults', () async {
      await repository.setDailyReminderEnabled(true);
      await repository.setDailyReminderTime(18, 15);
      await repository.setBudgetAlertsEnabled(true);
      await repository.setGoalRemindersEnabled(true);

      await repository.resetNotificationPreferences();

      expect(repository.getDailyReminderEnabled(), false);
      expect(repository.getDailyReminderHour(), 21);
      expect(repository.getDailyReminderMinute(), 0);
      expect(repository.getBudgetAlertsEnabled(), false);
      expect(repository.getGoalRemindersEnabled(), false);
    });

    test('NotificationNotifier state updates correctly', () async {
      final notifier = NotificationNotifier(repository);
      await notifier.init();

      expect(notifier.debugState.dailyReminderEnabled, false);
      expect(notifier.debugState.reminderTime, const TimeOfDay(hour: 21, minute: 0));

      await notifier.toggleDailyReminder(true);
      expect(notifier.debugState.dailyReminderEnabled, true);

      await notifier.setReminderTime(const TimeOfDay(hour: 20, minute: 45));
      expect(notifier.debugState.dailyReminderHour, 20);
      expect(notifier.debugState.dailyReminderMinute, 45);

      await notifier.toggleBudgetAlerts(true);
      expect(notifier.debugState.budgetAlertsEnabled, true);

      await notifier.toggleGoalReminders(true);
      expect(notifier.debugState.goalRemindersEnabled, true);

      await notifier.resetNotificationSettings();
      expect(notifier.debugState.dailyReminderEnabled, false);
      expect(notifier.debugState.dailyReminderHour, 21);
      expect(notifier.debugState.dailyReminderMinute, 0);
      expect(notifier.debugState.budgetAlertsEnabled, false);
      expect(notifier.debugState.goalRemindersEnabled, false);
    });
  });
}

extension NotificationNotifierTest on NotificationNotifier {
  NotificationState get debugState => state;
}
