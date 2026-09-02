// ============================================================
// PocketDay — LoginScreen (Product Landing & Auth Entry Point)
// ============================================================
//
// Purpose:
// Primary product landing screen and single-click Google OAuth entry point for PocketDay.
//
// Responsibilities:
// - Render official PocketDay brand logo, value proposition, and clean landing page hierarchy.
// - Provide single-click "Continue with Google" authentication action.
// - Handle loading spinner state and suppress user-canceled OAuth dialog alerts cleanly.
// - Navigate authenticated users immediately to AppMainNavigationScreen ('/main') on success.
//
// Data Flow:
// User Tap "Continue with Google" → _handleGoogleLogin() → authProvider.notifier.loginWithGoogle() → Firebase Auth & Firestore Profile → AppMainNavigationScreen
//
// Navigation Flow:
// SplashScreen / OnboardingScreen → LoginScreen → AppMainNavigationScreen ('/main')
//
// Important Rules:
// - Uses replacement navigation (Navigator.pushReplacementNamed) so LoginScreen is popped off back-stack.
// - User-cancelled sign-in dialogs are caught gracefully and do not display error banners.
// - Disables button during active login request to prevent duplicate submissions.
//
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/pocketday_logo.dart';
import '../../../core/utils/app_error_handler.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  Future<void> _handleGoogleLogin() async {
    if (ref.read(authProvider).isLoading) return;
    final success = await ref.read(authProvider.notifier).loginWithGoogle();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),

                  // Brand Logo Mark
                  const Center(
                    child: PocketDayLogo(
                      size: PocketDayLogoSize.large,
                      showBackground: true,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // App Title & Tagline
                  Text(
                    AppStrings.appTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightTextPrimary,
                      letterSpacing: -0.5,
                      fontSize: 28,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.appTagline,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // Value Proposition Supporting Text
                  Text(
                    'Take control of your money.\nKnow where it goes. Know how long it lasts.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.lightTextSecondary,
                      height: 1.45,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Error Banner (ignoring user-initiated cancellations)
                  if (authState.hasError &&
                      AppErrorHandler.toAuthUserMessage(authState.error).isNotEmpty) ...[
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
                        AppErrorHandler.toAuthUserMessage(authState.error),
                        style: const TextStyle(
                          color: AppColors.expense,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Single-Click Google OAuth Action Button
                  AppButton(
                    text: AppStrings.continueWithGoogle,
                    variant: AppButtonVariant.google,
                    icon: Icons.g_mobiledata_rounded,
                    isLoading: authState.isLoading,
                    onPressed: authState.isLoading ? null : _handleGoogleLogin,
                  ),
                  const SizedBox(height: 48),

                  // Trust & Security Footnote
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Your money. Your control. • Secure Cloud Sync',
                        style: TextStyle(
                          color: AppColors.lightTextSecondary.withAlpha(160),
                          fontSize: 12,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
