// ============================================================================
// PocketDay
// File: main.dart
// Purpose: Main entry point for PocketDay Flutter app. Initializes Firebase & UI.
// Architecture: Core Application Layer
// State Management: Riverpod
// Storage: Cloud Firestore with Native Offline Cache
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketday/firebase_options.dart';
import 'core/constants/app_strings.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase App for platform (Android / iOS / Web)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Enable Firestore native offline persistence with unlimited cache
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (_) {}

  runApp(const ProviderScope(child: PocketDayApp()));
}

class PocketDayApp extends ConsumerWidget {
  final String? initialRoute;

  const PocketDayApp({super.key, this.initialRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      initialRoute: initialRoute ?? AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }

}
