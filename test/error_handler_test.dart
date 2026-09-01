// ============================================================================
// PocketDay Unit Test
// File: error_handler_test.dart
// Purpose: Validates global AppErrorHandler exception mapping logic.
// Architecture: Test Layer
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pocketday/core/utils/app_error_handler.dart';

void main() {
  group('AppErrorHandler Tests', () {
    test('Maps FirebaseException permission-denied to user-friendly message', () {
      final exc = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Permission denied for path',
      );
      final msg = AppErrorHandler.toUserMessage(exc);
      expect(msg, contains('permission'));
    });

    test('Maps FirebaseException network-request-failed to connection message', () {
      final exc = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'network-request-failed',
        message: 'Network drop',
      );
      final msg = AppErrorHandler.toUserMessage(exc);
      expect(msg, contains('connection'));
    });

    test('Maps arbitrary Exception to clean fallback message', () {
      final exc = Exception('Custom internal error');
      final msg = AppErrorHandler.toUserMessage(exc);
      expect(msg, isNotEmpty);
      expect(msg, isNot(contains('Exception:')));
    });
  });
}
