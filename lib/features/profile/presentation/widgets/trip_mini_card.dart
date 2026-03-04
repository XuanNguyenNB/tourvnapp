import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_radius.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';
import 'package:tour_vn/features/profile/presentation/providers/profile_providers.dart';

/// TripMiniCard - Compact trip card for horizontal carousel
///
/// Displays trip thumbnail, name, destination, and day count.
/// Used in RecentTripsSection on Profile screen.
///
/// Design specs (from UX):
/// - Card Width: 140px
/// - Card Height: 100px
/// - Image Height: 60px
/// - Border Radius: 12px
class TripMiniCard extends StatelessWidget {
  final TripMini trip;
  final VoidCallback? onTap;

  const TripMiniCard({super.key, required this.trip, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip image
            SizedBox(height: 60, width: double.infinity, child: _buildImage()),
            // Trip info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2, // Reduced from AppSpacing.xs to prevent overflow
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Added to prevent overflow
                  children: [
                    // Trip name
                    Flexible(
                      child: Text(
                        trip.name,
                        style: AppTypography.bodySM.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Destination + days
                    if (trip.destination != null)
                      Flexible(
                        child: Text(
                          '${trip.destination} • ${trip.dayCount}N',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (trip.imageUrl != null && trip.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: trip.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.border,
          child: const Center(
            child: Icon(
              Icons.landscape_outlined,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.map_outlined, color: AppColors.primary, size: 24),
      ),
    );
  }
}
