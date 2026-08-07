import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/transaction_item_tile.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navTransactions),
      ),
      body: dashboardState.recentTransactions.isEmpty
          ? const EmptyStateWidget(
              title: AppStrings.noTransactionsYet,
              description: 'Your transactions will be listed here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dashboardState.recentTransactions.length,
              itemBuilder: (context, index) {
                final txn = dashboardState.recentTransactions[index];
                return TransactionItemTile(transaction: txn);
              },
            ),
    );
  }
}
