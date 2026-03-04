import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/trip.dart';
import 'package:tour_vn/features/trip/presentation/providers/schedule_optimization_provider.dart';

void main() {
  group('ScheduleOptimizationProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    Trip createEmptyTrip() {
      return Trip(
        id: '1',
        userId: 'u1',
        name: 'Empty Trip',
        destinationId: 'dest1',
        destinationName: 'Dest 1',
        days: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    test('initial state is idle (not loading, no result)', () {
      final state = container.read(scheduleOptimizationProvider);

      expect(state.isLoading, isFalse);
      expect(state.result, isNull);
      expect(state.error, isNull);
    });

    test('optimizeTrip transitions from loading to result synchronously', () {
      final trip = createEmptyTrip();

      // Since optimizeSchedule is synchronous, it updates to loading then to result immediately.
      // We can only check the final state after the call.

      container.read(scheduleOptimizationProvider.notifier).optimizeTrip(trip);

      final state = container.read(scheduleOptimizationProvider);

      expect(state.isLoading, isFalse);
      expect(state.result, isNotNull);
      expect(state.error, isNull);
      expect(state.result!.hasChanges, isFalse);
    });

    test('reset clears the state to idle', () {
      final trip = createEmptyTrip();

      final notifier = container.read(scheduleOptimizationProvider.notifier);
      notifier.optimizeTrip(trip);

      // Verify it's populated
      expect(container.read(scheduleOptimizationProvider).result, isNotNull);

      notifier.reset();

      // Verify it's reset
      final resetState = container.read(scheduleOptimizationProvider);
      expect(resetState.isLoading, isFalse);
      expect(resetState.result, isNull);
      expect(resetState.error, isNull);
    });
  });
}
