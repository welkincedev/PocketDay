// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: navigation_provider.dart
//
// Purpose:
// Riverpod StateProvider holding the active bottom navigation bar tab index.
//
// Responsibilities:
// - Expose active tab index (0: Dashboard, 1: Transactions, 2: Budget, 3: Goals).
//
// Data Flow:
// BottomNavigationBar → navigationProvider → MainShellScreen IndexedStack
//
// Important Rules:
// - Default tab index is 0 (Dashboard).
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

final navigationProvider = StateProvider<int>((ref) {
  return 0;
});
