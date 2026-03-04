import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/trip.dart';
import 'package:tour_vn/features/trip/presentation/providers/trips_provider.dart';
import 'package:tour_vn/features/trip/presentation/widgets/trip_selector_bottom_sheet.dart';

void main() {
  group('TripSelectorBottomSheet', () {
    final mockTrips = List.generate(
      7,
      (i) => Trip(
        id: 'trip-$i',
        userId: 'user-1',
        name: 'Trip $i',
        destinationId: 'dest-$i',
        destinationName: 'Destination $i',
        days: const [],
        createdAt: DateTime.now().subtract(Duration(days: i)), // 0 is newest
        updatedAt: DateTime.now(),
      ),
    );

    Future<void> pumpBottomSheet(
      WidgetTester tester,
      AsyncValue<List<Trip>> tripsValue,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userTripsProvider.overrideWith(
              (ref) => tripsValue.when(
                data: (data) => Stream.value(data),
                loading: () => Stream.periodic(
                  const Duration(minutes: 1),
                ).cast<List<Trip>>(),
                error: (e, st) => Stream.error(e, st),
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () {
                      TripSelectorBottomSheet.show(context: context);
                    },
                    child: const Text('Show'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500)); // To show modal
    }

    testWidgets('shows loading state initially', (tester) async {
      await pumpBottomSheet(tester, const AsyncValue.loading());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows up to 5 trips and new trip button', (tester) async {
      await pumpBottomSheet(tester, AsyncData(mockTrips));
      await tester.pumpAndSettle();

      // Should display "Thêm vào chuyến đi nào?"
      expect(find.text('Thêm vào chuyến đi nào?'), findsOneWidget);

      // Should show the new trip button
      final newTripButton = find.text('Tạo chuyến đi mới');
      await tester.ensureVisible(newTripButton);
      expect(newTripButton, findsOneWidget);

      // Verify the list has items (we can check the first item)
      expect(find.text('Trip 0'), findsOneWidget);
      expect(find.text('Trip 5'), findsNothing);
    });
  });
}
