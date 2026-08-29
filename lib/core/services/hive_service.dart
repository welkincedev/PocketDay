import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

/// Centralises all Hive initialisation and box access for PocketDay.
///
/// The app initialises Hive once in [main] (or via [init]) and then reads
/// persisted settings through the static getters here. UI and providers
/// should never open Hive boxes directly.
class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();

    // Open necessary boxes
    await Hive.openBox(AppConstants.settingsBox);
    await Hive.openBox(AppConstants.userBox);
    await Hive.openBox(AppConstants.transactionsBox);
    await Hive.openBox(AppConstants.budgetBox);
    await Hive.openBox(AppConstants.goalsBox);
    await Hive.openBox(AppConstants.subscriptionsBox);
    await Hive.openBox(AppConstants.processedAutoExpensesBox);
  }

  // Getters for boxes
  static Box get settingsBox => Hive.box(AppConstants.settingsBox);
  static Box get userBox => Hive.box(AppConstants.userBox);
  static Box get transactionsBox => Hive.box(AppConstants.transactionsBox);
  static Box get budgetBox => Hive.box(AppConstants.budgetBox);
  static Box get goalsBox => Hive.box(AppConstants.goalsBox);
  static Box get subscriptionsBox => Hive.box(AppConstants.subscriptionsBox);
  static Box get processedAutoExpensesBox =>
      Hive.box(AppConstants.processedAutoExpensesBox);

  // Quick settings methods
  static bool get isDarkMode =>
      settingsBox.get(AppConstants.keyIsDarkMode, defaultValue: false);
  static Future<void> setDarkMode(bool value) async =>
      await settingsBox.put(AppConstants.keyIsDarkMode, value);

  static bool get hasOnboarded =>
      settingsBox.get(AppConstants.keyHasOnboarded, defaultValue: false);
  static Future<void> setHasOnboarded(bool value) async =>
      await settingsBox.put(AppConstants.keyHasOnboarded, value);
}
