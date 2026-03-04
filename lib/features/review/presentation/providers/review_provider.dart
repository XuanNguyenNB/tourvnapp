import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/review_repository.dart';
import '../../domain/entities/review.dart';
import '../../../destination/domain/entities/location.dart';
import '../../../destination/presentation/providers/location_provider.dart';

/// Provider for fetching a review by ID
///
/// Auto-disposes when not used (screen-specific state)
/// See Story 3.8 AC #1-4
final reviewByIdProvider = FutureProvider.autoDispose.family<Review, String>((
  ref,
  reviewId,
) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getReviewById(reviewId);
});

/// Provider for fetching related locations for a review
///
/// Takes a list of location IDs and returns the matching locations.
/// Queries across all destinations to find matching locations.
/// Auto-disposes when not used.
/// See Story 3.10 AC #1-6
final relatedLocationsProvider = FutureProvider.autoDispose
    .family<List<Location>, List<String>>((ref, locationIds) async {
      if (locationIds.isEmpty) {
        return [];
      }

      final repository = ref.watch(destinationRepositoryProvider);

      // Fetch each location by ID (works across all destinations)
      final locations = <Location>[];
      for (final id in locationIds) {
        try {
          final location = await repository.getLocationById(id);
          locations.add(location);
        } catch (_) {
          // Skip locations that are not found
          // This handles cases where IDs don't match any location
        }
      }

      return locations;
    });

/// Provider for all reviews (for listing/browsing)
final allReviewsProvider = FutureProvider.autoDispose<List<Review>>((
  ref,
) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getAllReviews();
});
