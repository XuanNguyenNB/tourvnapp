import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/features/trip/domain/entities/trip.dart';
import 'package:tour_vn/features/trip/presentation/providers/active_trip_provider.dart';

void main() {
  group('ActiveTripProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    final testTrip = Trip(
      id: 'trip-1',
      userId: 'user-1',
      name: 'Test Trip',
      destinationId: 'dest-1',
      destinationName: 'Destination 1',
      days: const [],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('initial state has no trip', () {
      final activeTrip = container.read(activeTripProvider);
      expect(activeTrip, isNull);
    });

    test('setActiveTrip updates the state', () {
      container.read(activeTripProvider.notifier).setActiveTrip(testTrip);

      final activeTrip = container.read(activeTripProvider);
      expect(activeTrip, equals(testTrip));
    });

    test('clearActiveTrip sets the trip to null', () {
      container.read(activeTripProvider.notifier).setActiveTrip(testTrip);
      container.read(activeTripProvider.notifier).clearActiveTrip();

      final activeTrip = container.read(activeTripProvider);
      expect(activeTrip, isNull);
    });
  });
}
