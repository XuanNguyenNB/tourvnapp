import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/data/repositories/trip_repository.dart';
import 'package:tour_vn/features/trip/domain/entities/activity.dart';
import 'package:tour_vn/features/trip/domain/entities/trip.dart';
import 'package:tour_vn/features/trip/domain/entities/trip_day.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreTripRepository repository;

  final fixedDate = DateTime(2026, 1, 27, 12, 0, 0);

  Trip createTestTrip({
    String id = 'trip-1',
    String userId = 'user-1',
    String name = 'Test Trip',
    String destinationId = 'dest-1',
    String destinationName = 'Đà Lạt',
    List<TripDay>? days,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Trip(
      id: id,
      userId: userId,
      name: name,
      destinationId: destinationId,
      destinationName: destinationName,
      days: days ?? const [],
      createdAt: createdAt ?? fixedDate,
      updatedAt: updatedAt ?? fixedDate,
    );
  }

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = FirestoreTripRepository(firestore: fakeFirestore);
  });

  group('FirestoreTripRepository', () {
    group('createTrip()', () {
      test('should create trip document in Firestore', () async {
        final trip = createTestTrip();

        final result = await repository.createTrip(trip);

        expect(result, equals(trip));

        // Verify document exists in Firestore
        final doc = await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('trips')
            .doc('trip-1')
            .get();

        expect(doc.exists, isTrue);
        expect(doc.data()?['name'], 'Test Trip');
        expect(doc.data()?['destinationName'], 'Đà Lạt');
      });

      test('should store trip with activities', () async {
        final tripWithActivities = createTestTrip(
          days: [
            TripDay(
              dayNumber: 1,
              activities: [
                const Activity(
                  id: 'act-1',
                  locationId: 'loc-1',
                  locationName: 'Location 1',
                  emoji: '🍜',
                  timeSlot: 'morning',
                  sortOrder: 0,
                ),
              ],
            ),
          ],
        );

        await repository.createTrip(tripWithActivities);

        final doc = await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('trips')
            .doc('trip-1')
            .get();

        final days = doc.data()?['days'] as List<dynamic>;
        expect(days, hasLength(1));
        expect(days[0]['dayNumber'], 1);

        final activities = days[0]['activities'] as List<dynamic>;
        expect(activities, hasLength(1));
        expect(activities[0]['locationName'], 'Location 1');
      });
    });

    group('getTrip()', () {
      test('should return trip when exists', () async {
        final trip = createTestTrip();
        await repository.createTrip(trip);

        final result = await repository.getTrip('user-1', 'trip-1');

        expect(result, isNotNull);
        expect(result!.id, 'trip-1');
        expect(result.name, 'Test Trip');
      });

      test('should return null when trip does not exist', () async {
        final result = await repository.getTrip('user-1', 'non-existent');

        expect(result, isNull);
      });

      test('should return null for different user', () async {
        final trip = createTestTrip(userId: 'user-1');
        await repository.createTrip(trip);

        final result = await repository.getTrip('user-2', 'trip-1');

        expect(result, isNull);
      });
    });

    group('getUserTrips()', () {
      test('should return stream of user trips', () async {
        await repository.createTrip(createTestTrip(id: 'trip-1'));
        await repository.createTrip(
          createTestTrip(id: 'trip-2', name: 'Trip 2'),
        );

        final stream = repository.getUserTrips('user-1');
        final trips = await stream.first;

        expect(trips, hasLength(2));
      });

      test('should return empty list when no trips', () async {
        final stream = repository.getUserTrips('user-1');
        final trips = await stream.first;

        expect(trips, isEmpty);
      });

      test('should only return trips for specified user', () async {
        await repository.createTrip(createTestTrip(userId: 'user-1'));
        await repository.createTrip(
          createTestTrip(id: 'trip-2', userId: 'user-2'),
        );

        final stream = repository.getUserTrips('user-1');
        final trips = await stream.first;

        expect(trips, hasLength(1));
        expect(trips[0].userId, 'user-1');
      });

      test('should order by updatedAt descending', () async {
        await repository.createTrip(
          createTestTrip(id: 'trip-1', updatedAt: DateTime(2026, 1, 1)),
        );
        await repository.createTrip(
          createTestTrip(id: 'trip-2', updatedAt: DateTime(2026, 1, 3)),
        );
        await repository.createTrip(
          createTestTrip(id: 'trip-3', updatedAt: DateTime(2026, 1, 2)),
        );

        final stream = repository.getUserTrips('user-1');
        final trips = await stream.first;

        expect(trips[0].id, 'trip-2'); // Most recent first
        expect(trips[1].id, 'trip-3');
        expect(trips[2].id, 'trip-1');
      });
    });

    group('getTripByDestination()', () {
      test('should return trip when destination matches', () async {
        await repository.createTrip(createTestTrip(destinationId: 'dalat-1'));

        final result = await repository.getTripByDestination(
          'user-1',
          'dalat-1',
        );

        expect(result, isNotNull);
        expect(result!.destinationId, 'dalat-1');
      });

      test('should return null when no matching destination', () async {
        await repository.createTrip(createTestTrip(destinationId: 'dalat-1'));

        final result = await repository.getTripByDestination(
          'user-1',
          'hanoi-1',
        );

        expect(result, isNull);
      });

      test('should only search for specified user', () async {
        await repository.createTrip(
          createTestTrip(userId: 'user-1', destinationId: 'dalat-1'),
        );

        final result = await repository.getTripByDestination(
          'user-2',
          'dalat-1',
        );

        expect(result, isNull);
      });

      test('should return only one trip when multiple exist', () async {
        await repository.createTrip(
          createTestTrip(id: 'trip-1', destinationId: 'dalat-1'),
        );
        await repository.createTrip(
          createTestTrip(id: 'trip-2', destinationId: 'dalat-1'),
        );

        final result = await repository.getTripByDestination(
          'user-1',
          'dalat-1',
        );

        expect(result, isNotNull);
        // Should return one of them (limit 1)
      });
    });

    group('updateTrip()', () {
      test('should update existing trip', () async {
        await repository.createTrip(createTestTrip());

        final updatedTrip = createTestTrip(name: 'Updated Name');
        await repository.updateTrip(updatedTrip);

        final result = await repository.getTrip('user-1', 'trip-1');

        expect(result?.name, 'Updated Name');
      });

      test('should update trip days', () async {
        await repository.createTrip(createTestTrip());

        final updatedTrip = createTestTrip(
          days: [const TripDay(dayNumber: 1), const TripDay(dayNumber: 2)],
        );
        await repository.updateTrip(updatedTrip);

        final result = await repository.getTrip('user-1', 'trip-1');

        expect(result?.days, hasLength(2));
      });
    });

    group('deleteTrip()', () {
      test('should delete trip document', () async {
        await repository.createTrip(createTestTrip());

        // Verify exists
        var result = await repository.getTrip('user-1', 'trip-1');
        expect(result, isNotNull);

        await repository.deleteTrip('user-1', 'trip-1');

        // Verify deleted
        result = await repository.getTrip('user-1', 'trip-1');
        expect(result, isNull);
      });

      test('should not affect other user trips', () async {
        await repository.createTrip(
          createTestTrip(id: 'trip-1', userId: 'user-1'),
        );
        await repository.createTrip(
          createTestTrip(id: 'trip-2', userId: 'user-2'),
        );

        await repository.deleteTrip('user-1', 'trip-1');

        final remaining = await repository.getTrip('user-2', 'trip-2');
        expect(remaining, isNotNull);
      });
    });

    group('addToExistingTrip()', () {
      test('should merge new data into existing trip', () async {
        final existingTrip = createTestTrip(
          days: [const TripDay(dayNumber: 1)],
        );
        await repository.createTrip(existingTrip);

        final newData = createTestTrip(
          days: [
            TripDay(
              dayNumber: 1,
              activities: [
                const Activity(
                  id: 'new-act',
                  locationId: 'new-loc',
                  locationName: 'New Location',
                  timeSlot: 'afternoon',
                  sortOrder: 0,
                ),
              ],
            ),
          ],
        );

        final result = await repository.addToExistingTrip(
          existingTrip,
          newData,
        );

        expect(result.days, hasLength(1));
        expect(result.days[0].activities, hasLength(1));
        expect(result.updatedAt, isNot(equals(existingTrip.updatedAt)));
      });
    });
  });
}
