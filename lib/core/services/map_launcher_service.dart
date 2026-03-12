import 'package:url_launcher/url_launcher.dart';

/// Service for launching Google Maps with location coordinates.
///
/// Uses url_launcher to open Google Maps externally instead of embedding
/// the Maps SDK, avoiding API key setup and usage costs.
class MapLauncherService {
  const MapLauncherService();

  /// Open a single location in Google Maps.
  ///
  /// [lat] and [lng] are the GPS coordinates of the location.
  /// [label] is an optional label to display on the map pin.
  Future<bool> openLocationInMap(
    double lat,
    double lng, {
    String? label,
  }) async {
    final query = label != null
        ? Uri.encodeComponent(label)
        : '$lat,$lng';
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$query',
    );
    return _launch(uri);
  }

  /// Open directions from current location to a destination.
  ///
  /// If [fromLat] and [fromLng] are provided, those are used as origin.
  /// Otherwise, Google Maps uses the user's current location.
  Future<bool> openDirections({
    double? fromLat,
    double? fromLng,
    required double toLat,
    required double toLng,
    String? travelMode, // driving, walking, bicycling, transit
  }) async {
    final origin = (fromLat != null && fromLng != null)
        ? '$fromLat,$fromLng'
        : '';
    final destination = '$toLat,$toLng';
    final mode = travelMode ?? 'driving';

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '${origin.isNotEmpty ? '&origin=$origin' : ''}'
      '&destination=$destination'
      '&travelmode=$mode',
    );
    return _launch(uri);
  }

  /// Open a multi-stop route in Google Maps.
  ///
  /// [waypoints] is a list of coordinates with optional labels.
  /// The first item is the origin, the last is the destination,
  /// and everything in between are waypoints.
  Future<bool> openTripRoute(
    List<({double lat, double lng, String? label})> waypoints,
  ) async {
    if (waypoints.isEmpty) return false;
    if (waypoints.length == 1) {
      return openLocationInMap(
        waypoints.first.lat,
        waypoints.first.lng,
        label: waypoints.first.label,
      );
    }

    final origin = '${waypoints.first.lat},${waypoints.first.lng}';
    final destination = '${waypoints.last.lat},${waypoints.last.lng}';

    // Google Maps supports up to 9 waypoints via URL
    final middle = waypoints.length > 2
        ? waypoints
            .sublist(1, waypoints.length - 1)
            .take(9)
            .map((w) => '${w.lat},${w.lng}')
            .join('|')
        : '';

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$origin'
      '&destination=$destination'
      '${middle.isNotEmpty ? '&waypoints=$middle' : ''}'
      '&travelmode=driving',
    );
    return _launch(uri);
  }

  /// Internal helper to launch a URL.
  Future<bool> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
