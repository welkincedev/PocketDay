// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: login_screen.dart
//
// Purpose:
// Single, streamlined Google Authentication screen for PocketDay.
//
// Responsibilities:
// - Present PocketDay branding and single-click "Continue with Google" action.
// - Dispatch Google login requests to `authProvider.notifier.loginWithGoogle()`.
// - Handle loading state and user cancellations gracefully.
// - Navigate to MainShellScreen upon successful authentication.
//
// Navigation Flow:
// LoginScreen → MainShellScreen (`/main`)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  void _handleGoogleLogin() async {
    final success = await ref.read(authProvider.notifier).loginWithGoogle();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Brand Icon Container
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withAlpha(60),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 56,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Welcome Headline
                  Text(
                    'PocketDay',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your personal money manager',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Track spending, set budgets, and achieve financial goals with real-time cloud backup.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary.withAlpha(180)
                          : AppColors.lightTextSecondary.withAlpha(180),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Error Banner (ignoring user-initiated cancellations)
                  if (authState.hasError &&
                      !authState.error.toString().contains('cancelled')) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.expense.withAlpha(50),
                        ),
                      ),
                      child: Text(
                        authState.error.toString().replaceAll(
                          'Exception: ',
                          '',
                        ),
                        style: const TextStyle(
                          color: AppColors.expense,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Google Sign-In Primary Action Button
                  AppButton(
                    text: AppStrings.continueWithGoogle,
                    variant: AppButtonVariant.google,
                    icon: Icons.g_mobiledata_rounded,
                    isLoading: authState.isLoading,
                    onPressed: authState.isLoading ? null : _handleGoogleLogin,
                  ),
                  const SizedBox(height: 48),

                  // Footer Tagline
                  Text(
                    'Your money. Your control.',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary.withAlpha(120)
                          : AppColors.lightTextSecondary.withAlpha(120),
                      fontSize: 12,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
