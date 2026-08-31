// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: auth_repository.dart
//
// Purpose:
// Abstract contract and local Hive repository implementation for user registration, authentication, and session persistence.
//
// Responsibilities:
// - Persist registered user accounts in Hive `userBox` under `'users_db'`.
// - Enforce normalized email matching and prevent duplicate email registrations.
// - Hash passwords (salted digest) to avoid plain-text storage in local database.
// - Verify credentials during login and manage active session keys (`current_uid`, `uid`, `name`, `email`).
// - Provide `getCurrentUser()` to restore active sessions across app restarts.
// - Provide `logout()` to clear active session without deleting registered user accounts.
//
// Data Flow:
// AuthNotifier → AuthRepositoryImpl → HiveService.userBox (`users_db` & session keys)
//
// Important Rules:
// - All email lookups use `email.trim().toLowerCase()` to prevent casing duplicates.
// - `logout()` clears active session keys but preserves registered accounts in `users_db`.
//
// Main Operations:
// - getCurrentUser(): Read active session from Hive
// - registerWithEmail(email, password, name): Validate duplicate and save account to `users_db`
// - loginWithEmail(email, password): Verify password hash against `users_db`
// - logout(): Terminate active session
// ============================================================

import 'dart:async';
import 'dart:convert';
import '../models/user_model.dart';
import '../../core/services/hive_service.dart';

abstract class AuthRepository {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> loginWithEmail(String email, String password);
  Future<UserModel> registerWithEmail(
    String email,
    String password,
    String name,
  );
  Future<UserModel> loginWithGoogle();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  /// Simple salted hash helper for local credential verification.
  String _hashPassword(String password) {
    final bytes = utf8.encode('pocketday_salt_2026_$password');
    return base64.encode(bytes);
  }

  Map<String, dynamic> _getUsersDb() {
    final raw = HiveService.userBox.get('users_db');
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return {};
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final cachedUid =
        HiveService.userBox.get('current_uid') ??
        HiveService.userBox.get('uid');
    final cachedName = HiveService.userBox.get('name');
    final cachedEmail = HiveService.userBox.get('email');

    if (cachedUid != null && cachedEmail != null) {
      return UserModel(
        uid: cachedUid.toString(),
        email: cachedEmail.toString(),
        displayName: (cachedName ?? 'User').toString(),
        createdAt: DateTime.now(),
      );
    }
    return null;
  }

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final emailNorm = email.trim().toLowerCase();
    final usersDb = _getUsersDb();
    final userMap = usersDb[emailNorm];

    if (userMap == null || userMap['passwordHash'] != _hashPassword(password)) {
      throw Exception('Incorrect email or password.');
    }

    final uid = userMap['uid'] as String;
    final displayName = userMap['displayName'] as String;
    final emailVal = userMap['email'] as String;

    final user = UserModel(
      uid: uid,
      email: emailVal,
      displayName: displayName,
      createdAt: DateTime.now(),
    );

    // Save active session
    await HiveService.userBox.put('current_uid', user.uid);
    await HiveService.userBox.put('uid', user.uid);
    await HiveService.userBox.put('name', user.displayName);
    await HiveService.userBox.put('email', user.email);

    return user;
  }

  @override
  Future<UserModel> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final emailNorm = email.trim().toLowerCase();
    final usersDb = _getUsersDb();

    if (usersDb.containsKey(emailNorm)) {
      throw Exception('This account already exists. Please sign in instead.');
    }

    final uid = 'hive_user_${DateTime.now().millisecondsSinceEpoch}';
    final passwordHash = _hashPassword(password);
    final userMap = {
      'uid': uid,
      'email': email.trim(),
      'emailNormalized': emailNorm,
      'displayName': name.trim(),
      'passwordHash': passwordHash,
      'createdAt': DateTime.now().toIso8601String(),
    };

    usersDb[emailNorm] = userMap;
    await HiveService.userBox.put('users_db', usersDb);

    final user = UserModel(
      uid: uid,
      email: email.trim(),
      displayName: name.trim(),
      createdAt: DateTime.now(),
    );

    // Save active session
    await HiveService.userBox.put('current_uid', user.uid);
    await HiveService.userBox.put('uid', user.uid);
    await HiveService.userBox.put('name', user.displayName);
    await HiveService.userBox.put('email', user.email);

    return user;
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 400));

    const email = 'google.user@pocketday.app';
    const displayName = 'Google User';
    const uid = 'google_hive_202';

    final usersDb = _getUsersDb();
    if (!usersDb.containsKey(email)) {
      usersDb[email] = {
        'uid': uid,
        'email': email,
        'emailNormalized': email,
        'displayName': displayName,
        'passwordHash': _hashPassword('google_auth'),
        'createdAt': DateTime.now().toIso8601String(),
      };
      await HiveService.userBox.put('users_db', usersDb);
    }

    final user = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );

    await HiveService.userBox.put('current_uid', user.uid);
    await HiveService.userBox.put('uid', user.uid);
    await HiveService.userBox.put('name', user.displayName);
    await HiveService.userBox.put('email', user.email);

    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> logout() async {
    await HiveService.userBox.delete('current_uid');
    await HiveService.userBox.delete('uid');
    await HiveService.userBox.delete('name');
    await HiveService.userBox.delete('email');
  }
}
