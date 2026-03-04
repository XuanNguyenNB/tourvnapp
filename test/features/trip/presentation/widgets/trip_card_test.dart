import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/trip.dart';
import 'package:tour_vn/features/trip/presentation/widgets/trip_card.dart';

void main() {
  group('TripCard', () {
    late Trip testTrip;

    setUp(() {
      testTrip = Trip(
        id: 'trip-1',
        userId: 'user-1',
        name: 'Đà Lạt Adventure',
        destinationId: 'da-lat',
        destinationName: 'Đà Lạt',
        days: const [],
        createdAt: DateTime(2026, 1, 20),
        updatedAt: DateTime(2026, 1, 25),
      );
    });

    testWidgets('displays trip name correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TripCard(trip: testTrip)),
        ),
      );

      expect(find.text('Đà Lạt Adventure'), findsOneWidget);
    });

    testWidgets('displays destination name correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TripCard(trip: testTrip)),
        ),
      );

      expect(find.text('Đà Lạt'), findsOneWidget);
    });

    testWidgets('displays day count badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TripCard(trip: testTrip)),
        ),
      );

      // Should show 0 days since trip has no days
      expect(find.text('0 ngày'), findsOneWidget);
    });

    testWidgets('displays activity count badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TripCard(trip: testTrip)),
        ),
      );

      // Should show 0 activities since trip has no activities
      expect(find.text('0 điểm'), findsOneWidget);
    });

    testWidgets('shows placeholder when no cover image', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TripCard(trip: testTrip)),
        ),
      );

      // Should show map icon as placeholder
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (
      WidgetTester tester,
    ) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripCard(trip: testTrip, onTap: () => wasTapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(TripCard));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('handles long trip name with ellipsis', (
      WidgetTester tester,
    ) async {
      final longNameTrip = Trip(
        id: 'trip-1',
        userId: 'user-1',
        name:
            'This is a very long trip name that should be truncated with ellipsis',
        destinationId: 'da-lat',
        destinationName: 'Đà Lạt',
        days: const [],
        createdAt: DateTime(2026, 1, 20),
        updatedAt: DateTime(2026, 1, 25),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 300, child: TripCard(trip: longNameTrip)),
          ),
        ),
      );

      // Widget should render without overflow errors
      expect(find.byType(TripCard), findsOneWidget);
    });
  });
}
