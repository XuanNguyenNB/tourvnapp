import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/location.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../trip/presentation/widgets/add_to_trip_gesture_wrapper.dart';
import '../../../home/presentation/widgets/distance_badge.dart';

/// Location card widget for Destination Hub grid.
///
/// Displays location with:
/// - Full-width hero image (rounded corners)
/// - Location name overlay
/// - Engagement metrics (views, saves)
/// - Category badge
/// - Distance badge (Story 8-0.5)
///
/// Based on Figma design node 1-220.
class LocationCard extends StatelessWidget {
  /// Location data to display
  final Location location;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Distance from user to this location in meters (null if unavailable)
  final double? distanceMeters;

  /// Whether location permission is denied
  final bool permissionDenied;

  /// Callback when user taps to enable location
  final VoidCallback? onEnableLocation;

  const LocationCard({
    super.key,
    required this.location,
    this.onTap,
    this.distanceMeters,
    this.permissionDenied = false,
    this.onEnableLocation,
  });

  @override
  Widget build(BuildContext context) {
    return AddToTripGestureWrapper(
      itemData: TripItemData.fromLocation(
        id: location.id,
        name: location.name,
        imageUrl: location.image,
        categoryEmoji: location.categoryEmoji,
        destinationId: location.destinationId,
        destinationName: location.resolvedDestinationName,
      ),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background image
              _buildImage(),

              // Gradient overlay for text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // Category badge (top-left)
              Positioned(top: 8, left: 8, child: _buildCategoryBadge()),

              // Distance badge (top-right) - Story 8-0.5
              if (distanceMeters != null || permissionDenied)
                Positioned(
                  top: 8,
                  right: 8,
                  child: DistanceBadge(
                    distanceMeters: distanceMeters,
                    permissionDenied: permissionDenied,
                    onEnableLocation: onEnableLocation,
                    style: DistanceBadgeStyle.dark,
                  ),
                ),

              // Content overlay (bottom)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Location name
                    Text(
                      location.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Engagement metrics row
                    _buildMetricsRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return AspectRatio(
      aspectRatio: 0.85, // Slightly taller than wide for location cards
      child: CachedNetworkImage(
        imageUrl: location.image,
        fit: BoxFit.cover,
        memCacheHeight: 400,
        placeholder: (context, url) =>
            const ShimmerPlaceholder.card(width: double.infinity, height: 200),
        errorWidget: (context, url, error) => Container(
          color: const Color(0xFFE2E8F0),
          child: const Center(
            child: Icon(
              Icons.image_not_supported,
              color: Color(0xFF94A3B8),
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge() {
    final (bgColor, textColor) = _getCategoryColors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(location.categoryEmoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            location.category.substring(0, 1).toUpperCase() +
                location.category.substring(1),
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _getCategoryColors() {
    switch (location.category.toLowerCase()) {
      case 'food':
        return (const Color(0xFFFEF3C7), const Color(0xFF92400E));
      case 'places':
        return (const Color(0xFFDBEAFE), const Color(0xFF1E40AF));
      case 'stay':
        return (const Color(0xFFD1FAE5), const Color(0xFF065F46));
      default:
        return (const Color(0xFFF1F5F9), const Color(0xFF475569));
    }
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        // Views
        Icon(
          Icons.visibility_outlined,
          size: 12,
          color: Colors.white.withOpacity(0.9),
        ),
        const SizedBox(width: 4),
        Text(
          location.formattedViewCount,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),

        // Saves
        Icon(
          Icons.bookmark_outline,
          size: 12,
          color: Colors.white.withOpacity(0.9),
        ),
        const SizedBox(width: 4),
        Text(
          location.formattedSaveCount,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
