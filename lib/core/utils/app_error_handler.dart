// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: app_error_handler.dart
//
// Purpose:
// Centralized exception parser and user-friendly error message generator.
//
// Responsibilities:
// - Catch and map Firebase, network, auth, and generic runtime exceptions.
// - Convert raw error details (codes, stack traces) into clear, friendly strings.
// - Prevent raw Firebase credentials or sensitive debug output from leaking to UI.
//
// Data Flow:
// Exception → AppErrorHandler.toUserMessage(error) → Displayed in UI (SnackBar / ErrorView / AppErrorScreen)
// ============================================================

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';

class AppErrorHandler {
  AppErrorHandler._();

  /// Converts any exception object into a clean, human-readable user message.
  static String toUserMessage(dynamic error) {
    if (error == null) {
      return 'Something went wrong. Please try again.';
    }

    if (error is SocketException) {
      return 'Check your internet connection and try again.';
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return "You don't have permission to access this data.";
        case 'network-request-failed':
        case 'unavailable':
          return 'Check your internet connection and try again.';
        case 'unauthenticated':
        case 'user-token-expired':
          return 'Your session has expired. Please sign in again.';
        case 'not-found':
          return 'This data is no longer available.';
        case 'already-exists':
          return 'This item already exists.';
        case 'resource-exhausted':
        case 'quota-exceeded':
          return 'Service limit reached. Please try again later.';
        case 'cancelled':
          return 'Operation was cancelled.';
        case 'deadline-exceeded':
          return 'Request timed out. Please check your connection.';
        default:
          if (error.message != null && error.message!.contains('network')) {
            return 'Check your internet connection and try again.';
          }
          return 'Something went wrong. Please try again.';
      }
    }

    // String fallback check
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('network') || errStr.contains('socket') || errStr.contains('offline')) {
      return 'Check your internet connection and try again.';
    }
    if (errStr.contains('permission') || errStr.contains('denied')) {
      return "You don't have permission to access this data.";
    }
    if (errStr.contains('unauthenticated') || errStr.contains('expired')) {
      return 'Your session has expired. Please sign in again.';
    }

    return 'Something went wrong. Please try again.';
  }

  /// Returns true if the error indicates a network or connectivity issue.
  static bool isNetworkError(dynamic error) {
    if (error is SocketException) return true;
    if (error is FirebaseException) {
      return error.code == 'network-request-failed' || error.code == 'unavailable';
    }
    final errStr = error.toString().toLowerCase();
    return errStr.contains('network') || errStr.contains('socket') || errStr.contains('offline');
  }
}
