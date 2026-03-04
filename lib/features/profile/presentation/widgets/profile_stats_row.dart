import 'package:flutter/material.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_radius.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';
import 'package:tour_vn/features/profile/domain/entities/user_stats.dart';

/// ProfileStatsRow - Displays user statistics in a horizontal row
///
/// Shows 3 stat cards: Trips, Saves, Reviews
/// Each card displays the count with formatted numbers (1.2k for 1200)
///
/// Usage:
/// ```dart
/// ProfileStatsRow(stats: userStats)
/// ```
class ProfileStatsRow extends StatelessWidget {
  final UserStats stats;

  const ProfileStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: stats.formattedTripCount,
            label: 'Trips',
            icon: Icons.map_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            value: stats.formattedSavesCount,
            label: 'Saves',
            icon: Icons.bookmark_outline,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            value: stats.formattedReviewsCount,
            label: 'Reviews',
            icon: Icons.rate_review_outlined,
          ),
        ),
      ],
    );
  }
}

/// Individual stat card widget
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Value (count)
          Text(
            value,
            style: AppTypography.headingLG.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Label with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.bodySM.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
