// ============================================================
// PocketDay — AuthSession Unit & Widget Tests
// ============================================================
//
// Purpose:
// Unit and provider tests verifying persistent authentication session resolution and AuthNotifier state.
//
// Responsibilities:
// - Verify checkCurrentUser() initializes user state when a cached authentication token exists.
// - Verify checkCurrentUser() returns null state when no authentication token exists.
// - Verify logout() clears active session state to null.
//
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketday/data/models/user_model.dart';
import 'package:pocketday/data/repositories/auth_repository.dart';
import 'package:pocketday/features/auth/providers/auth_provider.dart';

class FakeAuthRepository implements AuthRepository {
  UserModel? mockUser;

  FakeAuthRepository({this.mockUser});

  @override
  Future<UserModel?> getCurrentUser() async {
    return mockUser;
  }

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    mockUser = UserModel(
      uid: 'fake_uid',
      email: email,
      displayName: 'Fake User',
      createdAt: DateTime.now(),
    );
    return mockUser!;
  }

  @override
  Future<UserModel> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    mockUser = UserModel(
      uid: 'fake_uid',
      email: email,
      displayName: name,
      createdAt: DateTime.now(),
    );
    return mockUser!;
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    mockUser = UserModel(
      uid: 'google_uid_123',
      email: 'test@google.com',
      displayName: 'Google Test User',
      createdAt: DateTime.now(),
    );
    return mockUser!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> logout() async {
    mockUser = null;
  }

  @override
  Future<void> resetAppData() async {}

  @override
  Future<void> deleteAccount() async {
    mockUser = null;
  }

  @override
  Stream<UserModel?> get authStateChanges => Stream.value(mockUser);
}

void main() {
  group('AuthSession Provider Tests', () {
    test('checkCurrentUser resolves authenticated user state when token exists', () async {
      final fakeUser = UserModel(
        uid: 'cached_uid_999',
        email: 'cached@pocketday.app',
        displayName: 'Cached User',
        createdAt: DateTime.now(),
      );
      final fakeRepo = FakeAuthRepository(mockUser: fakeUser);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).checkCurrentUser();

      final state = container.read(authProvider);
      expect(state.value, isNotNull);
      expect(state.value?.uid, equals('cached_uid_999'));
      expect(state.value?.email, equals('cached@pocketday.app'));
    });

    test('checkCurrentUser resolves null user state when unauthenticated', () async {
      final fakeRepo = FakeAuthRepository(mockUser: null);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).checkCurrentUser();

      final state = container.read(authProvider);
      expect(state.value, isNull);
    });

    test('Explicit logout clears session state to null', () async {
      final fakeUser = UserModel(
        uid: 'active_session_123',
        email: 'active@pocketday.app',
        displayName: 'Active User',
        createdAt: DateTime.now(),
      );
      final fakeRepo = FakeAuthRepository(mockUser: fakeUser);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).checkCurrentUser();
      expect(container.read(authProvider).value, isNotNull);

      await container.read(authProvider.notifier).logout();
      expect(container.read(authProvider).value, isNull);
    });
  });
}
