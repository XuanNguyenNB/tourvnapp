import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/onboarding_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/trip/presentation/providers/trip_save_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase - REQUIRED before runApp
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize SharedPreferences for onboarding state (Story 6.3)
  final prefs = await SharedPreferences.getInstance();

  // Sign in anonymously on first launch if not already signed in
  // This enables frictionless onboarding - users can browse without account
  final authRepository = AuthRepository();
  if (!authRepository.isSignedIn) {
    try {
      await authRepository.signInAnonymously();
      debugPrint('✓ User signed in anonymously');
    } catch (e) {
      debugPrint('✗ Anonymous sign-in failed: $e');
      // Continue anyway - user will be prompted if auth is required
    }
  } else {
    debugPrint('✓ User already signed in (anonymous or authenticated)');
  }

  // Global error handling — log uncaught errors
  // Future: tích hợp Crashlytics.recordFlutterFatalError
  FlutterError.onError = (details) {
    debugPrint('FlutterError: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
  };

  runZonedGuarded(
    () {
      runApp(
        ProviderScope(
          overrides: [
            onboardingServiceProvider.overrideWithValue(
              OnboardingService(prefs),
            ),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint('Uncaught error: $error');
      debugPrint('Stack: $stack');
      // Future: Crashlytics.recordError(error, stack);
    },
  );
}

/// Root app widget — dùng ConsumerStatefulWidget để:
/// - Kick auto-save provider 1 lần trong initState (thay vì ref.watch)
/// - Lấy routerProvider từ Riverpod
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Kick auto-save provider 1 lần — không dùng ref.watch trong build
    // để tránh side-effect bị trigger khi widget rebuild
    ref.read(autoSavePendingTripsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TourVN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
      locale: const Locale('vi', 'VN'),
    );
  }
}
