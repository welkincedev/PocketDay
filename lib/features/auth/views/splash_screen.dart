// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: splash_screen.dart
//
// Purpose:
// Animated application splash screen performing initial session routing.
//
// Responsibilities:
// - Render animated PocketDay wallet logo and branding tagline.
// - Evaluate onboarding and session state via `HiveService.hasOnboarded` and `authProvider`.
// - Route user to OnboardingScreen (`/onboarding`), MainShellScreen (`/main`), or LoginScreen (`/login`).
//
// Navigation Flow:
// App Launch → SplashScreen → Route Decision (Onboarding / Main / Login)
//
// Important Rules:
// - Minimum splash display duration is 2000ms for branding presentation.
//
// Main Operations:
// - _navigate(): Determine target screen and perform pushReplacementNamed
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_router.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final user = ref.read(authProvider).value;

    if (user != null) {
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(40),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withAlpha(80),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                )
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                .fade(duration: 400.ms),
            const SizedBox(height: 24),
            Text(
                  AppStrings.appTitle,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                )
                .animate()
                .slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 200.ms)
                .fade(duration: 400.ms, delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              AppStrings.appTagline,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ).animate().fade(duration: 400.ms, delay: 400.ms),
          ],
        ),
      ),
    );
  }
}
