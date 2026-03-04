import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/trip_day.dart';
import 'package:tour_vn/features/trip/domain/entities/activity.dart';

void main() {
  group('TripDay Multi-Destination Conflict Detection', () {
    group('hasMultipleDestinations', () {
      test('returns false when activities is empty', () {
        const day = TripDay(dayNumber: 1, activities: []);

        expect(day.hasMultipleDestinations, isFalse);
      });

      test('returns false when all activities have same destination', () {
        const day = TripDay(
          dayNumber: 1,
          activities: [
            Activity(
              id: 'a1',
              locationId: 'loc1',
              locationName: 'Location 1',
              timeSlot: 'morning',
              sortOrder: 0,
              destinationId: 'dest1',
              destinationName: 'Hà Nội',
            ),
            Activity(
              id: 'a2',
              locationId: 'loc2',
              locationName: 'Location 2',
              timeSlot: 'noon',
              sortOrder: 1,
              destinationId: 'dest1',
              destinationName: 'Hà Nội',
            ),
          ],
        );

        expect(day.hasMultipleDestinations, isFalse);
      });

      test('returns true when activities have different destinations', () {
        const day = TripDay(
          dayNumber: 1,
          activities: [
            Activity(
              id: 'a1',
              locationId: 'loc1',
              locationName: 'Location 1',
              timeSlot: 'morning',
              sortOrder: 0,
              destinationId: 'dest1',
              destinationName: 'Hà Nội',
            ),
            Activity(
              id: 'a2',
              locationId: 'loc2',
              locationName: 'Location 2',
              timeSlot: 'noon',
              sortOrder: 1,
              destinationId: 'dest2',
              destinationName: 'Đà Nẵng',
            ),
          ],
        );

        expect(day.hasMultipleDestinations, isTrue);
      });

      test('ignores activities with null destinationId', () {
        const day = TripDay(
          dayNumber: 1,
          activities: [
            Activity(
              id: 'a1',
              locationId: 'loc1',
              locationName: 'Location 1',
              timeSlot: 'morning',
              sortOrder: 0,
              destinationId: 'dest1',
              destinationName: 'Hà Nội',
            ),
            Activity(
              id: 'a2',
              locationId: 'loc2',
              locationName: 'Location 2 (Legacy)',
              timeSlot: 'noon',
              sortOrder: 1,
              // No destinationId - legacy data
            ),
          ],
        );

        expect(day.hasMultipleDestinations, isFalse);
      });

      test('returns true with 3+ different destinations', () {
        const day = TripDay(
          dayNumber: 1,
          activities: [
            Activity(
              id: 'a1',
              locationId: 'loc1',
              locationName: 'Location 1',
              timeSlot: 'morning',
              sortOrder: 0,
              destinationId: 'dest1',
              destinationName: 'Hà Nội',
            ),
            Activity(
              id: 'a2',
              locationId: 'loc2',
              locationName: 'Location 2',
              timeSlot: 'noon',
              sortOrder: 1,
              destinationId: 'dest2',
              destinationName: 'Đà Nẵng',
            ),
            Activity(
              id: 'a3',
              locationId: 'loc3',
              locationName: 'Location 3',
              timeSlot: 'afternoon',
              sortOrder: 2,
              destinationId: 'dest3',
              destinationName: 'Đà Lạt',
            ),
          ],
        );

        expect(day.hasMultipleDestinations, isTrue);
      });
    });

    group('primaryDestinationId', () {
      test('returns null when activities is empty', () {
        const day = TripDay(dayNumber: 1, activities: []);

        expect(day.primaryDestinationId, isNull);
      });

      test('returns null when all activities have null destinationId', () {
        const day = TripDay(
          dayNumber: 1,
          activities: [
            Activity(
              id: 'a1',
              locationId: 'loc1',
              locationName: 'Location 1',
              timeSlot: 'morning',
              sortOrder: 0,
            ),
          ],
        );

        expect(day.primaryDestinationId, isNull);
      });

      test('returns the most frequent destination', () {
        const day = TripDay(
          dayNumber: 1,
          activities: [
            Activity(
              id: 'a1',
              locationId: 'loc1',
              locationName: 'Location 1',
              timeSlot: 'morning',
              sortOrder: 0,
              destinationId: 'dest1',
              destinationName: 'Hà Nội',
            ),
            Activity(
              id: 'a2',
              locationId: 'loc2',
              locationName: 'Location 2',
              timeSlot: 'noon',
              sortOrder: 1,
              destinationId: 'dest2',
              destinationName: 'Đà Nẵng',
            ),
            Activity(
              id: 'a3',
              locationId: 'loc3',
              locationName: 'Location 3',
              timeSlot: 'afternoon',
              sortOrder: 2,
              destinationId: 'dest1',
              destinationName: 'Hà Nội',
            ),
          ],
        );

        // dest1 (Hà Nội) appears 2 times, dest2 appears 1 time
        expect(day.primaryDestinationId, equals('dest1'));
      });

      test('returns destination when all activities have same destination', () {
        const day = TripDay(
          dayNumber: 1,
          activities: [
            Activity(
              id: 'a1',
              locationId: 'loc1',
              locationName: 'Location 1',
              timeSlot: 'morning',
              sortOrder: 0,
              destinationId: 'dest1',
              destinationName: 'Hà Nội',
            ),
          ],
        );

        expect(day.primaryDestinationId, equals('dest1'));
      });
    });

    group('allDestinations', () {
      test('returns empty list when activities is empty', () {
        const day = TripDay(dayNumber: 1, activities: []);

        expect(day.allDestinations, isEmpty);
      });

      test('returns unique destination IDs', () {
        const day = TripDay(
          dayNumber: 1,
          activities: [
            Activity(
              id: 'a1',
              locationId: 'loc1',
              locationName: 'Location 1',
              timeSlot: 'morning',
              sortOrder: 0,
              destinationId: 'dest1',
              destinationName: 'Hà Nội',
            ),
            Activity(
              id: 'a2',
              locationId: 'loc2',
              locationName: 'Location 2',
              timeSlot: 'noon',
              sortOrder: 1,
              destinationId: 'dest2',
              destinationName: 'Đà Nẵng',
            ),
            Activity(
              id: 'a3',
              locationId: 'loc3',
              locationName: 'Location 3',
              timeSlot: 'afternoon',
              sortOrder: 2,
              destinationId: 'dest1',
              destinationName: 'Hà Nội',
            ),
          ],
        );

        expect(day.allDestinations, containsAll(['dest1', 'dest2']));
        expect(day.allDestinations.length, equals(2));
      });

      test('ignores activities with null destinationId', () {
        const day = TripDay(
          dayNumber: 1,
          activities: [
            Activity(
              id: 'a1',
              locationId: 'loc1',
              locationName: 'Location 1',
              timeSlot: 'morning',
              sortOrder: 0,
              destinationId: 'dest1',
              destinationName: 'Hà Nội',
            ),
            Activity(
              id: 'a2',
              locationId: 'loc2',
              locationName: 'Legacy Location',
              timeSlot: 'noon',
              sortOrder: 1,
              // No destinationId
            ),
          ],
        );

        expect(day.allDestinations, equals(['dest1']));
      });
    });

    group('allDestinationNames', () {
      test('returns empty list when activities is empty', () {
        const day = TripDay(dayNumber: 1, activities: []);

        expect(day.allDestinationNames, isEmpty);
      });

      test('returns unique destination names', () {
        const day = TripDay(
          dayNumber: 1,
          activities: [
            Activity(
              id: 'a1',
              locationId: 'loc1',
              locationName: 'Location 1',
              timeSlot: 'morning',
              sortOrder: 0,
              destinationId: 'dest1',
              destinationName: 'Hà Nội',
            ),
            Activity(
              id: 'a2',
              locationId: 'loc2',
              locationName: 'Location 2',
              timeSlot: 'noon',
              sortOrder: 1,
              destinationId: 'dest2',
              destinationName: 'Đà Nẵng',
            ),
            Activity(
              id: 'a3',
              locationId: 'loc3',
              locationName: 'Location 3',
              timeSlot: 'afternoon',
              sortOrder: 2,
              destinationId: 'dest1',
              destinationName: 'Hà Nội',
            ),
          ],
        );

        expect(day.allDestinationNames, containsAll(['Hà Nội', 'Đà Nẵng']));
        expect(day.allDestinationNames.length, equals(2));
      });

      test('ignores activities with null destinationName', () {
        const day = TripDay(
          dayNumber: 1,
          activities: [
            Activity(
              id: 'a1',
              locationId: 'loc1',
              locationName: 'Location 1',
              timeSlot: 'morning',
              sortOrder: 0,
              destinationId: 'dest1',
              destinationName: 'Hà Nội',
            ),
            Activity(
              id: 'a2',
              locationId: 'loc2',
              locationName: 'Legacy Location',
              timeSlot: 'noon',
              sortOrder: 1,
              destinationId: 'dest1',
              // No destinationName
            ),
          ],
        );

        expect(day.allDestinationNames, equals(['Hà Nội']));
      });
    });
  });
}
