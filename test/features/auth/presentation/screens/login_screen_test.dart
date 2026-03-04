import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/core/widgets/glass_card.dart';
import 'package:tour_vn/features/auth/presentation/screens/login_screen.dart';
import 'package:tour_vn/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:tour_vn/features/auth/presentation/widgets/facebook_sign_in_button.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    /// Helper to create a testable widget
    Widget createLoginScreen() {
      return const ProviderScope(child: MaterialApp(home: LoginScreen()));
    }

    testWidgets('should display TourVN logo', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump(); // Allow widgets to settle

      // Logo container should be present with TourVN text
      expect(find.text('TourVN'), findsOneWidget);
    });

    testWidgets('should display welcome tagline in Vietnamese', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      expect(find.textContaining('Chào mừng'), findsOneWidget);
      expect(find.textContaining('Khám phá Việt Nam'), findsOneWidget);
    });

    testWidgets('should display GoogleSignInButton widget', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      expect(find.byType(GoogleSignInButton), findsOneWidget);
    });

    testWidgets('should display FacebookSignInButton widget', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      expect(find.byType(FacebookSignInButton), findsOneWidget);
    });

    testWidgets('should display anonymous browse option', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      // Find TextButton with text containing "không đăng nhập"
      expect(find.textContaining('không đăng nhập'), findsOneWidget);
    });

    testWidgets('should display divider with "hoặc" text', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      expect(find.text('hoặc'), findsOneWidget);
    });

    testWidgets('should have gradient background', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      // Find the Container with gradient decoration
      final container = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).gradient != null,
      );

      expect(container, findsOneWidget);
    });

    testWidgets('should display GlassCard for buttons', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      // Find GlassCard widget directly
      expect(find.byType(GlassCard), findsOneWidget);
    });

    testWidgets('LoginScreen renders without errors', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      // The screen should render without throwing exceptions
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
