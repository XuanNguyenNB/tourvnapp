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

Trip createTrip() {
  final now = DateTime(2026, 1, 1);
  return Trip(
    id: 'trip-1',
    userId: 'test-uid',
    name: 'Đà Nẵng 3 ngày',
    destinationId: 'da-nang',
    destinationName: 'Đà Nẵng',
    days: const [],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('TripsScreen', () {
    const signedInUser = User(
      uid: 'test-uid',
      isAnonymous: false,
      email: 'test@example.com',
      displayName: 'Test User',
    );

    testWidgets('shows bottom create bar for signed-in users with trips', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          user: signedInUser,
          isAnonymous: false,
          trips: [createTrip()],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI lên lịch'), findsOneWidget);
      expect(find.text('Tự lên lịch'), findsOneWidget);
    });

    testWidgets('empty state for signed-in users shows current messaging', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(user: signedInUser, isAnonymous: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lên kế hoạch thông minh trong vài giây!'), findsOneWidget);
      expect(find.text('✨ Lên lịch trình với AI'), findsOneWidget);
      expect(find.text('Tự tạo thủ công'), findsOneWidget);
    });

    testWidgets('anonymous users see sign-in prompt', (tester) async {
      await tester.pumpWidget(createTestWidget(isAnonymous: true));
      await tester.pumpAndSettle();

      expect(find.text('Đăng nhập để lưu chuyến đi'), findsOneWidget);
      expect(find.text('Đăng nhập'), findsOneWidget);
    });
  });
}
