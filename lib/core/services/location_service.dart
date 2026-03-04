import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling user's GPS location.
///
/// Provides methods for:
/// - Checking and requesting location permissions
/// - Getting the user's current GPS coordinates
/// - Caching location to reduce GPS calls
///
/// Story 8-0.5: GPS-Based Distance Calculation
class LocationService {
  Position? _cachedPosition;
  DateTime? _cacheTimestamp;

  /// Cache duration in seconds (avoid excessive GPS calls)
  static const int _cacheDurationSeconds = 60;

  /// Check if location permission is granted.
  Future<bool> hasPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Request location permission from the user.
  ///
  /// Returns true if permission is granted, false otherwise.
  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Check if location service is enabled on device.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Open app settings for the user to manually grant permission.
  Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Open location settings on the device.
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Get user's current GPS coordinates.
  ///
  /// Returns cached position if available and not expired.
  /// Returns null if:
  /// - Permission is denied
  /// - Location service is disabled
  /// - Unable to get location
  Future<Position?> getCurrentPosition() async {
    // Check if we have a valid cached position
    if (_cachedPosition != null && _cacheTimestamp != null) {
      final elapsed = DateTime.now().difference(_cacheTimestamp!).inSeconds;
      if (elapsed < _cacheDurationSeconds) {
        return _cachedPosition;
      }
    }

    // Check permission
    if (!await hasPermission()) {
      return null;
    }

    // Check if location service is enabled
    if (!await isLocationServiceEnabled()) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Cache the position
      _cachedPosition = position;
      _cacheTimestamp = DateTime.now();

      return position;
    } catch (e) {
      // Location unavailable - return null gracefully
      return null;
    }
  }

  /// Clear the cached position.
  void clearCache() {
    _cachedPosition = null;
    _cacheTimestamp = null;
  }

  /// Check the current permission status.
  Future<LocationPermissionStatus> getPermissionStatus() async {
    if (!await isLocationServiceEnabled()) {
      return LocationPermissionStatus.serviceDisabled;
    }

    final status = await Permission.location.status;

    if (status.isGranted) {
      return LocationPermissionStatus.granted;
    } else if (status.isDenied) {
      return LocationPermissionStatus.denied;
    } else if (status.isPermanentlyDenied) {
      return LocationPermissionStatus.permanentlyDenied;
    }

    return LocationPermissionStatus.denied;
  }
}

/// Enum representing the location permission status.
enum LocationPermissionStatus {
  /// Permission is granted
  granted,

  /// Permission is denied (can be requested again)
  denied,

  /// Permission is permanently denied (must go to settings)
  permanentlyDenied,

  /// Location service is disabled on the device
  serviceDisabled,
}
