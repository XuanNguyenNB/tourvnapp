import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/schedule_optimization_result.dart';
import 'package:tour_vn/features/trip/domain/entities/trip_day.dart';
import 'package:tour_vn/features/trip/domain/entities/activity.dart';
import 'package:tour_vn/features/trip/domain/entities/time_slot.dart';

void main() {
  group('OptimizationChange', () {
    test('supports value equality', () {
      const change1 = OptimizationChange(
        fromDay: 1,
        toDay: 2,
        activityName: 'Test Activity',
        reason: 'Test reason',
      );

      const change2 = OptimizationChange(
        fromDay: 1,
        toDay: 2,
        activityName: 'Test Activity',
        reason: 'Test reason',
      );

      const change3 = OptimizationChange(
        fromDay: 1,
        toDay: 3,
        activityName: 'Test Activity',
        reason: 'Test reason',
      );

      expect(change1, equals(change2));
      expect(change1.hashCode, equals(change2.hashCode));

      expect(change1, isNot(equals(change3)));
      expect(change1.hashCode, isNot(equals(change3.hashCode)));
    });
  });

  group('ScheduleOptimizationResult', () {
    late List<TripDay> mockDays;

    setUp(() {
      mockDays = [
        TripDay(
          dayNumber: 1,
          activities: [
            Activity(
              id: 'a1',
              locationId: 'l1',
              locationName: 'Location 1',
              timeSlot: 'morning',
              sortOrder: 0,
            ),
          ],
        ),
      ];
    });

    test('supports value equality', () {
      final result1 = ScheduleOptimizationResult(
        optimizedDays: mockDays,
        totalTravelTimeSavedMin: 30,
        totalDistanceSavedKm: 15.5,
        changes: const [
          OptimizationChange(
            fromDay: 2,
            toDay: 1,
            activityName: 'Location 1',
            reason: 'Group by destination',
          ),
        ],
        originalTravelTimeMin: 120,
        optimizedTravelTimeMin: 90,
      );

      final result2 = ScheduleOptimizationResult(
        optimizedDays: mockDays,
        totalTravelTimeSavedMin: 30,
        totalDistanceSavedKm: 15.5,
        changes: const [
          OptimizationChange(
            fromDay: 2,
            toDay: 1,
            activityName: 'Location 1',
            reason: 'Group by destination',
          ),
        ],
        originalTravelTimeMin: 120,
        optimizedTravelTimeMin: 90,
      );

      final result3 = ScheduleOptimizationResult(
        optimizedDays: mockDays,
        totalTravelTimeSavedMin: 0,
        totalDistanceSavedKm: 0.0,
        changes: const [],
        originalTravelTimeMin: 120,
        optimizedTravelTimeMin: 120,
      );

      expect(result1, equals(result2));
      expect(result1.hashCode, equals(result2.hashCode));

      expect(result1, isNot(equals(result3)));
      expect(result1.hashCode, isNot(equals(result3.hashCode)));
    });

    test('noChanges factory creates empty result correctly', () {
      final result = ScheduleOptimizationResult.noChanges(
        originalDays: mockDays,
        originalTravelTimeMin: 45,
      );

      expect(result.optimizedDays, equals(mockDays));
      expect(result.totalTravelTimeSavedMin, equals(0));
      expect(result.totalDistanceSavedKm, equals(0.0));
      expect(result.changes, isEmpty);
      expect(result.hasChanges, isFalse);
      expect(result.originalTravelTimeMin, equals(45));
      expect(result.optimizedTravelTimeMin, equals(45));
    });

    test('hasChanges returns true when changes exist', () {
      final result = ScheduleOptimizationResult(
        optimizedDays: mockDays,
        totalTravelTimeSavedMin: 10,
        totalDistanceSavedKm: 5.0,
        changes: const [
          OptimizationChange(
            fromDay: 1,
            toDay: 2,
            activityName: 'Test',
            reason: 'Reason',
          ),
        ],
        originalTravelTimeMin: 10,
        optimizedTravelTimeMin: 0,
      );

      expect(result.hasChanges, isTrue);
    });
  });
}
