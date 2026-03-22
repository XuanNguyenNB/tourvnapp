import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tour_vn/features/destination/presentation/providers/destination_provider.dart';
import 'package:tour_vn/features/onboarding/domain/entities/nearby_location_item.dart';
import 'package:tour_vn/features/home/presentation/providers/user_location_provider.dart';

/// Provider trả về danh sách locations gần vị trí GPS hiện tại.
///
/// - Lấy tất cả locations từ Firestore
/// - Lọc các locations có tọa độ GPS
/// - Tính khoảng cách đến vị trí người dùng
/// - Sắp xếp theo distance ascending
/// - Giới hạn top 15 kết quả gần nhất
///
/// Trả về list rỗng nếu không có GPS position.
final nearbyLocationsProvider =
    FutureProvider<List<NearbyLocationItem>>((ref) async {
  // Get user position
  final locationState = ref.watch(userLocationProvider);
  final userPosition = locationState.position;

  if (userPosition == null) return [];

  // Get all locations from Firestore
  final destRepo = ref.read(destinationRepositoryProvider);
  final allLocations = await destRepo.getAllLocations();

  // Filter locations with GPS coordinates and calculate distance
  final nearbyItems = <NearbyLocationItem>[];

  for (final location in allLocations) {
    if (location.latitude == null || location.longitude == null) continue;

    final distanceMeters = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      location.latitude!,
      location.longitude!,
    );

    nearbyItems.add(NearbyLocationItem(
      location: location,
      distanceKm: distanceMeters / 1000.0,
    ));
  }

  // Sort by distance (nearest first)
  nearbyItems.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

  // Return top 15
  return nearbyItems.take(15).toList();
});
