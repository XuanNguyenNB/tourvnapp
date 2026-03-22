import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/pending_activity.dart';
import 'package:tour_vn/features/trip/domain/entities/time_slot.dart';
import 'package:tour_vn/features/trip/domain/services/trip_creation_service.dart';
import 'package:tour_vn/features/trip/presentation/providers/pending_trip_provider.dart';

void main() {
  group('TripCreationService', () {
    const service = TripCreationService();

    test('returns null for empty PendingTripState', () {
      const emptyState = PendingTripState();

      final result = service.createTripFromPendingState(
        userId: 'user-1',
        pendingState: emptyState,
        destinationId: 'dest-1',
        destinationName: 'Test Destination',
      );

      expect(result, isNull);
    });

    test('creates trip from PendingTripState with activities', () {
      final activity = PendingActivity(
        id: 'act-1',
        dayIndex: 0,
        timeSlot: TimeSlot.morning,
        locationId: 'loc-1',
        locationName: 'Test Location',
        destinationId: 'dest-1',
        destinationName: 'Đà Lạt',
        addedAt: DateTime.now(),
      );

      final state = PendingTripState(activities: [activity]);

      final trip = service.createTripFromPendingState(
        userId: 'user-1',
        pendingState: state,
        destinationId: 'dest-1',
        destinationName: 'Đà Lạt',
      );

      expect(trip, isNotNull);
      expect(trip!.userId, 'user-1');
      expect(trip.destinationId, 'dest-1');
      expect(trip.destinationName, 'Đà Lạt');
      expect(trip.name, 'Khám phá Đà Lạt');
      expect(trip.days, isNotEmpty);
    });

    test('gets destination info from first pending activity', () {
      final activity = PendingActivity(
        id: 'act-1',
        dayIndex: 0,
        timeSlot: TimeSlot.morning,
        locationId: 'loc-1',
        locationName: 'First Location',
        destinationId: 'da-lat',
        destinationName: 'Đà Lạt',
        addedAt: DateTime.now(),
      );

      final state = PendingTripState(activities: [activity]);

      final destination = service.getDestinationFromPendingState(state);

      expect(destination, isNotNull);
      expect(destination!.id, 'da-lat');
      expect(destination.name, 'Đà Lạt');
    });

    test('canCreateTrip returns true when activities exist', () {
      final state = PendingTripState(
        activities: [
          PendingActivity(
            id: 'act-1',
            dayIndex: 0,
            timeSlot: TimeSlot.morning,
            locationId: 'loc-1',
            locationName: 'Test',
            destinationId: 'test-dest',
            destinationName: 'Test Destination',
            addedAt: DateTime.now(),
          ),
        ],
      );

      expect(service.canCreateTrip(state), isTrue);
    });

    test('canCreateTrip returns false for empty state', () {
      expect(service.canCreateTrip(const PendingTripState()), isFalse);
    });
  });
}
