// ============================================================
// PocketDay — NotificationProvider
// ============================================================
//
// Purpose:
// StateNotifier provider managing local notification settings state (Daily reminder toggle & time,
// budget alerts toggle, goal reminders toggle) and delegating persistent operations to NotificationRepository.
//
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/services/notification_service.dart';

class NotificationState {
  final bool dailyReminderEnabled;
  final int dailyReminderHour;
  final int dailyReminderMinute;
  final bool budgetAlertsEnabled;
  final bool goalRemindersEnabled;
  final bool isInitialized;

  NotificationState({
    this.dailyReminderEnabled = false,
    this.dailyReminderHour = 21,
    this.dailyReminderMinute = 0,
    this.budgetAlertsEnabled = false,
    this.goalRemindersEnabled = false,
    this.isInitialized = false,
  });

  TimeOfDay get reminderTime => TimeOfDay(
        hour: dailyReminderHour,
        minute: dailyReminderMinute,
      );

  NotificationState copyWith({
    bool? dailyReminderEnabled,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    bool? budgetAlertsEnabled,
    bool? goalRemindersEnabled,
    bool? isInitialized,
  }) {
    return NotificationState(
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      goalRemindersEnabled: goalRemindersEnabled ?? this.goalRemindersEnabled,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repo);
});

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repo;

  NotificationNotifier(this._repo) : super(NotificationState()) {
    init();
  }

  Future<void> init() async {
    await _repo.init();
    state = NotificationState(
      dailyReminderEnabled: _repo.getDailyReminderEnabled(),
      dailyReminderHour: _repo.getDailyReminderHour(),
      dailyReminderMinute: _repo.getDailyReminderMinute(),
      budgetAlertsEnabled: _repo.getBudgetAlertsEnabled(),
      goalRemindersEnabled: _repo.getGoalRemindersEnabled(),
      isInitialized: true,
    );
  }

  Future<void> toggleDailyReminder(bool enabled) async {
    await _repo.setDailyReminderEnabled(enabled);
    if (enabled) {
      await NotificationService.instance.requestPermissions();
    }
    state = state.copyWith(dailyReminderEnabled: enabled);
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    await _repo.setDailyReminderTime(time.hour, time.minute);
    state = state.copyWith(
      dailyReminderHour: time.hour,
      dailyReminderMinute: time.minute,
    );
  }

  Future<void> toggleBudgetAlerts(bool enabled) async {
    await _repo.setBudgetAlertsEnabled(enabled);
    if (enabled) {
      await NotificationService.instance.requestPermissions();
    }
    state = state.copyWith(budgetAlertsEnabled: enabled);
  }

  Future<void> toggleGoalReminders(bool enabled) async {
    await _repo.setGoalRemindersEnabled(enabled);
    if (enabled) {
      await NotificationService.instance.requestPermissions();
    }
    state = state.copyWith(goalRemindersEnabled: enabled);
  }

  Future<void> resetNotificationSettings() async {
    await _repo.resetNotificationPreferences();
    state = NotificationState(isInitialized: true);
  }
}
