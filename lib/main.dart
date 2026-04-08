import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/services/onboarding_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/trip/presentation/providers/trip_save_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      GoogleFonts.config.allowRuntimeFetching = false;

      FlutterError.onError = (details) {
        debugPrint('FlutterError: ${details.exception}');
        debugPrint('Stack: ${details.stack}');
      };

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final prefs = await SharedPreferences.getInstance();
      final authRepository = AuthRepository();

      if (!authRepository.isSignedIn) {
        try {
          await authRepository.signInAnonymously();
          debugPrint('User signed in anonymously');
        } catch (e) {
          debugPrint('Anonymous sign-in failed: $e');
        }
      } else {
        debugPrint('User already signed in');
      }

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
    },
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
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
