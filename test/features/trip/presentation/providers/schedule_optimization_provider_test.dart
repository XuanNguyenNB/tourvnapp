import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/destination/data/repositories/destination_repository.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';
import 'package:tour_vn/features/destination/presentation/providers/destination_provider.dart';
import 'package:tour_vn/features/trip/domain/entities/trip.dart';
import 'package:tour_vn/features/trip/presentation/providers/schedule_optimization_provider.dart';

class FakeDestinationRepository extends DestinationRepository {
  FakeDestinationRepository() : super(firestore: FakeFirebaseFirestore());

  @override
  Future<List<Location>> getLocationsByIds(List<String> ids) async => const [];
}

void main() {
  group('ScheduleOptimizationProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          destinationRepositoryProvider.overrideWithValue(
            FakeDestinationRepository(),
          ),
        ],
      );
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

    test('initial state is idle', () {
      final state = container.read(scheduleOptimizationProvider);

      expect(state.isLoading, isFalse);
      expect(state.result, isNull);
      expect(state.error, isNull);
    });

    test('optimizeTrip resolves to a no-change result for empty trip', () async {
      final trip = createEmptyTrip();

      await container.read(scheduleOptimizationProvider.notifier).optimizeTrip(trip);

      final state = container.read(scheduleOptimizationProvider);

      expect(state.isLoading, isFalse);
      expect(state.result, isNotNull);
      expect(state.error, isNull);
      expect(state.result!.hasChanges, isFalse);
    });

    test('reset clears the state to idle', () async {
      final trip = createEmptyTrip();
      final notifier = container.read(scheduleOptimizationProvider.notifier);

      await notifier.optimizeTrip(trip);
      expect(container.read(scheduleOptimizationProvider).result, isNotNull);

      notifier.reset();

      final resetState = container.read(scheduleOptimizationProvider);
      expect(resetState.isLoading, isFalse);
      expect(resetState.result, isNull);
      expect(resetState.error, isNull);
    });
  });
}
