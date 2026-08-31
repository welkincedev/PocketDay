// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: profile_screen.dart
//
// Purpose:
// User profile tab displaying user credentials, theme mode toggle, subscription tracker entry point, and logout.
//
// Responsibilities:
// - Render user avatar, name, and email from `authProvider`.
// - Toggle dark/light theme via `themeProvider`.
// - Navigate to Subscriptions screen (`AppRoutes.subscriptions`).
// - Prompt confirmation dialog before signing out and clearing session.
//
// Data Flow:
// authProvider + themeProvider → ProfileScreen → User Settings & Sign Out
//
// Important Rules:
// - Sign-out clears auth state and replaces router stack with `AppRoutes.login`.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/hive_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/routes/app_router.dart';

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
                    Container(
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

              // ─── RECURRING ────────────────────────────────────────────────
              _SectionLabel(label: 'RECURRING', isDark: isDark),
              _SettingsTile(
                icon: Icons.subscriptions_rounded,
                label: 'Subscriptions Tracker',
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.subscriptions),
              ),

              const _Divider(),

              // ─── APPEARANCE ───────────────────────────────────────────────
              _SectionLabel(label: 'APPEARANCE', isDark: isDark),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                secondary: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: AppColors.primary,
                ),
                title: Text('Dark Mode', style: textTheme.bodyLarge),
                value: isDark,
                activeThumbColor: AppColors.primary,
                onChanged: (_) =>
                    ref.read(themeProvider.notifier).toggleTheme(),
              ),

              const _Divider(),

              // ─── ABOUT ────────────────────────────────────────────────────
              _SectionLabel(label: 'ABOUT', isDark: isDark),
              _SettingsTile(
                icon: Icons.account_balance_wallet_rounded,
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

              // ─── DEVELOPER ────────────────────────────────────────────────
              _SectionLabel(label: 'DEVELOPER UTILITIES', isDark: isDark),
              _SettingsTile(
                icon: Icons.cleaning_services_rounded,
                label: 'Reset Financial Data',
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Reset Financial Data'),
                      content: const Text(
                        'This will clear all local transactions, budgets, goals, and subscriptions for a clean presentation test. Are you sure?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Reset',
                            style: TextStyle(color: AppColors.expense),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await HiveService.resetFinancialData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Local financial data reset to zero state.',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),

              const _Divider(),

              // ─── SIGN OUT ─────────────────────────────────────────────────
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
                          'Your data stays on this device. Are you sure you want to sign out?',
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

/// Labelled section heading (e.g. ACCOUNT, APPEARANCE).
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

/// A standard settings row with icon, label and optional trailing widget.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, color: AppColors.primary, size: 22),
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
