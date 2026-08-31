// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: main_shell_screen.dart
//
// Purpose:
// Root tab shell view hosting the main bottom navigation bar and IndexedStack.
//
// Responsibilities:
// - Preserve state across tabs (Dashboard, Transactions, Budget, Goals, Profile) using IndexedStack.
// - Render Material 3 `NavigationBar` with selection highlights.
// - Listen to and update `navigationProvider`.
//
// Navigation Flow:
// MainShellScreen → [DashboardScreen | TransactionsScreen | BudgetScreen | GoalsScreen | ProfileScreen]
//
// Important Rules:
// - Uses IndexedStack to prevent screen destruction and rebuild lag when switching tabs.
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

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key});

  static const List<Widget> _pages = [
    DashboardScreen(),
    TransactionsScreen(),
    BudgetScreen(),
    GoalsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _pages),
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
