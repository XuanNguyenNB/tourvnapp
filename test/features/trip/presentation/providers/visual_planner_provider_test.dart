import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/activity.dart';
import 'package:tour_vn/features/trip/domain/entities/trip.dart';
import 'package:tour_vn/features/trip/domain/entities/trip_day.dart';
import 'package:tour_vn/features/trip/presentation/providers/pending_trip_provider.dart';
import 'package:tour_vn/features/trip/presentation/providers/visual_planner_provider.dart';

void main() {
  group('VisualPlannerState', () {
    group('Initial State', () {
      test('has correct default values', () {
        const state = VisualPlannerState();

        expect(state.currentTrip, isNull);
        expect(state.selectedDayNumber, 1);
        expect(state.isLoading, isFalse);
        expect(state.isSaving, isFalse);
        expect(state.error, isNull);
        expect(state.isPending, isFalse);
      });
    });

    group('copyWith', () {
      test('copies with new selectedDayNumber', () {
        const state = VisualPlannerState(selectedDayNumber: 1);
        final updated = state.copyWith(selectedDayNumber: 3);

        expect(updated.selectedDayNumber, 3);
        expect(updated.isLoading, state.isLoading);
      });

      test('copies with new isLoading', () {
        const state = VisualPlannerState(isLoading: false);
        final updated = state.copyWith(isLoading: true);

        expect(updated.isLoading, isTrue);
        expect(updated.selectedDayNumber, state.selectedDayNumber);
      });

      test('copies with new isSaving', () {
        const state = VisualPlannerState(isSaving: false);
        final updated = state.copyWith(isSaving: true);

        expect(updated.isSaving, isTrue);
      });

      test('copies with new error', () {
        const state = VisualPlannerState();
        final updated = state.copyWith(error: 'Test error');

        expect(updated.error, 'Test error');
      });

      test('clearError clears the error', () {
        const state = VisualPlannerState(error: 'Some error');
        final updated = state.copyWith(clearError: true);

        expect(updated.error, isNull);
      });

      test('clearTrip clears the trip', () {
        const state = VisualPlannerState();
        final updated = state.copyWith(clearTrip: true);

        expect(updated.currentTrip, isNull);
      });

      test('copies with new isPending', () {
        const state = VisualPlannerState(isPending: false);
        final updated = state.copyWith(isPending: true);

        expect(updated.isPending, isTrue);
      });
    });

    group('activitiesForCurrentDay', () {
      test('returns empty list when currentTrip is null', () {
        const state = VisualPlannerState(currentTrip: null);

        expect(state.activitiesForCurrentDay, isEmpty);
      });

      test('returns empty list for day with no activities', () {
        final trip = Trip(
          id: 'test-trip',
          userId: 'user-1',
          name: 'Test Trip',
          destinationId: 'dest-1',
          destinationName: 'Hà Nội',
          days: [
            TripDay(dayNumber: 1, activities: const []),
            TripDay(dayNumber: 2, activities: const []),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final state = VisualPlannerState(
          currentTrip: trip,
          selectedDayNumber: 1,
        );

        expect(state.activitiesForCurrentDay, isEmpty);
      });

      test('returns activities for selected day sorted by time slot', () {
        final morningActivity = Activity(
          id: 'act-1',
          locationId: 'loc-1',
          locationName: 'Cafe Morning',
          emoji: '☕',
          timeSlot: 'morning',
          sortOrder: 2, // Out of order to test sorting
        );
        final eveningActivity = Activity(
          id: 'act-2',
          locationId: 'loc-2',
          locationName: 'Restaurant Evening',
          emoji: '🍜',
          timeSlot: 'evening',
          sortOrder: 0,
        );
        final noonActivity = Activity(
          id: 'act-3',
          locationId: 'loc-3',
          locationName: 'Lunch Place',
          emoji: '🍱',
          timeSlot: 'noon',
          sortOrder: 1,
        );

        final trip = Trip(
          id: 'test-trip',
          userId: 'user-1',
          name: 'Test Trip',
          destinationId: 'dest-1',
          destinationName: 'Hà Nội',
          days: [
            TripDay(
              dayNumber: 1,
              activities: [eveningActivity, morningActivity, noonActivity],
            ),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final state = VisualPlannerState(
          currentTrip: trip,
          selectedDayNumber: 1,
        );

        final activities = state.activitiesForCurrentDay;

        expect(activities.length, 3);
        // Should be sorted: morning (0) -> noon (1) -> evening (3)
        expect(activities[0].timeSlot, 'morning');
        expect(activities[1].timeSlot, 'noon');
        expect(activities[2].timeSlot, 'evening');
      });

      test('returns only activities for selected day', () {
        final day1Activity = Activity(
          id: 'act-1',
          locationId: 'loc-1',
          locationName: 'Day 1 Activity',
          emoji: '🏛️',
          timeSlot: 'morning',
          sortOrder: 0,
        );
        final day2Activity = Activity(
          id: 'act-2',
          locationId: 'loc-2',
          locationName: 'Day 2 Activity',
          emoji: '🏖️',
          timeSlot: 'afternoon',
          sortOrder: 0,
        );

        final trip = Trip(
          id: 'test-trip',
          userId: 'user-1',
          name: 'Test Trip',
          destinationId: 'dest-1',
          destinationName: 'Đà Nẵng',
          days: [
            TripDay(dayNumber: 1, activities: [day1Activity]),
            TripDay(dayNumber: 2, activities: [day2Activity]),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Select Day 1
        final state1 = VisualPlannerState(
          currentTrip: trip,
          selectedDayNumber: 1,
        );
        expect(state1.activitiesForCurrentDay.length, 1);
        expect(
          state1.activitiesForCurrentDay[0].locationName,
          'Day 1 Activity',
        );

        // Select Day 2
        final state2 = VisualPlannerState(
          currentTrip: trip,
          selectedDayNumber: 2,
        );
        expect(state2.activitiesForCurrentDay.length, 1);
        expect(
          state2.activitiesForCurrentDay[0].locationName,
          'Day 2 Activity',
        );
      });

      test('returns empty list for non-existent day', () {
        final trip = Trip(
          id: 'test-trip',
          userId: 'user-1',
          name: 'Test Trip',
          destinationId: 'dest-1',
          destinationName: 'Huế',
          days: [TripDay(dayNumber: 1, activities: const [])],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final state = VisualPlannerState(
          currentTrip: trip,
          selectedDayNumber: 5, // Day doesn't exist
        );

        expect(state.activitiesForCurrentDay, isEmpty);
      });
    });

    group('toString', () {
      test('returns readable string', () {
        const state = VisualPlannerState(selectedDayNumber: 2);

        expect(state.toString(), contains('day: 2'));
      });
    });
  });

  group('VisualPlannerNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is loading', () {
      final state = container.read(visualPlannerProvider);

      // Initial state is loading, screen will call loadTrip() or loadFromPending()
      expect(state.isLoading, isTrue);
    });

    test('selectDay updates selectedDayNumber', () {
      // First read to initialize
      container.read(visualPlannerProvider);

      // Wait for initial load
      container.read(visualPlannerProvider.notifier).selectDay(3);

      final state = container.read(visualPlannerProvider);
      expect(state.selectedDayNumber, 3);
    });

    test('selectDay ignores same day', () {
      container.read(visualPlannerProvider);
      container.read(visualPlannerProvider.notifier).selectDay(1);

      // Should still be day 1 (default)
      final state = container.read(visualPlannerProvider);
      expect(state.selectedDayNumber, 1);
    });

    test('provider works with empty pending state', () {
      // Ensure pending state is empty
      final pendingState = container.read(pendingTripProvider);
      expect(pendingState.isEmpty, isTrue);

      final state = container.read(visualPlannerProvider);

      expect(state.isLoading, isTrue);
      // Initial state is loading, not auto-loading from pending
      // Screen will call loadFromPending() explicitly
    });
  });

  group('SaveTripResult', () {
    test('has all expected values', () {
      expect(SaveTripResult.values, contains(SaveTripResult.success));
      expect(SaveTripResult.values, contains(SaveTripResult.needsSignIn));
      expect(SaveTripResult.values, contains(SaveTripResult.error));
      expect(SaveTripResult.values, contains(SaveTripResult.noTrip));
    });

    test('enum has correct count', () {
      expect(SaveTripResult.values.length, 4);
    });
  });

  group('VisualPlannerNotifier.saveTrip()', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('returns noTrip when currentTrip is null', () async {
      // Initialize provider (will have empty pending state → null trip)
      container.read(visualPlannerProvider);

      final notifier = container.read(visualPlannerProvider.notifier);
      final result = await notifier.saveTrip();

      expect(result, SaveTripResult.noTrip);
    });

    // Note: Testing needsSignIn requires mocking FirebaseAuth
    // which is complex. Integration tests are better for this.
    // However, we document the expected behavior here.

    test('state preserves isSaving=false after noTrip result', () async {
      container.read(visualPlannerProvider);

      final notifier = container.read(visualPlannerProvider.notifier);
      await notifier.saveTrip();

      final state = container.read(visualPlannerProvider);
      expect(state.isSaving, isFalse);
    });
  });

  group('VisualPlannerNotifier.updateTrip()', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('returns noTrip when state is pending', () async {
      // Provider starts in pending state
      container.read(visualPlannerProvider);

      final notifier = container.read(visualPlannerProvider.notifier);
      final result = await notifier.updateTrip();

      // updateTrip returns noTrip for pending trips
      expect(result, SaveTripResult.noTrip);
    });

    test('returns noTrip when currentTrip is null', () async {
      container.read(visualPlannerProvider);

      final notifier = container.read(visualPlannerProvider.notifier);
      final result = await notifier.updateTrip();

      expect(result, SaveTripResult.noTrip);
    });
  });
}
