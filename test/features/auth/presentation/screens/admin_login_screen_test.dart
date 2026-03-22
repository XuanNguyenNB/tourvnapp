import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/auth/presentation/screens/admin_login_screen.dart';
import 'package:tour_vn/features/auth/presentation/widgets/google_sign_in_button.dart';

void main() {
  group('AdminLoginScreen Widget Tests', () {
    /// Helper to create a testable widget
    Widget createAdminLoginScreen() {
      return const ProviderScope(
        child: MaterialApp(home: AdminLoginScreen()),
      );
    }

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(createAdminLoginScreen());
      await tester.pump();

      expect(find.byType(AdminLoginScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays TourVN Admin title', (tester) async {
      await tester.pumpWidget(createAdminLoginScreen());
      await tester.pump();

      expect(find.text('TourVN Admin'), findsOneWidget);
    });

    testWidgets('displays admin subtitle', (tester) async {
      await tester.pumpWidget(createAdminLoginScreen());
      await tester.pump();

      expect(find.text('Bảng điều khiển quản trị'), findsOneWidget);
    });

    testWidgets('has email and password input fields', (tester) async {
      await tester.pumpWidget(createAdminLoginScreen());
      await tester.pump();

      // Should have 2 TextFormFields (email + password)
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('has Đăng nhập button', (tester) async {
      await tester.pumpWidget(createAdminLoginScreen());
      await tester.pump();

      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('displays admin-only footer text', (tester) async {
      await tester.pumpWidget(createAdminLoginScreen());
      await tester.pump();

      expect(find.text('Chỉ dành cho quản trị viên'), findsOneWidget);
    });

    testWidgets('does NOT have GoogleSignInButton', (tester) async {
      await tester.pumpWidget(createAdminLoginScreen());
      await tester.pump();

      expect(find.byType(GoogleSignInButton), findsNothing);
    });

    testWidgets('does NOT have anonymous browse option', (tester) async {
      await tester.pumpWidget(createAdminLoginScreen());
      await tester.pump();

      expect(find.textContaining('không đăng nhập'), findsNothing);
    });

    testWidgets('does NOT have registration toggle', (tester) async {
      await tester.pumpWidget(createAdminLoginScreen());
      await tester.pump();

      expect(find.textContaining('Đăng ký'), findsNothing);
    });

    testWidgets('password visibility toggle works', (tester) async {
      await tester.pumpWidget(createAdminLoginScreen());
      await tester.pump();

      // Initially password is obscured — visibility_off icon is shown
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Tap the toggle
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      // Now visibility icon should be shown
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });
}
