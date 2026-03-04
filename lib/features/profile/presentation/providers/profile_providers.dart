import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/features/auth/presentation/providers/auth_provider.dart';
import 'package:tour_vn/features/profile/domain/entities/user_stats.dart';
import 'package:tour_vn/features/trip/presentation/providers/trips_provider.dart';

/// TripMini - Simplified trip entity for profile display
///
/// Contains minimal data needed for the recent trips carousel.
class TripMini {
  final String id;
  final String name;
  final String? imageUrl;
  final String? destination;
  final DateTime? startDate;
  final int dayCount;

  const TripMini({
    required this.id,
    required this.name,
    this.imageUrl,
    this.destination,
    this.startDate,
    this.dayCount = 1,
  });
}

/// Provider for user statistics (trips, saves, reviews counts)
///
/// Returns UserStats for authenticated users, empty stats for anonymous.
final userStatsProvider = FutureProvider.autoDispose<UserStats>((ref) async {
  final user = ref.watch(currentUserProvider);

  // Return empty stats for anonymous or null user
  if (user == null || user.isAnonymous) {
    return UserStats.empty();
  }

  // Get trip count from real data
  final tripsAsync = ref.watch(userTripsProvider);
  final tripCount = tripsAsync.maybeWhen(
    data: (trips) => trips.length,
    orElse: () => 0,
  );

  // Still mocking saves and reviews for now
  return UserStats(tripCount: tripCount, savesCount: 0, reviewsCount: 0);
});

/// Provider for recent trips (last 5 trips for carousel)
///
/// Returns list of TripMini for authenticated users.
/// Returns empty list for anonymous users.
final recentTripsProvider = FutureProvider.autoDispose<List<TripMini>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);

  // Return empty for anonymous or null user
  if (user == null || user.isAnonymous) {
    return [];
  }

  // Get real trips from Firestore via userTripsProvider
  final tripsAsync = ref.watch(userTripsProvider);

  return tripsAsync.maybeWhen(
    data: (trips) {
      if (trips.isEmpty) return <TripMini>[];

      // Take top 5 trips (already sorted by updatedAt desc)
      return trips.take(5).map((trip) {
        // Get image from first activity if available
        String? imageUrl;
        if (trip.days.isNotEmpty && trip.days.first.activities.isNotEmpty) {
          imageUrl = trip.days.first.activities.first.imageUrl;
        }

        return TripMini(
          id: trip.id,
          name: trip.name,
          imageUrl: imageUrl,
          destination: trip.destinationName,
          startDate: trip.createdAt,
          dayCount: trip.totalDays,
        );
      }).toList();
    },
    orElse: () => <TripMini>[],
  );
});
