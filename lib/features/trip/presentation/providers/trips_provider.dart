import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/trip_repository.dart';
import '../../domain/entities/trip.dart';
import 'trip_save_provider.dart';

/// Provider for streaming user's trips.
///
/// Returns a stream of trips for the current user.
/// Updates automatically when trips are added/modified/deleted.
final userTripsProvider = StreamProvider<List<Trip>>((ref) {
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(tripRepositoryProvider);
  return repository.getUserTrips(userId);
});

/// Provider for a single trip by ID.
final tripByIdProvider = FutureProvider.family<Trip?, String>((
  ref,
  tripId,
) async {
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return null;
  }

  final repository = ref.read(tripRepositoryProvider);
  return repository.getTrip(userId, tripId);
});

/// Provider for checking if user has any trips.
final hasTripsProvider = Provider<bool>((ref) {
  final tripsAsync = ref.watch(userTripsProvider);
  return tripsAsync.when(
    data: (trips) => trips.isNotEmpty,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for trip count.
final tripCountProvider = Provider<int>((ref) {
  final tripsAsync = ref.watch(userTripsProvider);
  return tripsAsync.when(
    data: (trips) => trips.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for deleting a trip.
///
/// Takes a record with userId and tripId and calls repository.deleteTrip().
/// StreamProvider (userTripsProvider) will auto-update after deletion.
final deleteTripProvider =
    FutureProvider.family<void, ({String userId, String tripId})>((
      ref,
      params,
    ) async {
      final repository = ref.read(tripRepositoryProvider);
      await repository.deleteTrip(params.userId, params.tripId);
    });
