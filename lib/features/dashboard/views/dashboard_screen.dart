import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/transaction_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/add_transaction_bottom_sheet.dart';
import '../widgets/category_budget_progress_widget.dart';
import '../widgets/dashboard_card_widget.dart';
import '../widgets/dashboard_budget_progress_widget.dart';
import '../widgets/quick_actions_widget.dart';
import '../widgets/spending_chart_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _openAddTransactionModal(BuildContext context, WidgetRef ref, TransactionType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionBottomSheet(
        initialType: type,
        onAdd: (txn) {
          ref.read(dashboardProvider.notifier).addTransaction(txn);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(dashboardProvider.notifier).loadDashboardData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Welcome Header & Interactive Profile Avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${user?.displayName.split(' ').first ?? 'Alex'} 👋',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Here is your financial status today',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    // Interactive Profile Avatar
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary.withAlpha(40),
                          child: Text(
                            user?.displayName.isNotEmpty == true
                                ? user!.displayName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Hero Dashboard Balance Card
                if (dashboardState.isLoading) ...[
                  const SkeletonLoader(width: double.infinity, height: 190, borderRadius: 24),
                ] else ...[
                  DashboardCardWidget(
                    balance: dashboardState.totalBalance,
                    income: dashboardState.totalIncome,
                    expense: dashboardState.totalExpense,
                    budgetRemaining: dashboardState.remainingBudget,
                  ),
                ],
                const SizedBox(height: 20),
                const DashboardBudgetProgressWidget(),
                const SizedBox(height: 20),

                // Quick Actions Bar
                QuickActionsWidget(
                  onAddTransaction: (type) => _openAddTransactionModal(context, ref, type),
                ),
                const SizedBox(height: 24),

                // Spending Overview Chart
                if (!dashboardState.isLoading) ...[
                  SpendingChartWidget(
                    income: dashboardState.totalIncome,
                    expense: dashboardState.totalExpense,
                  ),
                  const SizedBox(height: 24),
                ],

                // Category Budget Progress Widget (Replaces redundant recent transactions)
                const CategoryBudgetProgressWidget(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
