import 'package:tour_vn/features/destination/domain/entities/location.dart';

/// Wrapper chứa Location + khoảng cách tới người dùng.
///
/// Dùng trong onboarding page 4 (nearby locations) để hiển thị
/// các địa điểm gần vị trí GPS hiện tại.
class NearbyLocationItem {
  /// The location entity from Firestore.
  final Location location;

  /// Distance from user's current position in kilometers.
  final double distanceKm;

  const NearbyLocationItem({
    required this.location,
    required this.distanceKm,
  });

  /// Format distance for display.
  String get formattedDistance {
    if (distanceKm < 1) return '${(distanceKm * 1000).round()} m';
    if (distanceKm < 100) return '${distanceKm.toStringAsFixed(1)} km';
    return '${distanceKm.round()} km';
  }
}
