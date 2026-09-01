// ============================================================
// PocketDay — AppRoutes
// ============================================================
//
// Purpose:
// Centralized application routing table and path string definitions.
// Maps named route strings to corresponding feature screen widgets.
//
// Responsibilities:
// - Define static route path constants (splash, onboarding, login, main, profile, subscriptions, error).
// - Maintain named route map for MaterialApp navigation.
// - Ensure consistent route naming conventions across all feature screens.
//
// Data Flow:
// MaterialApp.routes → AppRoutes.routes → Named Screen Widgets
//
// Navigation Flow:
// SplashScreen ('/') → LoginScreen ('/login') → AppMainNavigationScreen ('/main')
//
// Important Rules:
// - All primary authenticated navigation routes to AppMainNavigationScreen.
// - Use Navigator.pushReplacementNamed() for authentication state transitions to prevent back-stack leaks.
//
// Main Operations:
// - routes getter — Returns Map<String, WidgetBuilder> mapping paths to screens.
//
// Dependencies / Collaborators:
// - SplashScreen — Initial route.
// - LoginScreen — Unauthenticated route.
// - AppMainNavigationScreen — Primary authenticated tab container.
// - ProfileScreen — User account screen.
// - SubscriptionsScreen — Recurring subscription tracker screen.
//
// ============================================================

import 'package:flutter/material.dart';
import '../../features/auth/views/splash_screen.dart';
import '../../features/auth/views/onboarding_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/dashboard/views/app_main_navigation_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/subscriptions/views/subscriptions_screen.dart';
import '../widgets/app_error_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String main = '/main';
  static const String profile = '/profile';
  static const String subscriptions = '/subscriptions';
  static const String error = '/error';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    onboarding: (context) => const OnboardingScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const LoginScreen(),
    forgotPassword: (context) => const LoginScreen(),
    main: (context) => const AppMainNavigationScreen(),
    profile: (context) => const ProfileScreen(),
    subscriptions: (context) => const SubscriptionsScreen(),
    error: (context) => const AppErrorScreen(),
  };
}
