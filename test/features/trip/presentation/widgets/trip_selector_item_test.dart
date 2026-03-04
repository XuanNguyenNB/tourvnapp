import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/trip.dart';
import 'package:tour_vn/features/trip/presentation/widgets/trip_selector_item.dart';

void main() {
  group('TripSelectorItem', () {
    final mockTrip = Trip(
      id: 'trip-1',
      userId: 'user-1',
      name: 'Hanoi Weekend',
      destinationId: 'han',
      destinationName: 'Hà Nội',
      days: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testWidgets('renders all trip details correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripSelectorItem(trip: mockTrip, onTap: () {}),
          ),
        ),
      );

      // Verify the name is displayed
      expect(find.text('Hanoi Weekend'), findsOneWidget);

      // Verify the destination name is displayed
      expect(find.text('Hà Nội'), findsOneWidget);

      // Verify the days and activities info is displayed
      expect(find.text('0 ngày • 0 hoạt động'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripSelectorItem(
              trip: mockTrip,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TripSelectorItem));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
