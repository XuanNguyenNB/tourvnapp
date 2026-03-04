import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/review_preview.dart';

/// Utility class for distance calculations and formatting.
///
/// Story 8-0.5: GPS-Based Distance Calculation
class DistanceCalculator {
  /// Calculate distance between two GPS coordinates in kilometers.
  static double calculateDistanceKm({
    required double userLat,
    required double userLng,
    required double targetLat,
    required double targetLng,
  }) {
    final distanceMeters = Geolocator.distanceBetween(
      userLat,
      userLng,
      targetLat,
      targetLng,
    );
    return distanceMeters / 1000.0;
  }

  /// Attach distance to a list of ReviewPreviews based on user position.
  ///
  /// Returns new list with `distanceKm` populated for reviews that have GPS.
  /// Reviews without GPS will have distanceKm = null.
  static List<ReviewPreview> attachDistances({
    required List<ReviewPreview> reviews,
    required double userLat,
    required double userLng,
  }) {
    return reviews.map((review) {
      if (!review.hasCoordinates) return review;

      final distKm = calculateDistanceKm(
        userLat: userLat,
        userLng: userLng,
        targetLat: review.latitude!,
        targetLng: review.longitude!,
      );

      return review.copyWith(distanceKm: distKm);
    }).toList();
  }

  /// Sort reviews by distance (nearest first).
  /// Reviews without GPS go to the end.
  static List<ReviewPreview> sortByDistance(List<ReviewPreview> reviews) {
    final withDistance = reviews.where((r) => r.distanceKm != null).toList();
    final withoutDistance = reviews.where((r) => r.distanceKm == null).toList();

    withDistance.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));

    return [...withDistance, ...withoutDistance];
  }

  /// Format distance for display.
  ///
  /// - < 1 km → "500 m"
  /// - 1-99 km → "3.2 km"
  /// - ≥ 100 km → "150 km"
  static String formatDistance(double km) {
    if (km < 1) {
      final meters = (km * 1000).round();
      return '$meters m';
    } else if (km < 100) {
      return '${km.toStringAsFixed(1)} km';
    } else {
      return '${km.round()} km';
    }
  }
}

/// Provider that attaches distance info to reviews based on user position.
///
/// Returns the original reviews with `distanceKm` populated when user
/// position is available.
final reviewsWithDistanceProvider =
    Provider.family<
      List<ReviewPreview>,
      ({List<ReviewPreview> reviews, Position? userPosition})
    >((ref, params) {
      if (params.userPosition == null) return params.reviews;

      return DistanceCalculator.attachDistances(
        reviews: params.reviews,
        userLat: params.userPosition!.latitude,
        userLng: params.userPosition!.longitude,
      );
    });
