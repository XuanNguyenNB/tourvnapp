import 'dart:math';

/// Utility class for calculating distance between two GPS coordinates.
///
/// Uses Haversine formula for accurate distance calculation on Earth's surface.
///
/// Story 8-0.5: GPS-Based Distance Calculation
abstract class DistanceCalculator {
  /// Earth's radius in meters
  static const double _earthRadiusM = 6371000;

  /// Calculate distance between two GPS coordinates using Haversine formula.
  ///
  /// Returns distance in meters.
  ///
  /// Parameters:
  /// - [lat1], [lng1]: First coordinate (user's position)
  /// - [lat2], [lng2]: Second coordinate (location's position)
  static double calculate({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    // Convert degrees to radians
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    // Haversine formula
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusM * c;
  }

  /// Convert degrees to radians.
  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Format distance for display.
  ///
  /// Returns:
  /// - "500m" for distances < 1km
  /// - "2.5km" for distances >= 1km
  static String format(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      final km = meters / 1000;
      // Show 1 decimal for distances < 10km, whole numbers for larger
      if (km < 10) {
        return '${km.toStringAsFixed(1)}km';
      } else {
        return '${km.round()}km';
      }
    }
  }

  /// Calculate distance and return formatted string.
  ///
  /// Returns null if any coordinate is null.
  static String? calculateAndFormat({
    required double? userLat,
    required double? userLng,
    required double? locationLat,
    required double? locationLng,
  }) {
    if (userLat == null ||
        userLng == null ||
        locationLat == null ||
        locationLng == null) {
      return null;
    }

    final distance = calculate(
      lat1: userLat,
      lng1: userLng,
      lat2: locationLat,
      lng2: locationLng,
    );

    return format(distance);
  }

  /// Check if distance is within a given radius.
  ///
  /// Returns true if distance is less than or equal to [radiusMeters].
  /// Returns false if coordinates are null.
  static bool isWithinRadius({
    required double? userLat,
    required double? userLng,
    required double? locationLat,
    required double? locationLng,
    required double radiusMeters,
  }) {
    if (userLat == null ||
        userLng == null ||
        locationLat == null ||
        locationLng == null) {
      return false;
    }

    final distance = calculate(
      lat1: userLat,
      lng1: userLng,
      lat2: locationLat,
      lng2: locationLng,
    );

    return distance <= radiusMeters;
  }
}
