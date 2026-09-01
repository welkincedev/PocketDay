// ============================================================================
// PocketDay
// File: auth_provider.dart
// Purpose: User session state notifier managing Firebase Auth and Google Sign-In.
// Architecture: Presentation / State Management Layer
// State Management: Riverpod
// Storage: Firebase Authentication & Cloud Firestore
// ============================================================================

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

  Future<void> resetAppData() async {
    await _repo.resetAppData();
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    await _repo.deleteAccount();
    state = const AsyncValue.data(null);
  }
}
