import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/auth/domain/entities/user.dart';
import 'package:tour_vn/features/auth/presentation/providers/auth_provider.dart';
import 'package:tour_vn/features/trip/domain/entities/trip.dart';
import 'package:tour_vn/features/trip/presentation/providers/trips_provider.dart';
import 'package:tour_vn/features/trip/presentation/screens/trips_screen.dart';

Widget createTestWidget({
  User? user,
  bool isAnonymous = true,
  List<Trip> trips = const [],
}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) => user),
      isAnonymousProvider.overrideWith((ref) => isAnonymous),
      userTripsProvider.overrideWith((ref) => Stream.value(trips)),
    ],
    child: const MaterialApp(home: TripsScreen()),
  );
}

void main() {
  group('TripsScreen', () {
    testWidgets('shows FAB for signed-in users', (WidgetTester tester) async {
      const user = User(
        uid: 'test-uid',
        isAnonymous: false,
        email: 'test@example.com',
        displayName: 'Test User',
      );

      await tester.pumpWidget(createTestWidget(user: user, isAnonymous: false));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Tạo mới'), findsOneWidget);
    });

    testWidgets('hides FAB for anonymous users', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isAnonymous: true));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('empty state for signed-in users shows context correctly', (
      WidgetTester tester,
    ) async {
      const user = User(
        uid: 'test-uid',
        isAnonymous: false,
        email: 'test@example.com',
        displayName: 'Test User',
      );

      await tester.pumpWidget(createTestWidget(user: user, isAnonymous: false));
      await tester.pumpAndSettle();

      expect(
        find.text('Bắt đầu lên kế hoạch cho chuyến đi tiếp theo!'),
        findsOneWidget,
      );
      expect(find.text('🎒 Tạo chuyến đi đầu tiên'), findsOneWidget);
    });

    testWidgets('empty state for anonymous users shows sign-in prompt', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(isAnonymous: true));
      await tester.pumpAndSettle();

      expect(find.text('Đăng nhập để lưu chuyến đi'), findsOneWidget);
      expect(find.text('Đăng nhập'), findsOneWidget);
    });
  });
}
