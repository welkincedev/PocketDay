// ============================================================
// PocketDay — AppMainNavigationScreen
// ============================================================
//
// Purpose:
// Primary tab navigation shell for authenticated PocketDay users.
// Hosts the root bottom NavigationBar and lazy IndexedStack layout.
//
// Responsibilities:
// - Preserve screen state across visited tabs (Dashboard, Transactions, Budget, Goals, Profile) using IndexedStack.
// - Lazily instantiate feature tabs on demand: Home (DashboardScreen) mounts on startup; other tabs mount only when selected.
// - Eliminate 5-screen concurrent provider loading bottleneck on application startup.
// - Render Material 3 NavigationBar with selected icon highlights and labels.
// - Listen to and update navigationProvider state.
//
// Data Flow:
// User Bottom Nav Selection → NavigationBar.onDestinationSelected → navigationProvider (Riverpod) → Lazy IndexedStack active tab update
//
// Navigation Flow:
// SplashScreen / LoginScreen → AppMainNavigationScreen → [DashboardScreen (Home) | Lazy Tabs]
//
// Important Rules:
// - Home tab (index 0) MUST build first on startup.
// - Other tabs are instantiated lazily upon first tap and kept alive once visited.
// - Does not perform direct network or Firestore calls; delegates data loading to feature view providers.
//
// Main Operations:
// - build(context, ref) — Watches navigationProvider index and renders active tab with bottom NavigationBar.
//
// Dependencies / Collaborators:
// - navigationProvider — Riverpod provider owning current tab index.
// - DashboardScreen — Primary overview tab.
// - TransactionsScreen — Financial transaction history tab.
// - BudgetScreen — Monthly overall & category budget tracking tab.
// - GoalsScreen — Savings goals & progress tracking tab.
// - ProfileScreen — User account identity & settings tab.
//
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../budget/views/budget_screen.dart';
import '../../goals/views/savings_goals_screen.dart';
import '../../profile/views/profile_screen.dart';
import '../../transactions/views/transactions_screen.dart';
import '../providers/navigation_provider.dart';
import 'dashboard_screen.dart';

class AppMainNavigationScreen extends ConsumerStatefulWidget {
  const AppMainNavigationScreen({super.key});

  @override
  ConsumerState<AppMainNavigationScreen> createState() =>
      _AppMainNavigationScreenState();
}

class _AppMainNavigationScreenState
    extends ConsumerState<AppMainNavigationScreen> {
  final Set<int> _visitedIndices = {0};

  static const List<Widget> _pages = [
    DashboardScreen(),
    TransactionsScreen(),
    BudgetScreen(),
    GoalsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);

    // Track visited tab indices so tabs build lazily upon first selection
    if (!_visitedIndices.contains(currentIndex)) {
      _visitedIndices.add(currentIndex);
    }

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: List.generate(_pages.length, (index) {
          if (_visitedIndices.contains(index)) {
            return _pages[index];
          }
          return const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (index) {
          ref.read(navigationProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: AppStrings.navHome,
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: AppStrings.navTransactions,
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded),
            label: AppStrings.navBudget,
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings_rounded),
            label: AppStrings.navGoals,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: AppStrings.navProfile,
          ),
        ],
      ),
    );
  }
}
