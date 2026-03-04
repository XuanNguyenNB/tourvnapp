import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/services/trip_creation_service.dart';
import 'package:tour_vn/features/trip/presentation/providers/pending_trip_provider.dart';
import 'package:tour_vn/features/trip/domain/entities/pending_activity.dart';
import 'package:tour_vn/features/trip/domain/entities/time_slot.dart';

void main() {
  group('TripCreationService', () {
    const service = TripCreationService();

    test('should return null for empty PendingTripState', () {
      const emptyState = PendingTripState();

      final result = service.createTripFromPendingState(
        userId: 'user-1',
        pendingState: emptyState,
        destinationId: 'dest-1',
        destinationName: 'Test Destination',
      );

      expect(result, isNull);
    });

    test('should create trip from PendingTripState with activities', () {
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
      expect(trip.name, 'Đà Lạt Trip');
      expect(trip.days.isNotEmpty, true);
    });

    test('should get destination from first pending activity', () {
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
      expect(destination!.id, 'loc-1');
      expect(destination.name, 'First Location');
    });

    test('should return null destination for empty state', () {
      const emptyState = PendingTripState();

      final destination = service.getDestinationFromPendingState(emptyState);

      expect(destination, isNull);
    });

    test('canCreateTrip returns true when activities exist', () {
      final activity = PendingActivity(
        id: 'act-1',
        dayIndex: 0,
        timeSlot: TimeSlot.morning,
        locationId: 'loc-1',
        locationName: 'Test',
        destinationId: 'test-dest',
        destinationName: 'Test Destination',
        addedAt: DateTime.now(),
      );

      final state = PendingTripState(activities: [activity]);

      expect(service.canCreateTrip(state), true);
    });

    test('canCreateTrip returns false for empty state', () {
      const emptyState = PendingTripState();

      expect(service.canCreateTrip(emptyState), false);
    });
  });
}
