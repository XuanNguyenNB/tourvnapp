import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_radius.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';
import 'package:tour_vn/features/profile/presentation/providers/profile_providers.dart';
import 'package:tour_vn/features/profile/presentation/widgets/trip_mini_card.dart';

/// RecentTripsSection - Displays user's recent trips in horizontal carousel
///
/// Features:
/// - Section header with "Xem tất cả" button
/// - Horizontal scrollable list of TripMiniCards (max 5)
/// - Empty state with CTA to explore
/// - Loading shimmer while fetching
class RecentTripsSection extends ConsumerWidget {
  const RecentTripsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(recentTripsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _SectionHeader(
          title: 'Chuyến đi của tôi',
          onSeeAll: () => context.go('/trips'),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Content based on async state
        tripsAsync.when(
          data: (trips) => trips.isEmpty
              ? const _EmptyTripsState()
              : _TripsCarousel(trips: trips),
          loading: () => const _TripsShimmer(),
          error: (e, st) => _TripsError(message: e.toString()),
        ),
      ],
    );
  }
}

/// Section header with title and "See all" button
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.headingMD),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Xem tất cả',
                style: AppTypography.bodySM.copyWith(color: AppColors.primary),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Horizontal scrollable carousel of trips
class _TripsCarousel extends StatelessWidget {
  final List<TripMini> trips;

  const _TripsCarousel({required this.trips});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: trips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final trip = trips[index];
          return TripMiniCard(
            trip: trip,
            onTap: () => context.push('/trips/${trip.id}'),
          );
        },
      ),
    );
  }
}

/// Empty state when user has no trips
class _EmptyTripsState extends StatelessWidget {
  const _EmptyTripsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.explore_outlined,
            size: 32,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Chưa có chuyến đi nào',
            style: AppTypography.bodySM.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'Bắt đầu khám phá ngay!',
            style: AppTypography.caption.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

/// Loading shimmer for trips
class _TripsShimmer extends StatelessWidget {
  const _TripsShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) => Container(
          width: 140,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}

/// Error state for trips loading
class _TripsError extends StatelessWidget {
  final String message;

  const _TripsError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: Text(
          'Không tải được chuyến đi',
          style: AppTypography.bodySM.copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}
