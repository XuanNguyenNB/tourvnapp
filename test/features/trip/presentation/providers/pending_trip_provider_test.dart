import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tour_vn/features/trip/domain/entities/pending_activity.dart';
import 'package:tour_vn/features/trip/domain/entities/time_slot.dart';
import 'package:tour_vn/features/trip/presentation/providers/pending_trip_provider.dart';

void main() {
  group('PendingTripState', () {
    test('should start with empty activities and default 3 days', () {
      const state = PendingTripState();

      expect(state.isEmpty, isTrue);
      expect(state.isNotEmpty, isFalse);
      expect(state.count, equals(0));
      expect(state.totalDays, equals(3)); // Default manualDayCount
      expect(state.manualDayCount, equals(3));
    });

    test('should report isEmpty correctly', () {
      final activity = _createTestActivity(dayIndex: 0);
      final state = PendingTripState(activities: [activity]);

      expect(state.isEmpty, isFalse);
      expect(state.isNotEmpty, isTrue);
      expect(state.count, equals(1));
    });

    test(
      'should calculate totalDays as max of activities and manualDayCount',
      () {
        // Activities go up to day index 2 (3 days)
        final activities = [
          _createTestActivity(id: '1', dayIndex: 0),
          _createTestActivity(id: '2', dayIndex: 2),
          _createTestActivity(id: '3', dayIndex: 1),
        ];
        // With default manualDayCount=3, totalDays should be 3 (max of 3, 3)
        final state = PendingTripState(activities: activities);
        expect(state.totalDays, equals(3));

        // With higher manualDayCount, it should take precedence
        final state2 = PendingTripState(
          activities: activities,
          manualDayCount: 5,
        );
        expect(state2.totalDays, equals(5));

        // With lower manualDayCount, activities take precedence
        final state3 = PendingTripState(
          activities: [_createTestActivity(id: '1', dayIndex: 4)],
          manualDayCount: 3,
        );
        expect(state3.totalDays, equals(5)); // dayIndex 4 = 5 days
      },
    );

    test('should group activities by day correctly', () {
      final activities = [
        _createTestActivity(id: '1', dayIndex: 0, name: 'Activity 1'),
        _createTestActivity(id: '2', dayIndex: 0, name: 'Activity 2'),
        _createTestActivity(id: '3', dayIndex: 1, name: 'Activity 3'),
      ];
      final state = PendingTripState(activities: activities);
      final grouped = state.activitiesByDay;

      expect(grouped.keys.length, equals(2));
      expect(grouped[0]?.length, equals(2));
      expect(grouped[1]?.length, equals(1));
    });

    test('copyWith should create new instance with updated values', () {
      const original = PendingTripState();
      final activity = _createTestActivity();
      final updated = original.copyWith(activities: [activity]);

      expect(original.isEmpty, isTrue);
      expect(updated.count, equals(1));
    });

    test('copyWith should update manualDayCount', () {
      const original = PendingTripState();
      final updated = original.copyWith(manualDayCount: 7);

      expect(original.manualDayCount, equals(3));
      expect(updated.manualDayCount, equals(7));
      expect(updated.totalDays, equals(7));
    });
  });

  group('PendingTripNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should start with default 3 days and empty activities', () {
      final state = container.read(pendingTripProvider);

      expect(state.isEmpty, isTrue);
      expect(state.totalDays, equals(3));
    });

    test('addActivity should add activity to state', () {
      final notifier = container.read(pendingTripProvider.notifier);
      final activity = _createTestActivity();

      notifier.addActivity(
        activity,
        destinationId: 'dest-1',
        destinationName: 'Test Destination',
      );

      final state = container.read(pendingTripProvider);
      expect(state.count, equals(1));
      expect(state.activities.first.id, equals(activity.id));
    });

    test('addActivity should accumulate multiple activities', () {
      final notifier = container.read(pendingTripProvider.notifier);

      notifier.addActivity(
        _createTestActivity(id: '1'),
        destinationId: 'dest-1',
        destinationName: 'Test Destination',
      );
      notifier.addActivity(
        _createTestActivity(id: '2'),
        destinationId: 'dest-1',
        destinationName: 'Test Destination',
      );
      notifier.addActivity(
        _createTestActivity(id: '3'),
        destinationId: 'dest-1',
        destinationName: 'Test Destination',
      );

      final state = container.read(pendingTripProvider);
      expect(state.count, equals(3));
    });

    test('removeActivity should remove activity by ID', () {
      final notifier = container.read(pendingTripProvider.notifier);
      final activity1 = _createTestActivity(id: 'to-keep');
      final activity2 = _createTestActivity(id: 'to-remove');

      notifier.addActivity(
        activity1,
        destinationId: 'dest-1',
        destinationName: 'Test Destination',
      );
      notifier.addActivity(
        activity2,
        destinationId: 'dest-1',
        destinationName: 'Test Destination',
      );
      expect(container.read(pendingTripProvider).count, equals(2));

      notifier.removeActivity('to-remove');

      final state = container.read(pendingTripProvider);
      expect(state.count, equals(1));
      expect(state.activities.first.id, equals('to-keep'));
    });

    test(
      'removeActivitiesForDay should remove all activities for that day',
      () {
        final notifier = container.read(pendingTripProvider.notifier);
        notifier.addActivity(
          _createTestActivity(id: '1', dayIndex: 0),
          destinationId: 'dest-1',
          destinationName: 'Test Destination',
        );
        notifier.addActivity(
          _createTestActivity(id: '2', dayIndex: 0),
          destinationId: 'dest-1',
          destinationName: 'Test Destination',
        );
        notifier.addActivity(
          _createTestActivity(id: '3', dayIndex: 1),
          destinationId: 'dest-1',
          destinationName: 'Test Destination',
        );

        notifier.removeActivitiesForDay(0);

        final state = container.read(pendingTripProvider);
        expect(state.count, equals(1));
        expect(state.activities.first.dayIndex, equals(1));
      },
    );

    test('clear should remove all activities and reset days', () {
      final notifier = container.read(pendingTripProvider.notifier);
      notifier.addActivity(
        _createTestActivity(id: '1'),
        destinationId: 'dest-1',
        destinationName: 'Test Destination',
      );
      notifier.addActivity(
        _createTestActivity(id: '2'),
        destinationId: 'dest-1',
        destinationName: 'Test Destination',
      );
      notifier.addNewDay(); // Add an extra day

      notifier.clear();

      final state = container.read(pendingTripProvider);
      expect(state.isEmpty, isTrue);
      expect(state.totalDays, equals(3)); // Reset to default
    });

    test('addNewDay should increase totalDays by one', () {
      final notifier = container.read(pendingTripProvider.notifier);

      expect(container.read(pendingTripProvider).totalDays, equals(3));

      notifier.addNewDay();
      expect(container.read(pendingTripProvider).totalDays, equals(4));

      notifier.addNewDay();
      expect(container.read(pendingTripProvider).totalDays, equals(5));
    });

    test('addNewDay should update manualDayCount', () {
      final notifier = container.read(pendingTripProvider.notifier);

      notifier.addNewDay();
      notifier.addNewDay();

      final state = container.read(pendingTripProvider);
      expect(state.manualDayCount, equals(5)); // 3 default + 2 added
    });

    test('totalDays respects activities beyond manualDayCount', () {
      final notifier = container.read(pendingTripProvider.notifier);

      // Add activity to day 5 (index 4)
      notifier.addActivity(
        _createTestActivity(id: '1', dayIndex: 4),
        destinationId: 'dest-1',
        destinationName: 'Test Destination',
      );

      final state = container.read(pendingTripProvider);
      // totalDays should be 5 (max of 3 manualDayCount, 5 from activities)
      expect(state.totalDays, equals(5));
    });

    test('restoreActivity should add activity back and sort by time slot', () {
      final notifier = container.read(pendingTripProvider.notifier);

      // Add two activities
      notifier.addActivity(
        _createTestActivity(id: '1', dayIndex: 0, timeSlot: TimeSlot.morning),
        destinationId: 'dest-1',
        destinationName: 'Test Destination',
      );
      notifier.addActivity(
        _createTestActivity(id: '3', dayIndex: 0, timeSlot: TimeSlot.evening),
        destinationId: 'dest-1',
        destinationName: 'Test Destination',
      );

      // Create an activity to restore (afternoon - should go between morning and evening)
      final activityToRestore = _createTestActivity(
        id: '2',
        dayIndex: 0,
        timeSlot: TimeSlot.afternoon,
      );

      // Restore it
      notifier.restoreActivity(activityToRestore);

      final state = container.read(pendingTripProvider);
      expect(state.count, equals(3));

      // Verify order: morning, afternoon, evening
      expect(state.activities[0].timeSlot, equals(TimeSlot.morning));
      expect(state.activities[1].timeSlot, equals(TimeSlot.afternoon));
      expect(state.activities[2].timeSlot, equals(TimeSlot.evening));
    });

    // --- Reorder Tests ---
    group('reorderActivitiesForDay', () {
      test('should reorder activities within a day - move first to last', () {
        final notifier = container.read(pendingTripProvider.notifier);

        // Add 3 activities to day 0
        notifier.addActivity(
          _createTestActivity(id: 'a', dayIndex: 0, name: 'First'),
          destinationId: 'dest-1',
          destinationName: 'Test',
        );
        notifier.addActivity(
          _createTestActivity(id: 'b', dayIndex: 0, name: 'Second'),
          destinationId: 'dest-1',
          destinationName: 'Test',
        );
        notifier.addActivity(
          _createTestActivity(id: 'c', dayIndex: 0, name: 'Third'),
          destinationId: 'dest-1',
          destinationName: 'Test',
        );

        // Move first (index 0) to last (index 2)
        notifier.reorderActivitiesForDay(0, 0, 2);

        final state = container.read(pendingTripProvider);
        final dayActivities = state.activities
            .where((a) => a.dayIndex == 0)
            .toList();

        // Order should be: Second, Third, First
        expect(dayActivities[0].id, equals('b'));
        expect(dayActivities[1].id, equals('c'));
        expect(dayActivities[2].id, equals('a'));
      });

      test('should reorder activities within a day - move last to first', () {
        final notifier = container.read(pendingTripProvider.notifier);

        notifier.addActivity(
          _createTestActivity(id: 'a', dayIndex: 0),
          destinationId: 'dest-1',
          destinationName: 'Test',
        );
        notifier.addActivity(
          _createTestActivity(id: 'b', dayIndex: 0),
          destinationId: 'dest-1',
          destinationName: 'Test',
        );
        notifier.addActivity(
          _createTestActivity(id: 'c', dayIndex: 0),
          destinationId: 'dest-1',
          destinationName: 'Test',
        );

        // Move last (index 2) to first (index 0)
        notifier.reorderActivitiesForDay(0, 2, 0);

        final state = container.read(pendingTripProvider);
        final dayActivities = state.activities
            .where((a) => a.dayIndex == 0)
            .toList();

        // Order should be: Third, First, Second
        expect(dayActivities[0].id, equals('c'));
        expect(dayActivities[1].id, equals('a'));
        expect(dayActivities[2].id, equals('b'));
      });

      test('should not change state for same index reorder', () {
        final notifier = container.read(pendingTripProvider.notifier);

        notifier.addActivity(
          _createTestActivity(id: 'a', dayIndex: 0),
          destinationId: 'dest-1',
          destinationName: 'Test',
        );
        notifier.addActivity(
          _createTestActivity(id: 'b', dayIndex: 0),
          destinationId: 'dest-1',
          destinationName: 'Test',
        );

        final beforeState = container.read(pendingTripProvider);

        // Same index - no change
        notifier.reorderActivitiesForDay(0, 1, 1);

        final afterState = container.read(pendingTripProvider);
        expect(
          afterState.activities.length,
          equals(beforeState.activities.length),
        );
      });

      test('should not reorder if only one activity', () {
        final notifier = container.read(pendingTripProvider.notifier);

        notifier.addActivity(
          _createTestActivity(id: 'a', dayIndex: 0),
          destinationId: 'dest-1',
          destinationName: 'Test',
        );

        final beforeState = container.read(pendingTripProvider);

        // Only one activity - should be no-op
        notifier.reorderActivitiesForDay(0, 0, 0);

        final afterState = container.read(pendingTripProvider);
        expect(
          afterState.activities.length,
          equals(beforeState.activities.length),
        );
      });

      test('should only affect the specified day', () {
        final notifier = container.read(pendingTripProvider.notifier);

        // Add activities to day 0
        notifier.addActivity(
          _createTestActivity(id: 'a', dayIndex: 0),
          destinationId: 'dest-1',
          destinationName: 'Test',
        );
        notifier.addActivity(
          _createTestActivity(id: 'b', dayIndex: 0),
          destinationId: 'dest-1',
          destinationName: 'Test',
        );

        // Add activities to day 1
        notifier.addActivity(
          _createTestActivity(id: 'x', dayIndex: 1),
          destinationId: 'dest-1',
          destinationName: 'Test',
        );
        notifier.addActivity(
          _createTestActivity(id: 'y', dayIndex: 1),
          destinationId: 'dest-1',
          destinationName: 'Test',
        );

        // Reorder day 0 only
        notifier.reorderActivitiesForDay(0, 0, 1);

        final state = container.read(pendingTripProvider);

        // Day 0 should be reordered
        final day0 = state.activities.where((a) => a.dayIndex == 0).toList();
        expect(day0[0].id, equals('b'));
        expect(day0[1].id, equals('a'));

        // Day 1 should remain unchanged
        final day1 = state.activities.where((a) => a.dayIndex == 1).toList();
        expect(day1[0].id, equals('x'));
        expect(day1[1].id, equals('y'));
      });

      test('should handle invalid indices gracefully', () {
        final notifier = container.read(pendingTripProvider.notifier);

        notifier.addActivity(
          _createTestActivity(id: 'a', dayIndex: 0),
          destinationId: 'dest-1',
          destinationName: 'Test',
        );
        notifier.addActivity(
          _createTestActivity(id: 'b', dayIndex: 0),
          destinationId: 'dest-1',
          destinationName: 'Test',
        );

        final beforeState = container.read(pendingTripProvider);

        // Invalid oldIndex
        notifier.reorderActivitiesForDay(0, -1, 0);
        expect(
          container.read(pendingTripProvider).activities.length,
          equals(beforeState.activities.length),
        );

        // Invalid newIndex
        notifier.reorderActivitiesForDay(0, 0, 999);
        expect(
          container.read(pendingTripProvider).activities.length,
          equals(beforeState.activities.length),
        );
      });
    });
  });
}

/// Helper to create test PendingActivity
PendingActivity _createTestActivity({
  String id = 'test-id',
  int dayIndex = 0,
  TimeSlot timeSlot = TimeSlot.morning,
  String locationId = 'loc-123',
  String name = 'Test Location',
  String destinationId = 'test-destination',
  String destinationName = 'Test Destination',
}) {
  return PendingActivity(
    id: id,
    dayIndex: dayIndex,
    timeSlot: timeSlot,
    locationId: locationId,
    locationName: name,
    emoji: '📍',
    imageUrl: null,
    destinationId: destinationId,
    destinationName: destinationName,
    addedAt: DateTime(2026, 1, 27),
  );
}
