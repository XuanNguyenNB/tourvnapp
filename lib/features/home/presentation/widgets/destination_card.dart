import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/destination_preview.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';

/// A card widget displaying a destination preview in the Bento Grid.
///
/// Features:
/// - Hero image with optimized caching
/// - Gradient overlay at bottom for text readability
/// - Destination name with white text
/// - Engagement badge (❤️ count) in top-right corner
///
/// See Story 3.1 AC #4, #6 for requirements.
class DestinationCard extends StatelessWidget {
  final DestinationPreview destination;
  final VoidCallback? onTap;

  const DestinationCard({super.key, required this.destination, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Hero image
              _buildHeroImage(),

              // Gradient overlay
              _buildGradientOverlay(),

              // Destination name
              _buildDestinationName(),

              // Engagement badge
              _buildEngagementBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return CachedNetworkImage(
      imageUrl: destination.heroImage,
      fit: BoxFit.cover,
      memCacheHeight: 400,
      placeholder: (context, url) => const ShimmerPlaceholder.card(
        width: double.infinity,
        height: double.infinity,
      ),
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFFE2E8F0),
        child: const Icon(
          Icons.image_not_supported,
          color: Color(0xFF94A3B8),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationName() {
    return Positioned(
      bottom: 12,
      left: 12,
      child: Text(
        destination.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementBadge() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: Color(0xFFEF4444), size: 14),
            const SizedBox(width: 4),
            Text(
              destination.formattedEngagement,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
