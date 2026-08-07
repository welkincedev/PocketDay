import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hive_service.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(HiveService.isDarkMode ? ThemeMode.dark : ThemeMode.light);

  bool get isDarkMode => state == ThemeMode.dark;

  void toggleTheme() {
    if (state == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    HiveService.setDarkMode(mode == ThemeMode.dark);
  }
}

// Balance Visibility Provider
final hideBalanceProvider = StateNotifierProvider<HideBalanceNotifier, bool>((ref) {
  return HideBalanceNotifier();
});

class HideBalanceNotifier extends StateNotifier<bool> {
  HideBalanceNotifier() : super(HiveService.hideBalance);

  void toggle() {
    state = !state;
    HiveService.setHideBalance(state);
  }
}
