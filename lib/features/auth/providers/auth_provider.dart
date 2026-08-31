// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: auth_provider.dart
//
// Purpose:
// Riverpod StateNotifier managing active user session state (`AsyncValue<UserModel?>`).
//
// Responsibilities:
// - Check for existing logged-in user on app launch (`checkCurrentUser`).
// - Handle email login, email registration, and Google sign-in.
// - Manage password reset and user logout flow.
//
// Data Flow:
// Auth Views → authProvider (AuthNotifier) → AuthRepository → Hive (`userBox`)
//
// Important Rules:
// - Exposes state as `AsyncValue<UserModel?>` to communicate loading, authenticated user data, or unauthenticated null states.
//
// Main Operations:
// - checkCurrentUser(): Verify active local session
// - loginWithEmail(email, password): Authenticate user with email credentials
// - registerWithEmail(email, password, name): Register user profile
// - logout(): Terminate session and clear state
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
      final repo = ref.watch(authRepositoryProvider);
      return AuthNotifier(repo);
    });

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    checkCurrentUser();
  }

  void _onUserAuthenticated(UserModel? user) {
    state = AsyncValue.data(user);
  }

  Future<void> checkCurrentUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.getCurrentUser();
      _onUserAuthenticated(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.loginWithEmail(email, password);
      _onUserAuthenticated(user);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.registerWithEmail(email, password, name);
      _onUserAuthenticated(user);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.loginWithGoogle();
      _onUserAuthenticated(user);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _repo.sendPasswordResetEmail(email);
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _repo.logout();
    state = const AsyncValue.data(null);
  }
}
