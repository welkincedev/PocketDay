// ============================================================
// PocketDay — SplashScreen
// ============================================================
//
// Purpose:
// Application startup and session resolution screen responsible for rendering
// official PocketDay branding immediately on frame 1 before resolving user authentication state.
//
// Responsibilities:
// - Render PocketDay brand logo (PocketDayLogo) immediately on frame 1 before session evaluation.
// - Resolve auth state using WidgetsBinding.instance.addPostFrameCallback so splash UI is painted first.
// - Inspect local FirebaseAuth.instance.currentUser token without blocking on Firestore network calls.
// - Route authenticated users to AppMainNavigationScreen ('/main') and unauthenticated users to LoginScreen ('/login').
// - Eliminate black screen startup artifacts completely with a 3-second branded presentation window.
//
// Data Flow:
// Native launch → Flutter engine → Splash UI painted (Frame 1) → checkCurrentUser() → Route (/main OR /login)
//
// Navigation Flow:
// App Launch → SplashScreen → Frame 1 Render → Authentication Resolution → LoginScreen OR AppMainNavigationScreen
//
// Important Rules:
// - Must paint splash UI to screen GPU buffer before triggering navigation.
// - Authentication decision evaluates local cached user token (`currentUser != null`), never blocking on Firestore profile calls.
// - Uses replacement navigation (Navigator.pushReplacementNamed) so SplashScreen is popped cleanly.
//
// Main Operations:
// - initState() — Registers post-frame callback to trigger _navigate() after frame 1 render.
// - _navigate() — Inspects local auth token and selects target route.
//
// Dependencies / Collaborators:
// - authProvider — Riverpod provider containing active user auth model state.
// - PocketDayLogo — Standardized brand logo component.
// - AppMainNavigationScreen — Main navigation shell destination for authenticated users.
// - LoginScreen — Authentication screen destination for unauthenticated users.
//
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/widgets/pocketday_logo.dart';
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
    // Schedule navigation after Frame 1 has painted PocketDay splash branding to GPU buffer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigate();
    });
  }

  Future<void> _navigate() async {
    // Run the 3-second branded splash window and lightweight startup checks concurrently.
    // Navigation fires exactly once, at whichever completes last (typically the 3s timer).
    bool hasCompletedOnboarding = false;

    await Future.wait([
      // Branch A — 3-second branded splash presentation window
      Future.delayed(const Duration(seconds: 3)),

      // Branch B — lightweight local startup checks (SharedPreferences + cached Firebase token)
      () async {
        try {
          final prefs = await SharedPreferences.getInstance();
          hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;
        } catch (_) {}

        // Only resolve cached auth token if onboarding is complete (avoids unnecessary work on first install)
        if (hasCompletedOnboarding) {
          await ref.read(authProvider.notifier).checkCurrentUser();
        }
      }(),
    ]);

    if (!mounted) return;

    if (!hasCompletedOnboarding) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      return;
    }

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
      backgroundColor: AppColors.lightBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PocketDayLogo(
                  size: PocketDayLogoSize.large,
                  showBackground: true,
                )
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                .fade(duration: 400.ms),
            const SizedBox(height: 24),
            Text(
                  AppStrings.appTitle,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.lightTextPrimary,
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
                color: AppColors.lightTextSecondary,
              ),
            ).animate().fade(duration: 400.ms, delay: 400.ms),
          ],
        ),
      ),
    );
  }

}
