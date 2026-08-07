import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

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
  }

  // Getters for boxes
  static Box get settingsBox => Hive.box(AppConstants.settingsBox);
  static Box get userBox => Hive.box(AppConstants.userBox);
  static Box get transactionsBox => Hive.box(AppConstants.transactionsBox);
  static Box get budgetBox => Hive.box(AppConstants.budgetBox);
  static Box get goalsBox => Hive.box(AppConstants.goalsBox);
  static Box get subscriptionsBox => Hive.box(AppConstants.subscriptionsBox);

  // Quick settings methods
  static bool get isDarkMode => settingsBox.get(AppConstants.keyIsDarkMode, defaultValue: false);
  static Future<void> setDarkMode(bool value) async => await settingsBox.put(AppConstants.keyIsDarkMode, value);

  static bool get hideBalance => settingsBox.get(AppConstants.keyHideBalance, defaultValue: false);
  static Future<void> setHideBalance(bool value) async => await settingsBox.put(AppConstants.keyHideBalance, value);

  static bool get hasOnboarded => settingsBox.get(AppConstants.keyHasOnboarded, defaultValue: false);
  static Future<void> setHasOnboarded(bool value) async => await settingsBox.put(AppConstants.keyHasOnboarded, value);
}
