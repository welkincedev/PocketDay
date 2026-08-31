// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: theme_provider.dart
//
// Purpose:
// Riverpod StateNotifier managing the active app ThemeMode (Light vs Dark).
//
// Responsibilities:
// - Read initial ThemeMode from `HiveService.isDarkMode`.
// - Toggle between light and dark themes.
// - Persist updated theme preference to Hive via `HiveService.setDarkMode()`.
//
// Data Flow:
// User Toggle (ProfileScreen) → themeProvider.toggleTheme() → State Update → Hive Sync → PocketDayApp rebuilds
//
// Important Rules:
// - State must stay synchronized with Hive settings box.
//
// Main Operations:
// - toggleTheme(): Switch between ThemeMode.light and ThemeMode.dark
// - setThemeMode(mode): Set explicit theme mode & persist to Hive
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark);

  bool get isDarkMode => state == ThemeMode.dark;

  void toggleTheme() {
    state = (state == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}
