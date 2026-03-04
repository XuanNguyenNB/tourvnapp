import 'package:flutter/material.dart';
import '../../../../core/utils/distance_calculator.dart';

/// Widget displaying distance from user to a location.
///
/// Shows:
/// - "📍 2.5km" when distance is available
/// - Nothing when distance is null (location has no GPS)
/// - Permission prompt when location permission is denied
///
/// Story 8-0.5: GPS-Based Distance Calculation
class DistanceBadge extends StatelessWidget {
  /// Distance in meters to display
  final double? distanceMeters;

  /// Whether location permission was denied
  final bool permissionDenied;

  /// Callback when user taps to enable location
  final VoidCallback? onEnableLocation;

  /// Badge style variant
  final DistanceBadgeStyle style;

  const DistanceBadge({
    super.key,
    this.distanceMeters,
    this.permissionDenied = false,
    this.onEnableLocation,
    this.style = DistanceBadgeStyle.dark,
  });

  @override
  Widget build(BuildContext context) {
    // Show permission prompt if denied
    if (permissionDenied) {
      return _buildPermissionPrompt();
    }

    // Hide if no distance data
    if (distanceMeters == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '📍',
            style: TextStyle(
              fontSize: style == DistanceBadgeStyle.compact ? 10 : 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            DistanceCalculator.format(distanceMeters!),
            style: TextStyle(
              color: _getTextColor(),
              fontSize: style == DistanceBadgeStyle.compact ? 10 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (style) {
      case DistanceBadgeStyle.dark:
        return Colors.black54;
      case DistanceBadgeStyle.light:
        return Colors.white.withOpacity(0.9);
      case DistanceBadgeStyle.compact:
        return Colors.black.withOpacity(0.6);
    }
  }

  Color _getTextColor() {
    switch (style) {
      case DistanceBadgeStyle.dark:
      case DistanceBadgeStyle.compact:
        return Colors.white;
      case DistanceBadgeStyle.light:
        return const Color(0xFF374151);
    }
  }

  Widget _buildPermissionPrompt() {
    return GestureDetector(
      onTap: onEnableLocation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 12,
              color: Color(0xFF92400E),
            ),
            const SizedBox(width: 4),
            Text(
              'Bật vị trí',
              style: TextStyle(
                color: const Color(0xFF92400E),
                fontSize: style == DistanceBadgeStyle.compact ? 10 : 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Style variants for DistanceBadge.
enum DistanceBadgeStyle {
  /// Dark background, white text (for overlays on images)
  dark,

  /// Light background, dark text (for light backgrounds)
  light,

  /// Compact size for inline use
  compact,
}

/// Widget for displaying "--" when distance is unavailable.
///
/// Used when location doesn't have GPS coordinates.
class DistancePlaceholder extends StatelessWidget {
  const DistancePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('📍', style: TextStyle(fontSize: 12)),
          SizedBox(width: 4),
          Text(
            '--',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
