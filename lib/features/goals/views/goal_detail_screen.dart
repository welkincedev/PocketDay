// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: goal_detail_screen.dart
//
// Purpose:
// Detailed view screen for a target financial goal, displaying target progress, remaining balance, and activity history.
//
// Responsibilities:
// - Render goal header metrics (saved amount in ₹, target amount, progress bar, percentage, target date).
// - Display list of goal-linked transactions (`goalTransactions`).
// - Trigger edit goal sheet (`EditGoalSheet`), contribution sheet (`AddToGoalSheet`), or confirm delete.
//
// Data Flow:
// GoalsScreen → GoalDetailScreen → AddToGoalSheet / EditGoalSheet → goalsProvider
//
// Important Rules:
// - All goal-linked transactions count positively (`+₹`) toward goal progress.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/goal_model.dart';
import '../providers/goals_provider.dart';
import '../widgets/add_to_goal_sheet.dart';
import '../widgets/edit_goal_sheet.dart';
import '../../transactions/widgets/transaction_detail_bottom_sheet.dart';

class GoalDetailScreen extends ConsumerWidget {
  final GoalModel goal;

  const GoalDetailScreen({super.key, required this.goal});

  void _openAddMoneySheet(BuildContext context, double currentAmount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddToGoalSheet(goal: goal, currentAmount: currentAmount),
    );
  }

  void _openEditSheet(BuildContext context, GoalModel currentGoal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditGoalSheet(goal: currentGoal),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        title: const Text('Delete Goal?'),
        content: const Text(
          'This will remove the Goal, but your regular transactions will remain in PocketDay. Any linked transactions will keep their transaction history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(goalsProvider.notifier).deleteGoal(goal.id);
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close detail screen
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(goalsProvider);

    // Find fresh version of this goal in case it was updated
    final currentGoal = state.goals.where((g) => g.id == goal.id).isNotEmpty
        ? state.goals.firstWhere((g) => g.id == goal.id)
        : goal;

    final transactions = state.transactions;
    final goalTransactions =
        transactions.where((t) => t.goalId == currentGoal.id).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final currentAmount = currentGoal.calculateCurrentAmount(transactions);
    final remainingAmount = currentGoal.calculateRemainingAmount(currentAmount);
    final progressVal = currentGoal.calculateProgress(currentAmount);
    final percentVal = currentGoal.calculatePercentage(currentAmount);
    final isCompleted = currentGoal.isGoalCompleted(currentAmount);
    final isAboveTarget = currentAmount > currentGoal.targetAmount;

    final stateColor = isCompleted
        ? AppColors.primary
        : (progressVal >= 0.8 ? Colors.orange : AppColors.primary);

    // Status text for accessibility
    String statusLabel;
    if (isAboveTarget) {
      statusLabel = 'Above target';
    } else if (isCompleted) {
      statusLabel = 'Goal reached';
    } else if (progressVal >= 0.8) {
      statusLabel = 'Almost there';
    } else {
      statusLabel = 'On track';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentGoal.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Goal',
            onPressed: () => _openEditSheet(context, currentGoal),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete Goal',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Header Block ───
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: stateColor.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          currentGoal.emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CurrencyFormatter.format(currentAmount),
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'of ${CurrencyFormatter.format(currentGoal.targetAmount)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ─── Progress Bar ───
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 10,
                      child: LinearProgressIndicator(
                        value: progressVal,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(stateColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ─── Metrics Row ───
                  Row(
                    children: [
                      Expanded(
                        child: _MetricChip(
                          label: 'Progress',
                          value: '${percentVal.toStringAsFixed(0)}%',
                          color: stateColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricChip(
                          label: isAboveTarget ? 'Above target' : 'Remaining',
                          value: CurrencyFormatter.format(
                            isAboveTarget
                                ? currentAmount - currentGoal.targetAmount
                                : remainingAmount,
                          ),
                          color: isAboveTarget ? Colors.orange : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricChip(
                          label: 'Status',
                          value: statusLabel,
                          color: stateColor,
                        ),
                      ),
                    ],
                  ),

                  // ─── Target date ───
                  if (currentGoal.targetDate != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withAlpha(80),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Target: ${DateFormat('MMMM yyyy').format(currentGoal.targetDate!)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          if (!isCompleted) ...[
                            const SizedBox(width: 6),
                            Builder(
                              builder: (context) {
                                final diff = currentGoal.targetDate!.difference(
                                  DateTime.now(),
                                );
                                final months = (diff.inDays / 30).ceil();
                                String timeLeft = diff.isNegative
                                    ? '(past due)'
                                    : '$months months left';
                                if (!diff.isNegative && months <= 0) {
                                  timeLeft = '${diff.inDays} days left';
                                }
                                return Text(
                                  '• $timeLeft',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: diff.isNegative
                                        ? AppColors.expense
                                        : AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ─── Add Money Button ───
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          _openAddMoneySheet(context, currentAmount),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add money'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ─── Goal Activity Header ───
                  Text(
                    'Goal Activity',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ─── Activity List ───
          if (goalTransactions.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.timeline_rounded,
                      size: 40,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No activity yet.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start adding money toward this Goal.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final txn = goalTransactions[index];
                final isContribution = txn.categoryId == 'goal_contribution';
                // In goal context, ALL linked transactions are positive progress
                const sign = '+';
                const amountColor = AppColors.income;
                final iconData = isContribution
                    ? Icons.add_circle_outline_rounded
                    : Icons.shopping_bag_rounded;
                final subtitle = isContribution
                    ? 'Added to Goal'
                    : 'Goal progress';

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) =>
                            TransactionDetailBottomSheet(transaction: txn),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: amountColor.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(iconData, size: 18, color: amountColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  txn.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${DateFormat('MMM d').format(txn.date)} · $subtitle',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$sign ${CurrencyFormatter.format(txn.amount)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'monospace',
                              color: amountColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }, childCount: goalTransactions.length),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MetricChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color:
                  color ??
                  (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
