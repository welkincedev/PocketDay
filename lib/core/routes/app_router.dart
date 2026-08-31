// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: app_router.dart
//
// Purpose:
// Centralized named route definitions and screen mapping table for PocketDay.
//
// Responsibilities:
// - Define route constants (splash, onboarding, login, register, forgotPassword, main, profile, subscriptions).
// - Expose `routes` map mapping route paths to screen widgets.
//
// Navigation Flow:
// Splash → Onboarding/Login → MainShellScreen (Tab shell: Dashboard, Transactions, Budget, Goals) → Profile / Subscriptions
//
// Important Rules:
// - Main navigation shell is served by `MainShellScreen`.
// - Screen navigation uses `Navigator.pushNamed()` or `Navigator.pushReplacementNamed()`.
//
// Route Constants:
// - splash: '/'
// - main: '/main'
// - subscriptions: '/subscriptions'
// ============================================================

import 'package:flutter/material.dart';
import '../../features/auth/views/splash_screen.dart';
import '../../features/auth/views/onboarding_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/dashboard/views/main_shell_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/subscriptions/views/subscriptions_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String main = '/main';
  static const String profile = '/profile';
  static const String subscriptions = '/subscriptions';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    onboarding: (context) => const OnboardingScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const LoginScreen(),
    forgotPassword: (context) => const LoginScreen(),
    main: (context) => const MainShellScreen(),
    profile: (context) => const ProfileScreen(),
    subscriptions: (context) => const SubscriptionsScreen(),
  };
}
