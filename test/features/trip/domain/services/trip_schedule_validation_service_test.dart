import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/pending_activity.dart';
import 'package:tour_vn/features/trip/domain/entities/schedule_validation_result.dart';
import 'package:tour_vn/features/trip/domain/entities/time_slot.dart';
import 'package:tour_vn/features/trip/domain/services/trip_schedule_validation_service.dart';

void main() {
  late TripScheduleValidationService service;

  setUp(() {
    service = TripScheduleValidationService();
  });

  PendingActivity createTestActivity({
    String id = 'test-id',
    int dayIndex = 0,
    TimeSlot timeSlot = TimeSlot.morning,
    String locationId = 'loc-1',
    String locationName = 'Test Location',
    String destinationId = 'da-nang',
    String destinationName = 'Đà Nẵng',
  }) {
    return PendingActivity(
      id: id,
      dayIndex: dayIndex,
      timeSlot: timeSlot,
      locationId: locationId,
      locationName: locationName,
      destinationId: destinationId,
      destinationName: destinationName,
      addedAt: DateTime.now(),
    );
  }

  group('TripScheduleValidationService', () {
    group('validateActivityAddition', () {
      test('should return valid for empty day', () {
        final result = service.validateActivityAddition(
          existingActivities: [],
          targetDayIndex: 0,
          activityDestinationId: 'da-nang',
          activityDestinationName: 'Đà Nẵng',
        );

        expect(result.isValid, true);
        expect(result.warningType, ScheduleWarningType.none);
        expect(result.hasWarning, false);
      });

      test('should return valid for same destination (AC4)', () {
        final activities = [
          createTestActivity(
            dayIndex: 0,
            destinationId: 'da-nang',
            destinationName: 'Đà Nẵng',
          ),
        ];

        final result = service.validateActivityAddition(
          existingActivities: activities,
          targetDayIndex: 0,
          activityDestinationId: 'da-nang',
          activityDestinationName: 'Đà Nẵng',
        );

        expect(result.isValid, true);
        expect(result.warningType, ScheduleWarningType.none);
      });

      test(
        'should return adjacent warning for adjacent destinations (AC5)',
        () {
          // Đà Nẵng - Hội An: 30km
          final activities = [
            createTestActivity(
              dayIndex: 0,
              destinationId: 'da-nang',
              destinationName: 'Đà Nẵng',
            ),
          ];

          final result = service.validateActivityAddition(
            existingActivities: activities,
            targetDayIndex: 0,
            activityDestinationId: 'hoi-an',
            activityDestinationName: 'Hội An',
          );

          expect(result.isValid, true);
          expect(result.warningType, ScheduleWarningType.adjacentDestination);
          expect(result.distanceKm, 30);
          expect(result.travelTimeMin, 45);
          expect(result.warningMessage, isNotNull);
        },
      );

      test(
        'should return different warning for different destinations (AC6)',
        () {
          // Đà Nẵng - Huế: 100km
          final activities = [
            createTestActivity(
              dayIndex: 0,
              destinationId: 'da-nang',
              destinationName: 'Đà Nẵng',
            ),
          ];

          final result = service.validateActivityAddition(
            existingActivities: activities,
            targetDayIndex: 0,
            activityDestinationId: 'hue',
            activityDestinationName: 'Huế',
          );

          expect(result.isValid, true);
          expect(result.warningType, ScheduleWarningType.differentDestination);
          expect(result.distanceKm, 100);
          expect(result.travelTimeMin, 180);
          expect(result.warningMessage, contains('di chuyển'));
        },
      );

      test('should return distant warning for distant destinations (AC7)', () {
        // Hà Nội - Sa Pa: 320km
        final activities = [
          createTestActivity(
            dayIndex: 0,
            destinationId: 'ha-noi',
            destinationName: 'Hà Nội',
          ),
        ];

        final result = service.validateActivityAddition(
          existingActivities: activities,
          targetDayIndex: 0,
          activityDestinationId: 'sapa',
          activityDestinationName: 'Sa Pa',
        );

        expect(result.isValid, true);
        expect(result.warningType, ScheduleWarningType.distantDestination);
        expect(result.distanceKm, 320);
        expect(result.warningMessage, contains('⚠️'));
      });

      test('should handle empty day with no conflict (AC9)', () {
        final activities = [
          createTestActivity(
            dayIndex: 1, // Different day
            destinationId: 'da-nang',
            destinationName: 'Đà Nẵng',
          ),
        ];

        final result = service.validateActivityAddition(
          existingActivities: activities,
          targetDayIndex: 0, // Empty day
          activityDestinationId: 'hue',
          activityDestinationName: 'Huế',
        );

        expect(result.isValid, true);
        expect(result.warningType, ScheduleWarningType.none);
      });

      test('should handle legacy data with null destination (AC10)', () {
        final activities = [
          PendingActivity(
            id: 'legacy-1',
            dayIndex: 0,
            timeSlot: TimeSlot.morning,
            locationId: 'loc-1',
            locationName: 'Legacy Location',
            destinationId: '', // Empty/legacy
            destinationName: '',
            addedAt: DateTime.now(),
          ),
        ];

        final result = service.validateActivityAddition(
          existingActivities: activities,
          targetDayIndex: 0,
          activityDestinationId: 'da-nang',
          activityDestinationName: 'Đà Nẵng',
        );

        expect(result.isValid, true);
        expect(result.warningType, ScheduleWarningType.none);
      });

      test('should handle unknown destination pair gracefully', () {
        final activities = [
          createTestActivity(
            dayIndex: 0,
            destinationId: 'unknown-city',
            destinationName: 'Unknown',
          ),
        ];

        final result = service.validateActivityAddition(
          existingActivities: activities,
          targetDayIndex: 0,
          activityDestinationId: 'another-unknown',
          activityDestinationName: 'Another Unknown',
        );

        expect(result.isValid, true);
        expect(result.warningType, ScheduleWarningType.none);
      });

      test('should suggest optimal day when conflict found', () {
        final activities = [
          createTestActivity(
            dayIndex: 0,
            destinationId: 'da-nang',
            destinationName: 'Đà Nẵng',
          ),
          createTestActivity(
            id: 'act-2',
            dayIndex: 1,
            destinationId: 'hue',
            destinationName: 'Huế',
          ),
        ];

        // Adding Huế activity to Đà Nẵng day (Day 0)
        final result = service.validateActivityAddition(
          existingActivities: activities,
          targetDayIndex: 0,
          activityDestinationId: 'hue',
          activityDestinationName: 'Huế',
        );

        expect(result.suggestedDayIndex, 1); // Suggest Day 1 which has Huế
      });
    });

    group('suggestOptimalDayForActivity (AC8)', () {
      test('should suggest day with matching destination', () {
        final activities = [
          createTestActivity(
            dayIndex: 0,
            destinationId: 'da-nang',
            destinationName: 'Đà Nẵng',
          ),
          createTestActivity(
            id: 'act-2',
            dayIndex: 1,
            destinationId: 'hue',
            destinationName: 'Huế',
          ),
        ];

        final suggestedDay = service.suggestOptimalDayForActivity(
          activities: activities,
          totalDays: 3,
          destinationId: 'hue',
        );

        expect(suggestedDay, 1); // Day 2 has Huế
      });

      test('should suggest empty day if no matching destination', () {
        final activities = [
          createTestActivity(
            dayIndex: 0,
            destinationId: 'da-nang',
            destinationName: 'Đà Nẵng',
          ),
        ];

        final suggestedDay = service.suggestOptimalDayForActivity(
          activities: activities,
          totalDays: 3,
          destinationId: 'hue', // Not in any day
        );

        expect(suggestedDay, 1); // First empty day
      });

      test('should return null if all days occupied and no match', () {
        final activities = [
          createTestActivity(dayIndex: 0),
          createTestActivity(id: 'act-2', dayIndex: 1),
          createTestActivity(id: 'act-3', dayIndex: 2),
        ];

        final suggestedDay = service.suggestOptimalDayForActivity(
          activities: activities,
          totalDays: 3,
          destinationId: 'unknown-dest',
        );

        expect(suggestedDay, isNull);
      });

      test(
        'should return first day with matching destination when multiple exist',
        () {
          final activities = [
            createTestActivity(
              dayIndex: 0,
              destinationId: 'da-nang',
              destinationName: 'Đà Nẵng',
            ),
            createTestActivity(
              id: 'act-2',
              dayIndex: 1,
              destinationId: 'hue',
              destinationName: 'Huế',
            ),
            createTestActivity(
              id: 'act-3',
              dayIndex: 2,
              destinationId: 'hue',
              destinationName: 'Huế',
            ),
          ];

          final suggestedDay = service.suggestOptimalDayForActivity(
            activities: activities,
            totalDays: 3,
            destinationId: 'hue',
          );

          expect(suggestedDay, 1); // First day with Huế
        },
      );
    });

    group('getDistanceBetween', () {
      test('should return distance for known pair', () {
        final distance = service.getDistanceBetween('da-nang', 'hue');

        expect(distance, isNotNull);
        expect(distance!.distanceKm, 100);
        expect(distance.travelTimeMin, 180);
      });

      test('should return null for unknown pair', () {
        final distance = service.getDistanceBetween('unknown-1', 'unknown-2');

        expect(distance, isNull);
      });

      test('should work bidirectionally', () {
        final forward = service.getDistanceBetween('da-nang', 'hoi-an');
        final reverse = service.getDistanceBetween('hoi-an', 'da-nang');

        expect(forward, equals(reverse));
      });
    });

    group('warning messages', () {
      test('adjacent message should mention both destinations', () {
        final activities = [
          createTestActivity(
            destinationId: 'da-nang',
            destinationName: 'Đà Nẵng',
          ),
        ];

        final result = service.validateActivityAddition(
          existingActivities: activities,
          targetDayIndex: 0,
          activityDestinationId: 'hoi-an',
          activityDestinationName: 'Hội An',
        );

        expect(result.warningMessage, contains('Hội An'));
        expect(result.warningMessage, contains('Đà Nẵng'));
        expect(result.warningMessage, contains('cùng ngày'));
      });

      test('different message should suggest splitting days', () {
        final activities = [
          createTestActivity(
            destinationId: 'da-nang',
            destinationName: 'Đà Nẵng',
          ),
        ];

        final result = service.validateActivityAddition(
          existingActivities: activities,
          targetDayIndex: 0,
          activityDestinationId: 'hue',
          activityDestinationName: 'Huế',
        );

        expect(result.warningMessage, contains('Cân nhắc'));
      });

      test('distant message should warn about impracticality', () {
        final activities = [
          createTestActivity(
            destinationId: 'ha-noi',
            destinationName: 'Hà Nội',
          ),
        ];

        final result = service.validateActivityAddition(
          existingActivities: activities,
          targetDayIndex: 0,
          activityDestinationId: 'sapa',
          activityDestinationName: 'Sa Pa',
        );

        expect(result.warningMessage, contains('Khó thực hiện'));
        expect(result.warningMessage, contains('⚠️'));
      });
    });
  });
}
