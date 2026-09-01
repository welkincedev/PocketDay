// ============================================================
// PocketDay — SubscriptionsScreen
// ============================================================
//
// Purpose:
// Standalone route wrapper around SubscriptionsContent providing AppBar and Scaffold for direct route navigation.
//
// Responsibilities:
// - Wrap SubscriptionsContent inside Scaffold and AppBar when navigating via AppRoutes.subscriptions.
// - Render FloatingActionButton to add subscriptions when accessed directly as a standalone route.
//
// Data Flow:
// AppRoutes.subscriptions → SubscriptionsScreen → SubscriptionsContent → subscriptionProvider
//
// Navigation Flow:
// AppRoutes.subscriptions → SubscriptionsScreen → AddSubscriptionSheet
//
// Important Rules:
// - When accessed via main bottom navigation, Subscriptions is rendered directly inside BudgetScreen Tab 1 via SubscriptionsContent.
// - SubscriptionsScreen provides a clean standalone wrapper for direct route access.
//
// Main Operations:
// - build(context) — Renders Scaffold wrapping SubscriptionsContent.
//
// Dependencies / Collaborators:
// - SubscriptionsContent — Reusable recurring subscription view widget.
// - AddSubscriptionSheet — Modal bottom sheet for instantiating subscriptions.
//
// ============================================================

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/add_subscription_sheet.dart';
import '../widgets/subscriptions_content.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSubscriptionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        elevation: 0,
      ),
      body: const SafeArea(
        child: SubscriptionsContent(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_standalone_subscriptions',
        onPressed: () => _openAddSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Subscription'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
