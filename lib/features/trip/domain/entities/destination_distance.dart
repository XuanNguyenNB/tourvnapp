import 'package:flutter/foundation.dart';

/// Represents the distance and travel time between two destinations.
@immutable
class DestinationDistance {
  /// Distance in kilometers.
  final double distanceKm;

  /// Estimated travel time in minutes.
  final int travelTimeMin;

  const DestinationDistance({
    required this.distanceKm,
    required this.travelTimeMin,
  });

  /// Create from JSON map.
  factory DestinationDistance.fromJson(Map<String, dynamic> json) {
    return DestinationDistance(
      distanceKm: (json['distanceKm'] as num).toDouble(),
      travelTimeMin: json['travelTimeMin'] as int,
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() {
    return {'distanceKm': distanceKm, 'travelTimeMin': travelTimeMin};
  }

  /// Format travel time as human-readable string (Vietnamese).
  String get formattedTravelTime {
    if (travelTimeMin < 60) {
      return '$travelTimeMin phút';
    }
    final hours = travelTimeMin ~/ 60;
    final minutes = travelTimeMin % 60;
    if (minutes == 0) {
      return '$hours giờ';
    }
    return '$hours giờ $minutes phút';
  }

  /// Format distance as human-readable string.
  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.round()} km';
  }

  @override
  String toString() {
    return 'DestinationDistance($formattedDistance, $formattedTravelTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DestinationDistance &&
        other.distanceKm == distanceKm &&
        other.travelTimeMin == travelTimeMin;
  }

  @override
  int get hashCode => Object.hash(distanceKm, travelTimeMin);
}
