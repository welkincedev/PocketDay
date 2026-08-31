// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: main.dart
//
// Purpose:
// Application entry point for PocketDay Flutter app.
//
// Responsibilities:
// - Initialize Flutter framework bindings.
// - Initialize Hive local database storage engine.
// - Wrap root application widget with Riverpod ProviderScope.
// - Configure MaterialApp with AppTheme, light/dark modes, and AppRoutes.
//
// Data Flow:
// System Launch → main() → HiveService.init() → ProviderScope → PocketDayApp → AppRoutes
//
// Important Rules:
// - HiveService.init() must complete before runApp() executes.
// - Root widget MUST be wrapped in ProviderScope for Riverpod state access.
//
// Main Operations:
// - main(): Framework binding, Hive init, launch root app
// - PocketDayApp.build(): Listen to themeProvider, build MaterialApp
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketday/firebase_options.dart';
import 'core/constants/app_strings.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: initialRoute ?? AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
