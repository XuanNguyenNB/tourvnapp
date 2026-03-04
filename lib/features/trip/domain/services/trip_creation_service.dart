import 'package:uuid/uuid.dart';

import '../entities/trip.dart';
import '../../presentation/providers/pending_trip_provider.dart';

/// Service for creating trips from pending activities.
///
/// Handles the logic for auto-creating trips when user adds
/// their first location without an existing trip.
class TripCreationService {
  const TripCreationService();

  /// Create a Trip from PendingTripState.
  ///
  /// Uses the first activity's destination as the trip name and ID.
  /// If no activities exist, returns null.
  Trip? createTripFromPendingState({
    required String userId,
    required PendingTripState pendingState,
    required String destinationId,
    required String destinationName,
  }) {
    if (pendingState.isEmpty) {
      return null;
    }

    final tripId = const Uuid().v4();

    return Trip.fromPendingState(
      id: tripId,
      userId: userId,
      pendingState: pendingState,
      destinationId: destinationId,
      destinationName: destinationName,
    );
  }

  /// Get destination info from the first pending activity.
  ///
  /// Returns a record with destinationId and destinationName.
  /// Uses the parent destination of the first activity's location.
  ({String id, String name})? getDestinationFromPendingState(
    PendingTripState pendingState,
  ) {
    if (pendingState.isEmpty) {
      return null;
    }

    final firstActivity = pendingState.activities.first;

    // Use the actual destination fields (parent of the location)
    return (
      id: firstActivity.destinationId,
      name: firstActivity.destinationName,
    );
  }

  /// Check if pending state has enough data to create a trip.
  bool canCreateTrip(PendingTripState pendingState) {
    return pendingState.isNotEmpty;
  }
}

/// Provider for TripCreationService.
///
/// Singleton service, no dependencies on other providers.
const tripCreationService = TripCreationService();
