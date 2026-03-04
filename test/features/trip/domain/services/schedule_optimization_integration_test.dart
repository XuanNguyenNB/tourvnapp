import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/activity.dart';
import 'package:tour_vn/features/trip/domain/entities/trip.dart';
import 'package:tour_vn/features/trip/domain/entities/trip_day.dart';
import 'package:tour_vn/features/trip/domain/services/schedule_optimization_service.dart';

void main() {
  group('ScheduleOptimization Integration Tests', () {
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

    test('optimizes a real-world multi-destination trip accurately', () {
      // Scenario: A 4-day trip covering Da Nang, Hoi An, and Hue.
      // Initially, the user puts Da Nang (Day 1), Hue (Day 2), Hoi An (Day 3), Hue (Day 4).
      // This is highly unoptimized because Da Nang->Hue is far, then Hue->Hoi An is far, then Hoi An->Hue is far.

      final trip = createTrip([
        TripDay(
          dayNumber: 1,
          activities: [
            createActivity('a1', 'da-nang', 'My Khe Beach', 'morning', 0),
            createActivity('a2', 'da-nang', 'Son Tra', 'afternoon', 1),
          ],
        ),
        TripDay(
          dayNumber: 2,
          activities: [
            createActivity('a3', 'hue', 'Imperial City', 'morning', 0),
          ],
        ),
        TripDay(
          dayNumber: 3,
          activities: [
            createActivity('a4', 'hoi-an', 'Ancient Town', 'morning', 0),
          ],
        ),
        TripDay(
          dayNumber: 4,
          activities: [
            createActivity('a5', 'hue', 'Thien Mu Pagoda', 'morning', 0),
          ],
        ),
      ]);

      final result = service.optimizeSchedule(trip);

      expect(result.hasChanges, isTrue);

      // Expected logic:
      // Da Nang has 2 activities. Hue has 2. Hoi An has 1. Pick Da Nang as starting destination (earliest appearance).
      // Then sequence from Da Nang: nearest neighbor is Hoi An (30km). Next nearest is Hue (130km from Hoi An).
      // Order of destinations: Da Nang -> Hoi An -> Hue.

      // So Days 1 will have Da Nang, Day 2 will have Hoi An, Days 3 & 4 will have Hue.
      expect(result.optimizedDays[0].primaryDestinationId, equals('da-nang'));
      expect(result.optimizedDays[1].primaryDestinationId, equals('hoi-an'));
      expect(result.optimizedDays[2].primaryDestinationId, equals('hue'));
      expect(result.optimizedDays[3].primaryDestinationId, equals('hue'));

      // Travel time checking
      // Original sequence: Da Nang -> Hue (100km, 180m) -> Hoi An (130km, 210m) -> Hue (130km, 210m).
      // Total Original Time: 180 + 210 + 210 = 600 mins
      // Distance: 100 + 130 + 130 = 360 km

      // New sequence: Da Nang -> Hoi An (30km, 45m) -> Hue (130km, 210m) -> Hue (0)
      // Total Optimized Time: 45 + 210 = 255 mins
      // Distance: 30 + 130 = 160 km

      // Saved Time: 600 - 255 = 345 mins
      // Saved Distance = 360 - 160 = 200 km

      expect(result.totalTravelTimeSavedMin, equals(345));
      expect(result.totalDistanceSavedKm, equals(200.0));
    });

    test('preserves all activities after optimization (round-trip)', () {
      final trip = createTrip([
        TripDay(
          dayNumber: 1,
          activities: [
            createActivity('a1', 'ho-chi-minh', 'Ben Thanh', 'morning', 0),
            createActivity('a2', 'vung-tau', 'Back Beach', 'afternoon', 1),
          ],
        ),
        TripDay(
          dayNumber: 2,
          activities: [
            createActivity(
              'a3',
              'ho-chi-minh',
              'Independence Palace',
              'morning',
              0,
            ),
          ],
        ),
      ]);

      final result = service.optimizeSchedule(trip);

      final originalActivitiesCount = trip.totalActivities;
      final optimizedActivitiesCount = result.optimizedDays.fold<int>(
        0,
        (prev, day) => prev + day.activities.length,
      );

      expect(originalActivitiesCount, equals(optimizedActivitiesCount));

      final originalIds = trip.days
          .expand((d) => d.activities)
          .map((a) => a.id)
          .toSet();
      final optimizedIds = result.optimizedDays
          .expand((d) => d.activities)
          .map((a) => a.id)
          .toSet();

      expect(originalIds.containsAll(optimizedIds), isTrue);
      expect(optimizedIds.containsAll(originalIds), isTrue);
    });

    test('works with mixed legacy (null destination) and new activities', () {
      final trip = createTrip([
        TripDay(
          dayNumber: 1,
          activities: [
            createActivity('a1', 'da-lat', 'Xuan Huong Lake', 'morning', 0),
            Activity(
              id: 'legacy1',
              locationId: 'loc_leg1',
              locationName: 'Unknown Cafe',
              timeSlot: 'afternoon',
              sortOrder: 1,
              destinationId: null,
            ),
          ],
        ),
        TripDay(
          dayNumber: 2,
          activities: [
            createActivity('a2', 'ho-chi-minh', 'Ben Thanh', 'morning', 0),
            createActivity('a3', 'da-lat', 'LangBiang', 'afternoon', 1),
          ],
        ),
      ]);

      final result = service.optimizeSchedule(trip);

      // Verify legacy activity stays on day 1 slot 2 (index 1)
      expect(result.optimizedDays[0].activities.length, equals(2));
      expect(result.optimizedDays[0].activities[1].id, equals('legacy1'));

      // Da-lat should group together. Ho Chi Minh will be pushed to the end or beginning.
      // Da-lat has 2 items, Ho Chi Minh has 1. Starting destination should be da-lat.
      // Day 1 has Da-lat. Day 2 has Da-lat. So `a1` is Day 1[0]. `a3` is Day 2[0]. `a2` (Ho Chi Minh) is Day 2[1].. wait.
      // Legacy takes its original spot (Day 1 slot 1).
      // Valid are a1(da-lat), a2(ho-chi-minh), a3(da-lat).
      // Assigned order: a1, a3, a2.
      // Day 1: [a1, legacy1].
      // Day 2: [a3, a2]. TimeSlots for day 2: a3(afternoon), a2(morning). Sort -> a2, a3.
      // So Day 2: [a2, a3].

      expect(result.optimizedDays[1].activities[0].id, equals('a2')); // morning
      expect(
        result.optimizedDays[1].activities[1].id,
        equals('a3'),
      ); // afternoon
    });
  });
}
