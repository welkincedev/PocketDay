// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: app_error_screen.dart
//
// Purpose:
// Reusable global error screen for unrecoverable page / application failures.
//
// Responsibilities:
// - Present a calm, friendly, minimal financial-app error interface.
// - Differentiate network offline states from generic unexpected errors.
// - Provide actionable [ Try Again ] and [ Go Home ] buttons without restarting the app.
// - Re-assure user that saved data remains safe.
//
// UX & Style Guidelines:
// - Simple icon, calm typography, no scary red banners or AI visuals.
// - Zero Lottie or third-party animation dependencies.
// ============================================================

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../routes/app_router.dart';
import '../utils/app_error_handler.dart';
import 'app_button.dart';

class AppErrorScreen extends StatelessWidget {
  final dynamic error;
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onGoHome;

  const AppErrorScreen({
    super.key,
    this.error,
    this.title,
    this.message,
    this.onRetry,
    this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    final isNetwork = error != null && AppErrorHandler.isNetworkError(error);

    final displayTitle = title ?? (isNetwork ? "You're offline" : 'Something went wrong');

    final displayMessage = message ??
        (isNetwork
            ? "PocketDay couldn't reach the server. Your cached data may still be available."
            : "PocketDay couldn't load this page. Your saved data is safe.");

    final iconData = isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.expense.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    size: 40,
                    color: AppColors.expense,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  displayTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  displayMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(180),
                        height: 1.4,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (onRetry != null) ...[
                      Flexible(
                        child: AppButton(
                          text: 'Try Again',
                          variant: AppButtonVariant.primary,
                          height: 48,
                          onPressed: onRetry,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Flexible(
                      child: AppButton(
                        text: 'Go Home',
                        variant: AppButtonVariant.outline,
                        height: 48,
                        onPressed: onGoHome ??
                            () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacementNamed(context, AppRoutes.main);
                              }
                            },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
