import 'package:flutter/material.dart';
import '../../features/auth/views/splash_screen.dart';
import '../../features/auth/views/onboarding_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/auth/views/forgot_password_screen.dart';
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
    register: (context) => const RegisterScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    main: (context) => const MainShellScreen(),
    profile: (context) => const ProfileScreen(),
    subscriptions: (context) => const SubscriptionsScreen(),
  };
}
