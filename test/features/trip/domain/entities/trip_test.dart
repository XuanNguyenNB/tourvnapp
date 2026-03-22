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

    test('toMap serializes dates as ISO strings', () {
      final trip = createTestTrip();
      final map = trip.toMap();

      expect(map['id'], 'trip-1');
      expect(map['userId'], 'user-1');
      expect(map['name'], 'Test Trip');
      expect(map['destinationId'], 'dest-1');
      expect(map['destinationName'], 'Đà Lạt');
      expect(map['days'], isEmpty);
      expect(map['createdAt'], fixedDate.toIso8601String());
      expect(map['updatedAt'], fixedDate.toIso8601String());
    });

    test('fromMap deserializes ISO string dates correctly', () {
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
        'createdAt': fixedDate.toIso8601String(),
        'updatedAt': fixedDate.toIso8601String(),
      };

      final trip = Trip.fromMap(map);

      expect(trip.id, 'trip-1');
      expect(trip.name, 'Đà Lạt Trip');
      expect(trip.createdAt, fixedDate);
      expect(trip.updatedAt, fixedDate);
      expect(trip.days, hasLength(1));
      expect(trip.days.first.activities.first.locationName, 'Location 1');
    });

    test('computed properties count days and activities', () {
      final trip = createTestTrip(
        days: [
          TripDay(
            dayNumber: 1,
            activities: const [
              Activity(
                id: 'a1',
                locationId: 'l1',
                locationName: 'Loc 1',
                timeSlot: 'morning',
                sortOrder: 0,
              ),
            ],
          ),
          TripDay(
            dayNumber: 2,
            activities: const [
              Activity(
                id: 'a2',
                locationId: 'l2',
                locationName: 'Loc 2',
                timeSlot: 'noon',
                sortOrder: 1,
              ),
              Activity(
                id: 'a3',
                locationId: 'l3',
                locationName: 'Loc 3',
                timeSlot: 'afternoon',
                sortOrder: 2,
              ),
            ],
          ),
        ],
      );

      expect(trip.totalDays, 2);
      expect(trip.totalActivities, 3);
    });

    test('fromPendingState creates default trip name from destination', () {
      final pendingState = PendingTripState(
        activities: [
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
        ],
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
      expect(trip.name, 'Khám phá Đà Lạt');
      expect(trip.days, hasLength(3));
      expect(trip.days[0].activities, hasLength(1));
      expect(trip.days[1].activities, hasLength(1));
      expect(trip.days[2].activities, isEmpty);
    });

    test('addFromPendingState appends new activities and expands days', () {
      final existingTrip = createTestTrip(
        days: [
          TripDay(
            dayNumber: 1,
            activities: const [
              Activity(
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

      final pendingState = PendingTripState(
        activities: [
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
          PendingActivity(
            id: 'new-pa-2',
            dayIndex: 2,
            timeSlot: TimeSlot.morning,
            locationId: 'new-loc-2',
            locationName: 'New Location 2',
            destinationId: 'dest-1',
            destinationName: 'Đà Lạt',
            addedAt: DateTime.now(),
          ),
        ],
        manualDayCount: 4,
      );

      final updated = existingTrip.addFromPendingState(pendingState);

      expect(updated.days, hasLength(4));
      expect(updated.days[0].activities, hasLength(2));
      expect(updated.days[2].activities, hasLength(1));
    });
  });
}
