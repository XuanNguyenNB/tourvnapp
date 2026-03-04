import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/services/trip_save_service.dart';

void main() {
  group('TripSaveService', () {
    group('pendingTripProvider', () {
      test('initial state is null', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(pendingTripProvider), isNull);
      });

      test('can set pending trip data', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final tripData = {
          'name': 'Test Trip',
          'destinations': ['Ha Noi', 'Da Lat'],
        };

        container.read(pendingTripProvider.notifier).setTrip(tripData);

        expect(container.read(pendingTripProvider), equals(tripData));
      });

      test('can clear pending trip data', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Set some data
        container.read(pendingTripProvider.notifier).setTrip({'name': 'Test'});
        expect(container.read(pendingTripProvider), isNotNull);

        // Clear it
        container.read(pendingTripProvider.notifier).clear();
        expect(container.read(pendingTripProvider), isNull);
      });
    });

    group('TripSaveResult', () {
      test('has correct enum values', () {
        expect(TripSaveResult.values, hasLength(3));
        expect(TripSaveResult.values, contains(TripSaveResult.success));
        expect(TripSaveResult.values, contains(TripSaveResult.cancelled));
        expect(TripSaveResult.values, contains(TripSaveResult.error));
      });
    });

    group('tripSaveServiceProvider', () {
      test('provides TripSaveService instance', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service = container.read(tripSaveServiceProvider);
        expect(service, isA<TripSaveService>());
      });
    });

    group('PendingTripNotifier', () {
      test('setTrip updates state correctly', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(pendingTripProvider.notifier);
        expect(container.read(pendingTripProvider), isNull);

        notifier.setTrip({'id': '123', 'name': 'Dalat Trip'});
        expect(container.read(pendingTripProvider)?['id'], '123');
        expect(container.read(pendingTripProvider)?['name'], 'Dalat Trip');
      });

      test('clear resets state to null', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(pendingTripProvider.notifier);
        notifier.setTrip({'id': '456'});
        expect(container.read(pendingTripProvider), isNotNull);

        notifier.clear();
        expect(container.read(pendingTripProvider), isNull);
      });
    });
  });
}
