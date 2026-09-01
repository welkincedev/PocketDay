// ============================================================
// PocketDay — ProfileScreen
// ============================================================
//
// Purpose:
// User account profile tab displaying authenticated user details, appearance settings,
// subscription tracker navigation, and data management options (Reset App Data & Delete Account).
//
// Responsibilities:
// - Render authenticated user avatar, display name, and email from authProvider.
// - Toggle app theme (Light vs Dark mode) via themeProvider.
// - Navigate to SubscriptionsScreen ('/subscriptions').
// - Execute Reset App Data flow with user confirmation (wiping financial subcollections while keeping account).
// - Execute Delete Account flow with user confirmation (wiping all Firestore data and Firebase Auth user).
// - Execute Sign Out flow with user confirmation (ending current session and routing to LoginScreen).
//
// Data Flow:
// authProvider & themeProvider → ProfileScreen UI → User Actions (Theme Toggle / Navigation / Reset / Delete / Logout) → AuthNotifier & Repositories
//
// Navigation Flow:
// AppMainNavigationScreen Tab 4 → ProfileScreen → SubscriptionsScreen ('/subscriptions') OR LoginScreen ('/login')
//
// Important Rules:
// - Reset App Data: Deletes user financial subcollections in 400-doc batches but PRESERVES the Firebase Auth user identity.
// - Delete Account: Deletes all user subcollections, root user document, AND permanently deletes the Firebase Auth account before routing to LoginScreen.
// - Sign Out: Ends active authentication session without modifying cloud data and replaces route stack with LoginScreen.
//
// Main Operations:
// - build(context, ref) — Renders user identity, theme switcher, settings tiles, and data action dialogs.
//
// Dependencies / Collaborators:
// - authProvider — Riverpod provider supplying user model and authentication actions.
// - themeProvider — Riverpod provider managing Light/Dark mode state.
// - transactionsProvider / budgetProvider / goalsProvider — Feature providers reloaded after data reset.
//
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../../goals/providers/goals_provider.dart';
import '../../budget/providers/budget_provider.dart';
import '../../../core/routes/app_router.dart';

import '../../../core/widgets/pocketday_logo.dart';

/// The Profile tab. Shows user account info, appearance settings,
/// app metadata, and sign-out. Only displays functionality that actually exists.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final textTheme = Theme.of(context).textTheme;

    final firstName = user?.displayName.split(' ').first ?? 'User';
    final initial = user?.displayName.isNotEmpty == true
        ? user!.displayName[0].toUpperCase()
        : 'U';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Avatar Header ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                        ? CircleAvatar(
                            radius: 36,
                            backgroundImage: NetworkImage(user.photoUrl!),
                            backgroundColor: AppColors.primary.withAlpha(30),
                          )
                        : Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withAlpha(30),
                              border: Border.all(
                                color: AppColors.primary.withAlpha(80),
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                    const SizedBox(height: 14),
                    Text(
                      user?.displayName ?? firstName,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // ─── ACCOUNT ─────────────────────────────────────────────────
              _SectionLabel(label: 'ACCOUNT', isDark: isDark),
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                label: 'Name',
                trailing: Text(
                  user?.displayName ?? '—',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.email_outlined,
                label: 'Email',
                trailing: Text(
                  user?.email ?? '—',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const _Divider(),

              // ─── ABOUT ────────────────────────────────────────────────────

              _SectionLabel(label: 'ABOUT', isDark: isDark),
              _SettingsTile(
                customLeading: const PocketDayLogo(size: PocketDayLogoSize.small),
                label: 'PocketDay',
                trailing: Text(
                  'Personal Money Manager',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: 'Version',
                trailing: Text(
                  '1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              const _Divider(),
              _SectionLabel(label: 'DATA MANAGEMENT', isDark: isDark),
              _SettingsTile(
                icon: Icons.cleaning_services_rounded,
                label: 'Reset App Data',
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Reset App Data'),
                      content: const Text(
                        'This will permanently delete all your transactions, budgets, goals, and subscriptions from Cloud Firestore. Your Google login remains active. Are you sure?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Reset Data',
                            style: TextStyle(color: AppColors.expense),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Resetting cloud app data...')),
                    );
                    try {
                      await ref.read(authProvider.notifier).resetAppData();
                      await ref.read(transactionsProvider.notifier).loadTransactions();
                      await ref.read(goalsProvider.notifier).loadGoals();
                      await ref.read(budgetProvider.notifier).loadBudgets();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'All financial app data was successfully reset.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to reset app data: $e'),
                            backgroundColor: AppColors.expense,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
              _SettingsTile(
                icon: Icons.delete_forever_rounded,
                label: 'Delete Account',
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Account'),
                      content: const Text(
                        'This will permanently delete all your data and user account profile. Are you sure?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Delete Account',
                            style: TextStyle(color: AppColors.expense),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    try {
                      await ref.read(authProvider.notifier).deleteAccount();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.login,
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Account deletion failed: $e'),
                            backgroundColor: AppColors.expense,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
              const _Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: TextButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text(
                          'Your data remains safely stored in your cloud account. Are you sure you want to sign out?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Sign Out',
                              style: TextStyle(color: AppColors.expense),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.login,
                          (route) => false,
                        );
                      }
                    }
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.expense,
                  ),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.expense,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 14,
                    ),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.4,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Widget? customLeading;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    this.icon,
    this.customLeading,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: customLeading ?? (icon != null ? Icon(icon, color: AppColors.primary, size: 22) : null),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: trailing,
      onTap: onTap,
    );
  }
}


/// Subtle section divider.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 24, indent: 20, endIndent: 20);
  }
}
