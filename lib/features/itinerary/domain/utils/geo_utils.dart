import 'dart:math';

/// Utility functions for geographic distance calculations.
///
/// Used by the smart itinerary algorithm to cluster locations
/// and optimize route ordering within each day.
class GeoUtils {
  GeoUtils._();

  /// Earth's radius in kilometers.
  static const double earthRadiusKm = 6371.0;

  /// Calculate the Haversine distance between two geo-coordinates.
  ///
  /// Returns distance in **kilometers**.
  /// Formula: a = sin²(Δlat/2) + cos(lat1)·cos(lat2)·sin²(Δlon/2)
  ///          c = 2·atan2(√a, √(1−a))
  ///          d = R·c
  static double haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Estimate travel time in minutes between two points.
  ///
  /// Uses average urban speed of [speedKmh] (default 30 km/h for city travel).
  /// Adds [overheadMinutes] as fixed overhead for parking, walking, etc.
  static int estimateTravelMinutes(
    double lat1,
    double lon1,
    double lat2,
    double lon2, {
    double speedKmh = 30.0,
    int overheadMinutes = 10,
  }) {
    final distKm = haversineKm(lat1, lon1, lat2, lon2);
    final travelMin = (distKm / speedKmh * 60).ceil();
    return travelMin + overheadMinutes;
  }

  /// Compute a full N×N distance matrix for a list of coordinate pairs.
  ///
  /// Returns a 2D list where `matrix[i][j]` is the distance in km
  /// between point `i` and point `j`.
  static List<List<double>> distanceMatrix(
    List<({double lat, double lon})> points,
  ) {
    final n = points.length;
    final matrix = List.generate(n, (_) => List.filled(n, 0.0));
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        final d = haversineKm(
          points[i].lat,
          points[i].lon,
          points[j].lat,
          points[j].lon,
        );
        matrix[i][j] = d;
        matrix[j][i] = d;
      }
    }
    return matrix;
  }

  /// Convert degrees to radians.
  static double _toRadians(double degrees) => degrees * pi / 180;
}
