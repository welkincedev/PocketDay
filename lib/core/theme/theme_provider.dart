// ============================================================================
// PocketDay
// File: theme_provider.dart
// Purpose: Manages app theme preference (Light vs Dark mode).
// Architecture: Presentation / State Management Layer
// State Management: Riverpod
// Storage: In-Memory / Riverpod
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light);

  bool get isDarkMode => false;

  void toggleTheme() {
    // PocketDay is permanently Light Mode only.
    state = ThemeMode.light;
  }

  void setThemeMode(ThemeMode mode) {
    state = ThemeMode.light;
  }
}

