// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: error_view.dart
//
// Purpose:
// Reusable error presentation view with retry button for handling unexpected exceptions gracefully.
//
// Responsibilities:
// - Render error icon, user-friendly error message, and optional retry action button.
// - Prevent raw unhandled exception traces from displaying directly to users.
//
// Data Flow:
// Async Error / Exception → ErrorView → User Retry tap (`onRetry`)
//
// Important Rules:
// - Never display raw stack traces to end users; provide actionable retry options.
//
// Main Operations:
// - ErrorView(message, onRetry)
// ============================================================

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../utils/app_error_handler.dart';
import 'app_button.dart';

class ErrorView extends StatelessWidget {
  final String? message;
  final dynamic error;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    this.message,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final displayMessage = message ?? (error != null ? AppErrorHandler.toUserMessage(error) : AppStrings.somethingWentWrong);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.expense,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              displayMessage,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              AppButton(
                text: AppStrings.retry,
                variant: AppButtonVariant.outline,
                width: 140,
                height: 44,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
