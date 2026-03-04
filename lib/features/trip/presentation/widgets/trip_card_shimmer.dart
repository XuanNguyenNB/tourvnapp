import 'package:flutter/material.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_radius.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/widgets/shimmer_placeholder.dart';

/// TripCardShimmer - Loading skeleton for TripCard.
///
/// Matches TripCard layout with shimmer placeholders.
/// Used while trips are loading from Firestore.
///
/// Design specs:
/// - Same dimensions as TripCard
/// - Shimmer animation for loading feedback
class TripCardShimmer extends StatelessWidget {
  const TripCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Cover image shimmer
          const ShimmerPlaceholder(
            width: double.infinity,
            height: 100,
            borderRadius: 0,
          ),
          // Info section shimmer
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title shimmer
                const ShimmerPlaceholder.line(width: 180, height: 20),
                const SizedBox(height: AppSpacing.sm),
                // Subtitle row shimmer
                Row(
                  children: [
                    const Expanded(
                      child: ShimmerPlaceholder.line(width: 100, height: 14),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Badges shimmer
                    ShimmerPlaceholder(
                      width: 70,
                      height: 24,
                      borderRadius: AppRadius.full,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ShimmerPlaceholder(
                      width: 70,
                      height: 24,
                      borderRadius: AppRadius.full,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a list of shimmer cards for loading state.
class TripCardsShimmerList extends StatelessWidget {
  final int itemCount;

  const TripCardsShimmerList({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: itemCount,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => const TripCardShimmer(),
    );
  }
}
