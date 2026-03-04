import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/auth/domain/entities/user.dart';
import 'package:tour_vn/features/auth/presentation/providers/auth_provider.dart';
import 'package:tour_vn/features/profile/presentation/screens/profile_screen.dart';

/// Test wrapper for ProfileScreen with Riverpod
Widget createTestWidget({
  User? user,
  bool isAnonymous = true,
  bool isLoading = false,
}) {
  return ProviderScope(
    overrides: [
      // Override currentUserProvider
      currentUserProvider.overrideWith((ref) => user),
      // Override isAnonymousProvider
      isAnonymousProvider.overrideWith((ref) => isAnonymous),
      // Override authStateProvider (mock stream)
      authStateProvider.overrideWith((ref) => Stream.value(user)),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

void main() {
  group('ProfileScreen', () {
    group('AC #5 - Anonymous User View', () {
      testWidgets('shows "Đăng nhập" button for anonymous users', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(isAnonymous: true));
        await tester.pumpAndSettle();

        // Assert - Sign in button visible
        expect(find.text('Đăng nhập'), findsOneWidget);
        expect(find.byIcon(Icons.login), findsOneWidget);

        // Assert - Sign out button NOT visible
        expect(find.text('Đăng xuất'), findsNothing);
        expect(find.byIcon(Icons.logout), findsNothing);
      });

      testWidgets('shows "Khách" title for anonymous users', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(isAnonymous: true));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Khách'), findsOneWidget);
        expect(find.text('Đăng nhập để lưu chuyến đi của bạn'), findsOneWidget);
      });
    });

    group('AC #1 - Signed-In User View', () {
      testWidgets('shows "Đăng xuất" button for signed-in users', (
        WidgetTester tester,
      ) async {
        // Arrange
        const user = User(
          uid: 'test-uid',
          isAnonymous: false,
          email: 'test@example.com',
          displayName: 'Test User',
        );

        await tester.pumpWidget(
          createTestWidget(user: user, isAnonymous: false),
        );
        await tester.pumpAndSettle();

        // Assert - Sign out button visible
        expect(find.text('Đăng xuất'), findsOneWidget);
        expect(find.byIcon(Icons.logout), findsOneWidget);

        // Assert - Sign in button NOT visible
        expect(find.text('Đăng nhập'), findsNothing);
      });

      testWidgets('shows user info for signed-in users', (
        WidgetTester tester,
      ) async {
        // Arrange
        const user = User(
          uid: 'test-uid',
          isAnonymous: false,
          email: 'nguyen@example.com',
          displayName: 'Nguyễn Văn A',
        );

        await tester.pumpWidget(
          createTestWidget(user: user, isAnonymous: false),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Nguyễn Văn A'), findsOneWidget);
        expect(find.text('nguyen@example.com'), findsOneWidget);
      });
    });

    group('AC #6 - Confirmation Dialog', () {
      testWidgets('shows confirmation dialog when tapping sign-out', (
        WidgetTester tester,
      ) async {
        // Arrange
        const user = User(
          uid: 'test-uid',
          isAnonymous: false,
          email: 'test@example.com',
          displayName: 'Test User',
        );

        await tester.pumpWidget(
          createTestWidget(user: user, isAnonymous: false),
        );
        await tester.pumpAndSettle();

        // Act - Tap sign-out button
        await tester.dragUntilVisible(
          find.text('Đăng xuất'),
          find.byType(SingleChildScrollView),
          const Offset(0, -100),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Đăng xuất'));
        await tester.pumpAndSettle();

        // Assert - Dialog appears
        expect(find.text('Bạn có chắc muốn đăng xuất?'), findsOneWidget);
        expect(find.text('Hủy'), findsOneWidget);
      });

      testWidgets('cancel button closes dialog without signing out', (
        WidgetTester tester,
      ) async {
        // Arrange
        const user = User(
          uid: 'test-uid',
          isAnonymous: false,
          email: 'test@example.com',
          displayName: 'Test User',
        );

        await tester.pumpWidget(
          createTestWidget(user: user, isAnonymous: false),
        );
        await tester.pumpAndSettle();

        // Act - Tap sign-out button
        await tester.dragUntilVisible(
          find.text('Đăng xuất'),
          find.byType(SingleChildScrollView),
          const Offset(0, -100),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Đăng xuất'));
        await tester.pumpAndSettle();

        // Act - Tap cancel
        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();

        // Assert - Dialog closes, still on profile screen
        expect(find.text('Bạn có chắc muốn đăng xuất?'), findsNothing);
        expect(find.text('Hồ sơ'), findsOneWidget);
      });
    });

    group('UI Structure', () {
      testWidgets('renders correctly with proper structure', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(isAnonymous: true));
        await tester.pumpAndSettle();

        // Assert - Basic structure
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Hồ sơ'), findsOneWidget);
      });

      testWidgets('shows person outline icon for anonymous users', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(isAnonymous: true));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.person_outline), findsOneWidget);
      });
    });
  });
}
