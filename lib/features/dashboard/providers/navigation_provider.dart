// ============================================================
// PocketDay — navigationProvider
// ============================================================
//
// Purpose:
// Riverpod StateProvider tracking the active tab index in AppMainNavigationScreen.
//
// Responsibilities:
// - Hold selected bottom navigation bar index (0: Home/Dashboard, 1: Transactions, 2: Budget, 3: Goals, 4: Profile).
// - Notify AppMainNavigationScreen IndexedStack when active tab selection changes.
// - Allow programmatically switching tabs from quick action buttons or detail screens.
//
// Data Flow:
// NavigationBar / Quick Actions → navigationProvider.notifier.state = index → AppMainNavigationScreen (IndexedStack rebuilds active tab)
//
// Important Rules:
// - Default tab index is 0 (Dashboard).
// - Valid tab index range is 0 to 4.
//
// Dependencies / Collaborators:
// - AppMainNavigationScreen — Primary listener consuming tab index state.
//
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

final navigationProvider = StateProvider<int>((ref) {
  return 0;
});
