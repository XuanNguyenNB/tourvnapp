import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/activity.dart';
import 'package:tour_vn/features/trip/domain/entities/pending_activity.dart';
import 'package:tour_vn/features/trip/domain/entities/time_slot.dart';
import 'package:tour_vn/features/trip/domain/entities/trip.dart';
import 'package:tour_vn/features/trip/domain/entities/trip_day.dart';
import 'package:tour_vn/features/trip/presentation/providers/pending_trip_provider.dart';

void main() {
  group('Trip', () {
    final fixedDate = DateTime(2026, 1, 27, 10, 0, 0);

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

    test('should create trip with required fields', () {
      final trip = createTestTrip();

      expect(trip.id, 'trip-1');
      expect(trip.userId, 'user-1');
      expect(trip.name, 'Test Trip');
      expect(trip.destinationId, 'dest-1');
      expect(trip.destinationName, 'Đà Lạt');
      expect(trip.days, isEmpty);
      expect(trip.createdAt, fixedDate);
      expect(trip.updatedAt, fixedDate);
    });

    group('toMap()', () {
      test('should serialize empty trip correctly', () {
        final trip = createTestTrip();
        final map = trip.toMap();

        expect(map['id'], 'trip-1');
        expect(map['userId'], 'user-1');
        expect(map['name'], 'Test Trip');
        expect(map['destinationId'], 'dest-1');
        expect(map['destinationName'], 'Đà Lạt');
        expect(map['days'], isEmpty);
        expect(map['createdAt'], isA<Timestamp>());
        expect(map['updatedAt'], isA<Timestamp>());
      });

      test('should serialize trip with days and activities', () {
        const activity = Activity(
          id: 'act-1',
          locationId: 'loc-1',
          locationName: 'Test Location',
          emoji: '🍜',
          timeSlot: 'morning',
          sortOrder: 0,
        );

        final tripDay = TripDay(dayNumber: 1, activities: [activity]);

        final trip = createTestTrip(days: [tripDay]);
        final map = trip.toMap();

        expect(map['days'], hasLength(1));
        expect(map['days'][0]['dayNumber'], 1);
        expect(map['days'][0]['activities'], hasLength(1));
        expect(
          map['days'][0]['activities'][0]['locationName'],
          'Test Location',
        );
      });
    });

    group('fromMap()', () {
      test('should deserialize trip correctly', () {
        final map = {
          'id': 'trip-1',
          'userId': 'user-1',
          'name': 'Đà Lạt Trip',
          'destinationId': 'dest-1',
          'destinationName': 'Đà Lạt',
          'days': [
            {
              'dayNumber': 1,
              'activities': [
                {
                  'id': 'act-1',
                  'locationId': 'loc-1',
                  'locationName': 'Location 1',
                  'emoji': '🍜',
                  'imageUrl': null,
                  'timeSlot': 'morning',
                  'sortOrder': 0,
                },
              ],
            },
          ],
          'createdAt': Timestamp.fromDate(fixedDate),
          'updatedAt': Timestamp.fromDate(fixedDate),
        };

        final trip = Trip.fromMap(map);

        expect(trip.id, 'trip-1');
        expect(trip.name, 'Đà Lạt Trip');
        expect(trip.days, hasLength(1));
        expect(trip.days[0].activities, hasLength(1));
        expect(trip.days[0].activities[0].locationName, 'Location 1');
      });

      test('should handle empty days array', () {
        final map = {
          'id': 'trip-1',
          'userId': 'user-1',
          'name': 'Empty Trip',
          'destinationId': 'dest-1',
          'destinationName': 'Đà Lạt',
          'days': <Map<String, dynamic>>[],
          'createdAt': Timestamp.fromDate(fixedDate),
          'updatedAt': Timestamp.fromDate(fixedDate),
        };

        final trip = Trip.fromMap(map);

        expect(trip.days, isEmpty);
      });

      test('should handle null days gracefully', () {
        final map = {
          'id': 'trip-1',
          'userId': 'user-1',
          'name': 'Null Days Trip',
          'destinationId': 'dest-1',
          'destinationName': 'Đà Lạt',
          'days': null,
          'createdAt': Timestamp.fromDate(fixedDate),
          'updatedAt': Timestamp.fromDate(fixedDate),
        };

        final trip = Trip.fromMap(map);

        expect(trip.days, isEmpty);
      });
    });

    group('copyWith()', () {
      test('should copy with updated name', () {
        final original = createTestTrip();
        final copied = original.copyWith(name: 'Updated Name');

        expect(copied.id, original.id);
        expect(copied.name, 'Updated Name');
        expect(copied.destinationName, original.destinationName);
      });

      test('should copy with updated days', () {
        final original = createTestTrip();
        const newDay = TripDay(dayNumber: 1);
        final copied = original.copyWith(days: [newDay]);

        expect(original.days, isEmpty);
        expect(copied.days, hasLength(1));
        expect(copied.days[0].dayNumber, 1);
      });

      test('should maintain immutability', () {
        final original = createTestTrip();
        final copied = original.copyWith(name: 'New Name');

        expect(original.name, 'Test Trip');
        expect(copied.name, 'New Name');
        expect(identical(original, copied), isFalse);
      });
    });

    group('computed properties', () {
      test('totalDays should return number of days', () {
        final tripWithDays = createTestTrip(
          days: [
            const TripDay(dayNumber: 1),
            const TripDay(dayNumber: 2),
            const TripDay(dayNumber: 3),
          ],
        );

        expect(tripWithDays.totalDays, 3);
        expect(createTestTrip().totalDays, 0);
      });

      test('totalActivities should return sum of all activities', () {
        final tripWithActivities = createTestTrip(
          days: [
            TripDay(
              dayNumber: 1,
              activities: [
                const Activity(
                  id: 'a1',
                  locationId: 'l1',
                  locationName: 'Loc 1',
                  timeSlot: 'morning',
                  sortOrder: 0,
                ),
                const Activity(
                  id: 'a2',
                  locationId: 'l2',
                  locationName: 'Loc 2',
                  timeSlot: 'noon',
                  sortOrder: 1,
                ),
              ],
            ),
            TripDay(
              dayNumber: 2,
              activities: [
                const Activity(
                  id: 'a3',
                  locationId: 'l3',
                  locationName: 'Loc 3',
                  timeSlot: 'morning',
                  sortOrder: 0,
                ),
              ],
            ),
          ],
        );

        expect(tripWithActivities.totalActivities, 3);
      });
    });

    group('getDay()', () {
      test('should return day by number', () {
        final trip = createTestTrip(
          days: [const TripDay(dayNumber: 1), const TripDay(dayNumber: 2)],
        );

        expect(trip.getDay(1)?.dayNumber, 1);
        expect(trip.getDay(2)?.dayNumber, 2);
      });

      test('should return null for non-existent day', () {
        final trip = createTestTrip(days: [const TripDay(dayNumber: 1)]);

        expect(trip.getDay(5), isNull);
      });
    });

    group('addActivityToDay()', () {
      test('should add activity to specified day', () {
        final trip = createTestTrip(days: [const TripDay(dayNumber: 1)]);

        const newActivity = Activity(
          id: 'new-act',
          locationId: 'new-loc',
          locationName: 'New Location',
          timeSlot: 'afternoon',
          sortOrder: 0,
        );

        final updated = trip.addActivityToDay(1, newActivity);

        expect(updated.days[0].activities, hasLength(1));
        expect(updated.days[0].activities[0].id, 'new-act');
        expect(updated.updatedAt, isNot(equals(trip.updatedAt)));
      });

      test('should not modify other days', () {
        final trip = createTestTrip(
          days: [const TripDay(dayNumber: 1), const TripDay(dayNumber: 2)],
        );

        const activity = Activity(
          id: 'act',
          locationId: 'loc',
          locationName: 'Loc',
          timeSlot: 'morning',
          sortOrder: 0,
        );

        final updated = trip.addActivityToDay(1, activity);

        expect(updated.days[0].activities, hasLength(1));
        expect(updated.days[1].activities, isEmpty);
      });
    });

    group('addDay()', () {
      test('should add day with next number', () {
        final trip = createTestTrip(
          days: [const TripDay(dayNumber: 1), const TripDay(dayNumber: 2)],
        );

        final updated = trip.addDay();

        expect(updated.days, hasLength(3));
        expect(updated.days[2].dayNumber, 3);
      });

      test('should add first day when empty', () {
        final emptyTrip = createTestTrip();
        final updated = emptyTrip.addDay();

        expect(updated.days, hasLength(1));
        expect(updated.days[0].dayNumber, 1);
      });
    });

    group('fromPendingState()', () {
      test('should create trip from pending state', () {
        final pendingActivities = [
          PendingActivity(
            id: 'pa-1',
            dayIndex: 0,
            timeSlot: TimeSlot.morning,
            locationId: 'loc-1',
            locationName: 'Location 1',
            emoji: '🍜',
            destinationId: 'dest-1',
            destinationName: 'Đà Lạt',
            addedAt: DateTime.now(),
          ),
          PendingActivity(
            id: 'pa-2',
            dayIndex: 1,
            timeSlot: TimeSlot.afternoon,
            locationId: 'loc-2',
            locationName: 'Location 2',
            destinationId: 'dest-1',
            destinationName: 'Đà Lạt',
            addedAt: DateTime.now(),
          ),
        ];

        final pendingState = PendingTripState(
          activities: pendingActivities,
          manualDayCount: 3,
        );

        final trip = Trip.fromPendingState(
          id: 'new-trip-id',
          userId: 'user-1',
          pendingState: pendingState,
          destinationId: 'dest-1',
          destinationName: 'Đà Lạt',
        );

        expect(trip.id, 'new-trip-id');
        expect(trip.userId, 'user-1');
        expect(trip.name, 'Đà Lạt Trip');
        expect(trip.days, hasLength(3));
        expect(trip.days[0].activities, hasLength(1));
        expect(trip.days[0].activities[0].locationName, 'Location 1');
        expect(trip.days[1].activities, hasLength(1));
        expect(trip.days[2].activities, isEmpty);
      });

      test('should handle empty pending state', () {
        const pendingState = PendingTripState();

        final trip = Trip.fromPendingState(
          id: 'trip',
          userId: 'user',
          pendingState: pendingState,
          destinationId: 'dest',
          destinationName: 'Destination',
        );

        expect(trip.days, hasLength(3)); // default manualDayCount
        expect(trip.totalActivities, 0);
      });
    });

    group('addFromPendingState()', () {
      test('should add activities from pending state', () {
        final existingTrip = createTestTrip(
          days: [
            TripDay(
              dayNumber: 1,
              activities: [
                const Activity(
                  id: 'existing',
                  locationId: 'existing-loc',
                  locationName: 'Existing',
                  timeSlot: 'morning',
                  sortOrder: 0,
                ),
              ],
            ),
          ],
        );

        final newPendingActivities = [
          PendingActivity(
            id: 'new-pa',
            dayIndex: 0,
            timeSlot: TimeSlot.afternoon,
            locationId: 'new-loc',
            locationName: 'New Location',
            destinationId: 'dest-1',
            destinationName: 'Đà Lạt',
            addedAt: DateTime.now(),
          ),
        ];

        final pendingState = PendingTripState(activities: newPendingActivities);
        final updated = existingTrip.addFromPendingState(pendingState);

        expect(updated.days[0].activities, hasLength(2));
        expect(updated.days[0].activities[0].id, 'existing');
        expect(updated.days[0].activities[1].id, 'new-pa');
      });

      test('should expand days if needed', () {
        final trip = createTestTrip(days: [const TripDay(dayNumber: 1)]);

        final pendingState = PendingTripState(
          activities: [
            PendingActivity(
              id: 'pa',
              dayIndex: 2, // Day 3 (0-indexed)
              timeSlot: TimeSlot.morning,
              locationId: 'loc',
              locationName: 'Location',
              destinationId: 'dest-1',
              destinationName: 'Đà Lạt',
              addedAt: DateTime.now(),
            ),
          ],
          manualDayCount: 4,
        );

        final updated = trip.addFromPendingState(pendingState);

        expect(updated.days, hasLength(4));
        expect(updated.days[2].activities, hasLength(1));
      });
    });

    group('equality', () {
      test('should be equal if same id', () {
        final trip1 = createTestTrip();
        final trip2 = createTestTrip(name: 'Different Name');

        expect(trip1, equals(trip2));
      });

      test('should not be equal if different id', () {
        final trip1 = createTestTrip(id: 'id-1');
        final trip2 = createTestTrip(id: 'id-2');

        expect(trip1, isNot(equals(trip2)));
      });
    });

    test('toString should return readable format', () {
      final trip = createTestTrip(
        days: [const TripDay(dayNumber: 1), const TripDay(dayNumber: 2)],
      );

      expect(trip.toString(), contains('Trip(id: trip-1'));
    });
  });
}
