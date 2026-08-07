import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _isInitialized = true;
      debugPrint('✅ Firebase initialized successfully');
    } catch (e) {
      _isInitialized = false;
      debugPrint('⚠️ Firebase initialization deferred or running in local offline mode: $e');
    }
  }
}
