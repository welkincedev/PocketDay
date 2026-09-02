// ============================================================
// PocketDay — AppErrorHandler
// ============================================================
//
// Purpose:
// Centralized exception parser and user-friendly error message generator.
//
// Responsibilities:
// - Catch and classify Firebase, network, authentication, and generic runtime exceptions.
// - Log full technical details (debugPrint & stack traces) for developers without leaking sensitive data to UI.
// - Convert raw error details (codes, stack traces) into calm, clear, human-readable strings.
// - Prevent raw Firebase credentials, UIDs, Firestore paths, or internal exceptions from reaching the user.
//
// Data Flow:
// Technical Exception → AppErrorHandler.toUserMessage(error) → PocketDay UI Component (SnackBar / Error Banner / Error View)
//
// ============================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class AppErrorHandler {
  AppErrorHandler._();

  /// Logs technical details for developers while remaining completely silent to the UI.
  static void logError(String tag, dynamic error, [StackTrace? stackTrace]) {
    debugPrint('=== [PocketDay Technical Log] $tag ===');
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Converts any exception object into a clean, human-readable user message.
  static String toUserMessage(dynamic error, {String? defaultMessage}) {
    if (error == null) {
      return defaultMessage ?? 'Something went wrong. Please try again.';
    }

    if (error is SocketException) {
      return 'Unable to connect right now. Please check your connection and try again.';
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return "You don't have permission to access this data.";
        case 'network-request-failed':
        case 'unavailable':
          return 'Unable to connect right now. Please check your connection and try again.';
        case 'unauthenticated':
        case 'user-token-expired':
          return 'Your session could not be verified. Please sign in again.';
        case 'not-found':
          return 'This item is no longer available.';
        case 'already-exists':
          return 'This item already exists.';
        case 'resource-exhausted':
        case 'quota-exceeded':
          return 'Service limit reached. Please try again later.';
        case 'cancelled':
          return 'Operation was cancelled.';
        case 'deadline-exceeded':
          return 'Request timed out. Please check your connection and try again.';
        default:
          if (error.message != null &&
              (error.message!.contains('network') || error.message!.contains('socket'))) {
            return 'Unable to connect right now. Please check your connection and try again.';
          }
          return defaultMessage ?? 'Something went wrong. Please try again.';
      }
    }

    final errStr = error.toString().toLowerCase();

    // User-initiated cancellations
    if (errStr.contains('cancelled') || errStr.contains('canceled')) {
      return '';
    }

    if (errStr.contains('network') || errStr.contains('socket') || errStr.contains('offline')) {
      return 'Unable to connect right now. Please check your connection and try again.';
    }

    if (errStr.contains('unauthenticated') || errStr.contains('session') || errStr.contains('expired')) {
      return 'Your session could not be verified. Please sign in again.';
    }

    if (errStr.contains('permission') || errStr.contains('denied')) {
      return "You don't have permission to access this data.";
    }

    return defaultMessage ?? 'Something went wrong. Please try again.';
  }

  /// Specific helper for Authentication errors
  static String toAuthUserMessage(dynamic error) {
    if (error == null) return 'Couldn\'t sign you in. Please try again.';
    final errStr = error.toString().toLowerCase();

    if (errStr.contains('cancelled') || errStr.contains('canceled')) {
      return '';
    }
    if (errStr.contains('google')) {
      return 'Couldn\'t sign you in with Google. Please try again.';
    }
    if (errStr.contains('network') || errStr.contains('socket') || errStr.contains('unavailable')) {
      return 'Unable to connect right now. Please check your connection and try again.';
    }
    if (errStr.contains('session') || errStr.contains('expired') || errStr.contains('token')) {
      return 'Your session could not be verified. Please sign in again.';
    }
    return toUserMessage(error, defaultMessage: 'Couldn\'t sign you in. Please try again.');
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
