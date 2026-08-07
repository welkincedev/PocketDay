import 'dart:async';
import '../models/user_model.dart';
import '../../core/services/hive_service.dart';

abstract class AuthRepository {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> loginWithEmail(String email, String password);
  Future<UserModel> registerWithEmail(String email, String password, String name);
  Future<UserModel> loginWithGoogle();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async {
    final cachedUid = HiveService.userBox.get('uid');
    final cachedName = HiveService.userBox.get('name');
    final cachedEmail = HiveService.userBox.get('email');

    if (cachedUid != null) {
      return UserModel(
        uid: cachedUid,
        email: cachedEmail ?? 'demo@pocketday.app',
        displayName: cachedName ?? 'Alex Johnson',
        createdAt: DateTime.now(),
      );
    }
    return null;
  }

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate async network response
    
    final user = UserModel(
      uid: 'hive_user_101',
      email: email,
      displayName: email.contains('@') ? email.split('@').first : 'User',
      createdAt: DateTime.now(),
    );

    // Save user session in Hive local storage
    await HiveService.userBox.put('uid', user.uid);
    await HiveService.userBox.put('name', user.displayName);
    await HiveService.userBox.put('email', user.email);

    return user;
  }

  @override
  Future<UserModel> registerWithEmail(String email, String password, String name) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final user = UserModel(
      uid: 'hive_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: name,
      createdAt: DateTime.now(),
    );

    // Save registered user details in Hive local storage
    await HiveService.userBox.put('uid', user.uid);
    await HiveService.userBox.put('name', user.displayName);
    await HiveService.userBox.put('email', user.email);

    return user;
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 600));

    final user = UserModel(
      uid: 'google_hive_202',
      email: 'alex.google@pocketday.app',
      displayName: 'Alex Johnson',
      photoUrl: 'https://i.pravatar.cc/150?img=12',
      createdAt: DateTime.now(),
    );

    await HiveService.userBox.put('uid', user.uid);
    await HiveService.userBox.put('name', user.displayName);
    await HiveService.userBox.put('email', user.email);

    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> logout() async {
    await HiveService.userBox.clear();
  }
}
