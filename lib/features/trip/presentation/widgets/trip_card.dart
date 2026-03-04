import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_radius.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';
import 'package:tour_vn/features/home/domain/utils/destination_emoji_helper.dart';
import 'package:tour_vn/features/trip/domain/entities/trip.dart';

/// TripCard - A card widget displaying trip information in a list.
///
/// Displays trip cover image, name, destination, and trip statistics.
/// Tapping triggers navigation to Visual Planner screen.
///
/// Design specs:
/// - Full width with 16px horizontal margin (applied by parent)
/// - Height: ~160px (image 100px + info section 60px)
/// - Border radius: 12px (AppRadius.md)
/// - Shadow: subtle elevation
class TripCard extends StatelessWidget {
  final Trip trip;
  final String? coverImageUrl;
  final VoidCallback? onTap;

  const TripCard({
    super.key,
    required this.trip,
    this.coverImageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cover image section
            _buildCoverImage(),
            // Info section
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    onTap?.call();
  }

  /// Builds the cover image with gradient overlay.
  Widget _buildCoverImage() {
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover image
          _buildImageContent(),
          // Gradient overlay at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    if (coverImageUrl != null && coverImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final destEmoji = DestinationEmojiHelper.getEmoji(trip.destinationId);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: Center(
        child: Text(destEmoji, style: const TextStyle(fontSize: 48)),
      ),
    );
  }

  /// Builds the info section with trip details.
  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trip name
          Text(
            trip.name,
            style: AppTypography.headingMD.copyWith(
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          // Subtitle with destination and stats
          Row(
            children: [
              // Destination name
              Expanded(
                child: Text(
                  trip.destinationName,
                  style: AppTypography.bodySM.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Stats badges - wrap in Flexible to prevent overflow
              Flexible(flex: 0, child: _buildStatsBadges()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBadges() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Days count
        _buildBadge(
          icon: Icons.calendar_today_outlined,
          text: '${trip.totalDays} ngày',
        ),
        const SizedBox(width: AppSpacing.sm),
        // Activities count
        _buildBadge(
          icon: Icons.place_outlined,
          text: '${trip.totalActivities} điểm',
        ),
      ],
    );
  }

  Widget _buildBadge({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
