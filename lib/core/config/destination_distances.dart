import 'package:tour_vn/features/trip/domain/entities/destination_distance.dart';

/// Configuration class for destination distances.
///
/// Contains static data for distances and travel times between
/// major tourist destinations in Vietnam.
abstract class DestinationDistances {
  /// Distance thresholds for warning levels (in km).
  static const double adjacentThreshold = 50;
  static const double differentThreshold = 200;

  /// Bidirectional lookup map for destination distances.
  ///
  /// Keys are destination IDs, values are maps of target destination IDs
  /// to their distance/travel time.
  ///
  /// Distance is stored bidirectionally, so A->B == B->A.
  static const Map<String, Map<String, DestinationDistance>> _distances = {
    // Central Vietnam region
    'da-nang': {
      'hoi-an': DestinationDistance(distanceKm: 30, travelTimeMin: 45),
      'hue': DestinationDistance(distanceKm: 100, travelTimeMin: 180),
      'ba-na-hills': DestinationDistance(distanceKm: 25, travelTimeMin: 40),
      'my-son': DestinationDistance(distanceKm: 50, travelTimeMin: 75),
      'quy-nhon': DestinationDistance(distanceKm: 300, travelTimeMin: 360),
    },
    'hoi-an': {
      'da-nang': DestinationDistance(distanceKm: 30, travelTimeMin: 45),
      'hue': DestinationDistance(distanceKm: 130, travelTimeMin: 210),
      'my-son': DestinationDistance(distanceKm: 40, travelTimeMin: 60),
    },
    'hue': {
      'da-nang': DestinationDistance(distanceKm: 100, travelTimeMin: 180),
      'hoi-an': DestinationDistance(distanceKm: 130, travelTimeMin: 210),
      'phong-nha': DestinationDistance(distanceKm: 210, travelTimeMin: 270),
    },

    // Northern Vietnam region
    'ha-noi': {
      'ninh-binh': DestinationDistance(distanceKm: 95, travelTimeMin: 120),
      'ha-long': DestinationDistance(distanceKm: 170, travelTimeMin: 180),
      'sapa': DestinationDistance(distanceKm: 320, travelTimeMin: 360),
      'mai-chau': DestinationDistance(distanceKm: 135, travelTimeMin: 180),
      'tam-dao': DestinationDistance(distanceKm: 85, travelTimeMin: 90),
      'ha-giang': DestinationDistance(distanceKm: 310, travelTimeMin: 420),
      'cat-ba': DestinationDistance(distanceKm: 150, travelTimeMin: 240),
    },
    'ha-long': {
      'ha-noi': DestinationDistance(distanceKm: 170, travelTimeMin: 180),
      'cat-ba': DestinationDistance(distanceKm: 30, travelTimeMin: 60),
      'ninh-binh': DestinationDistance(distanceKm: 230, travelTimeMin: 240),
    },
    'sapa': {
      'ha-noi': DestinationDistance(distanceKm: 320, travelTimeMin: 360),
      'ha-giang': DestinationDistance(distanceKm: 240, travelTimeMin: 360),
    },
    'ninh-binh': {
      'ha-noi': DestinationDistance(distanceKm: 95, travelTimeMin: 120),
      'ha-long': DestinationDistance(distanceKm: 230, travelTimeMin: 240),
      'mai-chau': DestinationDistance(distanceKm: 85, travelTimeMin: 120),
    },

    // Southern Vietnam region
    'ho-chi-minh': {
      'vung-tau': DestinationDistance(distanceKm: 125, travelTimeMin: 120),
      'da-lat': DestinationDistance(distanceKm: 310, travelTimeMin: 360),
      'mui-ne': DestinationDistance(distanceKm: 220, travelTimeMin: 270),
      'can-tho': DestinationDistance(distanceKm: 170, travelTimeMin: 210),
      'phu-quoc': DestinationDistance(
        distanceKm: 400,
        travelTimeMin: 90,
      ), // By flight
      'con-dao': DestinationDistance(
        distanceKm: 230,
        travelTimeMin: 45,
      ), // By flight
      'cu-chi': DestinationDistance(distanceKm: 40, travelTimeMin: 60),
    },
    'da-lat': {
      'ho-chi-minh': DestinationDistance(distanceKm: 310, travelTimeMin: 360),
      'nha-trang': DestinationDistance(distanceKm: 140, travelTimeMin: 180),
      'mui-ne': DestinationDistance(distanceKm: 150, travelTimeMin: 210),
    },
    'nha-trang': {
      'da-lat': DestinationDistance(distanceKm: 140, travelTimeMin: 180),
      'quy-nhon': DestinationDistance(distanceKm: 220, travelTimeMin: 270),
      'mui-ne': DestinationDistance(distanceKm: 230, travelTimeMin: 300),
    },
    'phu-quoc': {
      'ho-chi-minh': DestinationDistance(distanceKm: 400, travelTimeMin: 90),
      'can-tho': DestinationDistance(distanceKm: 160, travelTimeMin: 180),
      'ha-noi': DestinationDistance(
        distanceKm: 1700,
        travelTimeMin: 150,
      ), // Flight
    },
    'can-tho': {
      'ho-chi-minh': DestinationDistance(distanceKm: 170, travelTimeMin: 210),
      'phu-quoc': DestinationDistance(distanceKm: 160, travelTimeMin: 180),
    },

    // Central Highlands region
    'buon-ma-thuot': {
      'da-lat': DestinationDistance(distanceKm: 200, travelTimeMin: 270),
      'pleiku': DestinationDistance(distanceKm: 200, travelTimeMin: 240),
      'nha-trang': DestinationDistance(distanceKm: 200, travelTimeMin: 270),
    },
  };

  /// Get distance between two destinations.
  ///
  /// Returns null if distance is unknown.
  /// Performs bidirectional lookup (from->to or to->from).
  static DestinationDistance? getDistance(String from, String to) {
    // Same destination
    if (from == to) return null;

    // Try direct lookup
    final fromDistances = _distances[from];
    if (fromDistances != null && fromDistances.containsKey(to)) {
      return fromDistances[to];
    }

    // Try reverse lookup
    final toDistances = _distances[to];
    if (toDistances != null && toDistances.containsKey(from)) {
      return toDistances[from];
    }

    // Unknown distance between destinations
    return null;
  }

  /// Check if two destinations are adjacent (within threshold).
  static bool areAdjacent(String from, String to) {
    final distance = getDistance(from, to);
    if (distance == null) return false;
    return distance.distanceKm < adjacentThreshold;
  }

  /// Check if distance between destinations is in different range.
  static bool areDifferent(String from, String to) {
    final distance = getDistance(from, to);
    if (distance == null) return false;
    return distance.distanceKm >= adjacentThreshold &&
        distance.distanceKm < differentThreshold;
  }

  /// Check if destinations are distant (beyond threshold).
  static bool areDistant(String from, String to) {
    final distance = getDistance(from, to);
    if (distance == null) return false;
    return distance.distanceKm >= differentThreshold;
  }

  /// Get all known destinations — bao gồm cả outer keys và nested keys.
  ///
  /// Ví dụ: nếu 'hoi-an' chỉ xuất hiện trong nested map của 'da-nang',
  /// getter cũ sẽ miss nó. Getter mới collect toàn bộ.
  static Set<String> get knownDestinations {
    final result = <String>{};
    for (final entry in _distances.entries) {
      result.add(entry.key);
      result.addAll(entry.value.keys);
    }
    return result;
  }
}
