import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/activity.dart';
import 'package:tour_vn/features/trip/domain/entities/trip.dart';
import 'package:tour_vn/features/trip/domain/entities/trip_day.dart';
import 'package:tour_vn/features/trip/domain/services/schedule_optimization_service.dart';

void main() {
  late ScheduleOptimizationService service;

  setUp(() {
    service = ScheduleOptimizationService();
  });

  Activity createActivity(
    String id,
    String destId,
    String name,
    String slot,
    int order,
  ) {
    return Activity(
      id: id,
      locationId: 'loc_$id',
      locationName: name,
      timeSlot: slot,
      sortOrder: order,
      destinationId: destId,
      destinationName: 'Dest_$destId',
    );
  }

  Trip createTrip(List<TripDay> days) {
    return Trip(
      id: 'trip1',
      userId: 'user1',
      name: 'Test Trip',
      destinationId: 'multi',
      destinationName: 'Multi',
      days: days,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  group('ScheduleOptimizationService Edge Cases', () {
    test('returns original schedule when there is only 1 day', () {
      final trip = createTrip([
        TripDay(
          dayNumber: 1,
          activities: [createActivity('1', 'da-nang', 'Beach', 'morning', 0)],
        ),
      ]);

      final result = service.optimizeSchedule(trip);

      expect(result.hasChanges, isFalse);
      expect(result.optimizedDays.length, equals(1));
    });

    test(
      'returns original schedule when all activities share same destination',
      () {
        final trip = createTrip([
          TripDay(
            dayNumber: 1,
            activities: [createActivity('1', 'da-nang', 'Beach', 'morning', 0)],
          ),
          TripDay(
            dayNumber: 2,
            activities: [
              createActivity('2', 'da-nang', 'Mountain', 'afternoon', 0),
            ],
          ),
        ]);

        final result = service.optimizeSchedule(trip);

        expect(result.hasChanges, isFalse);
      },
    );

    test(
      'keeps activities with null destinationId in their original relative position',
      () {
        final trip = createTrip([
          TripDay(
            dayNumber: 1,
            activities: [
              createActivity('1', 'ha-noi', 'Old Quarter', 'morning', 0),
              Activity(
                id: 'null1',
                locationId: 'loc_null',
                locationName: 'Null Place',
                timeSlot: 'afternoon',
                sortOrder: 1,
                destinationId: null,
              ),
            ],
          ),
          TripDay(
            dayNumber: 2,
            activities: [
              createActivity('2', 'ha-noi', 'Hoan Kiem', 'morning', 0),
              createActivity('3', 'ninh-binh', 'Trang An', 'afternoon', 1),
            ],
          ),
        ]);

        final result = service.optimizeSchedule(trip);

        // Null activity was on day 1 slot 2. Should stay there.
        expect(result.optimizedDays[0].activities[1].id, equals('null1'));
      },
    );
  });

  group('ScheduleOptimizationService Core Logic', () {
    test('groups same-destination activities together', () {
      // Day 1: HN, NB. Day 2: HN, NB.
      // Expected Day 1: HN, HN. Day 2: NB, NB.
      final trip = createTrip([
        TripDay(
          dayNumber: 1,
          activities: [
            createActivity('1', 'ha-noi', 'HN1', 'morning', 0),
            createActivity('2', 'ninh-binh', 'NB1', 'afternoon', 1),
          ],
        ),
        TripDay(
          dayNumber: 2,
          activities: [
            createActivity('3', 'ha-noi', 'HN2', 'morning', 0),
            createActivity('4', 'ninh-binh', 'NB2', 'afternoon', 1),
          ],
        ),
      ]);

      final result = service.optimizeSchedule(trip);

      expect(result.hasChanges, isTrue);
      // Because HN has 2, NB has 2. Priority based on earliest appearance after counting.
      // Usually HN gets grouped to day 1 since it's the starting dest.
      final day1Dests = result.optimizedDays[0].activities
          .map((a) => a.destinationId)
          .toSet();
      final day2Dests = result.optimizedDays[1].activities
          .map((a) => a.destinationId)
          .toSet();

      expect(day1Dests.length, equals(1));
      expect(day2Dests.length, equals(1));
      expect(day1Dests.first, isNot(equals(day2Dests.first)));

      // Ensure timeSlot order is preserved
      if (day1Dests.first == 'ha-noi') {
        expect(
          result.optimizedDays[0].activities[0].timeSlot,
          equals('morning'),
        );
        expect(
          result.optimizedDays[0].activities[1].timeSlot,
          equals('morning'),
        );
      } else {
        expect(
          result.optimizedDays[0].activities[0].timeSlot,
          equals('afternoon'),
        );
        expect(
          result.optimizedDays[0].activities[1].timeSlot,
          equals('afternoon'),
        );
      }
    });

    test('reorders destinations by nearest neighbor heuristic', () {
      // Trip: Hue -> Da Nang -> Hoi An
      // Given distances: Hue->Da Nang(100), Da Nang->Hoi An(30), Hue->Hoi An(130).
      // Let's create an unoptimized sequence: Hoi An(1) -> Hue(2) -> Da Nang(3)
      final trip = createTrip([
        TripDay(
          dayNumber: 1,
          activities: [
            createActivity('1', 'hoi-an', 'HA1', 'morning', 0),
            createActivity('2', 'hoi-an', 'HA2', 'afternoon', 1),
          ],
        ),
        TripDay(
          dayNumber: 2,
          activities: [createActivity('3', 'hue', 'HUE1', 'morning', 0)],
        ),
        TripDay(
          dayNumber: 3,
          activities: [createActivity('4', 'da-nang', 'DN1', 'morning', 0)],
        ),
      ]);

      final result = service.optimizeSchedule(trip);

      // Hoi-an has 2 activities, so it starts at Hoi An. Nearest is Da Nang(30), then Hue(100 from Da Nang).
      // Ordered days: Hoi An -> Da Nang -> Hue.

      expect(result.hasChanges, isTrue);
      expect(result.optimizedDays.length, equals(3));

      expect(result.optimizedDays[0].primaryDestinationId, equals('hoi-an'));
      expect(result.optimizedDays[1].primaryDestinationId, equals('da-nang'));
      expect(result.optimizedDays[2].primaryDestinationId, equals('hue'));

      expect(
        result.totalDistanceSavedKm,
        equals((130 + 100) - (30 + 100)),
      ); // 230 - 130 = 100
      expect(result.totalTravelTimeSavedMin, greaterThan(0));
    });

    test('verifies data loss does not occur', () {
      final trip = createTrip([
        TripDay(
          dayNumber: 1,
          activities: [
            createActivity('1', 'ha-noi', 'HN1', 'morning', 0),
            createActivity('2', 'ninh-binh', 'NB1', 'afternoon', 1),
          ],
        ),
        TripDay(
          dayNumber: 2,
          activities: [
            createActivity('3', 'ha-noi', 'HN2', 'morning', 0),
            createActivity('4', 'ninh-binh', 'NB2', 'afternoon', 1),
          ],
        ),
      ]);

      final result = service.optimizeSchedule(trip);

      final originalIds = trip.days
          .expand((d) => d.activities)
          .map((a) => a.id)
          .toSet();
      final optimizedIds = result.optimizedDays
          .expand((d) => d.activities)
          .map((a) => a.id)
          .toSet();

      expect(originalIds.length, equals(optimizedIds.length));
      expect(originalIds.containsAll(optimizedIds), isTrue);
    });
  });
}
