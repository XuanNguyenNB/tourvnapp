import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/location_service.dart';

/// Provider for LocationService singleton.
///
/// Story 8-0.5: GPS-Based Distance Calculation
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider for user's current GPS position.
///
/// Returns null if:
/// - Permission is denied
/// - Location service is disabled
/// - Position unavailable
///
/// Story 8-0.5: GPS-Based Distance Calculation
final userPositionProvider = FutureProvider<Position?>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  return await locationService.getCurrentPosition();
});

/// Provider for location permission status.
///
/// Story 8-0.5: GPS-Based Distance Calculation
final locationPermissionStatusProvider =
    FutureProvider<LocationPermissionStatus>((ref) async {
      final locationService = ref.read(locationServiceProvider);
      return await locationService.getPermissionStatus();
    });

/// Notifier for managing user position state.
///
/// Handles:
/// - Initial position loading
/// - Permission request flow
/// - Position refresh
///
/// Story 8-0.5: GPS-Based Distance Calculation
class UserLocationNotifier extends Notifier<UserLocationState> {
  @override
  UserLocationState build() {
    // Initial state - position not yet fetched
    return const UserLocationState(
      position: null,
      permissionStatus: LocationPermissionStatus.denied,
      isLoading: false,
    );
  }

  /// Load user's current position.
  Future<void> loadPosition() async {
    final locationService = ref.read(locationServiceProvider);

    state = state.copyWith(isLoading: true, error: null);

    try {
      final status = await locationService.getPermissionStatus();
      state = state.copyWith(permissionStatus: status);

      if (status == LocationPermissionStatus.granted) {
        final position = await locationService.getCurrentPosition();
        state = state.copyWith(position: position, isLoading: false);
      } else {
        state = state.copyWith(position: null, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        position: null,
        isLoading: false,
        error: 'Không thể lấy vị trí',
      );
    }
  }

  /// Request location permission.
  Future<bool> requestPermission() async {
    final locationService = ref.read(locationServiceProvider);

    final granted = await locationService.requestPermission();

    if (granted) {
      await loadPosition();
    } else {
      state = state.copyWith(permissionStatus: LocationPermissionStatus.denied);
    }

    return granted;
  }

  /// Open app settings for permission.
  Future<void> openSettings() async {
    final locationService = ref.read(locationServiceProvider);
    await locationService.openSettings();
  }

  /// Refresh position (clears cache and reloads).
  Future<void> refreshPosition() async {
    final locationService = ref.read(locationServiceProvider);
    locationService.clearCache();
    await loadPosition();
  }
}

/// State for user location.
class UserLocationState {
  final Position? position;
  final LocationPermissionStatus permissionStatus;
  final bool isLoading;
  final String? error;

  const UserLocationState({
    this.position,
    required this.permissionStatus,
    required this.isLoading,
    this.error,
  });

  /// Check if user has valid position.
  bool get hasPosition => position != null;

  /// Check if permission is granted.
  bool get isPermissionGranted =>
      permissionStatus == LocationPermissionStatus.granted;

  /// Check if permission was denied.
  bool get isPermissionDenied =>
      permissionStatus == LocationPermissionStatus.denied ||
      permissionStatus == LocationPermissionStatus.permanentlyDenied;

  /// Create copy with modified fields.
  UserLocationState copyWith({
    Position? position,
    LocationPermissionStatus? permissionStatus,
    bool? isLoading,
    String? error,
  }) {
    return UserLocationState(
      position: position ?? this.position,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for user location state.
///
/// Story 8-0.5: GPS-Based Distance Calculation
final userLocationProvider =
    NotifierProvider<UserLocationNotifier, UserLocationState>(
      UserLocationNotifier.new,
    );
