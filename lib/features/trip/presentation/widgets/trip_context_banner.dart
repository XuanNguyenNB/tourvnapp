import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/active_trip_provider.dart';
import '../providers/visual_planner_provider.dart';

/// Banner displaying the active trip currently being planned.
///
/// Shows at the top of Destination Hub when an active trip is set.
/// Allows the user to finish and navigate back to the trip via the "Xong" button.
class TripContextBanner extends ConsumerWidget {
  const TripContextBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the active trip provider to re-render when it changes
    final activeTrip = ref.watch(activeTripProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: activeTrip != null ? 44.0 : 0.0,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
      ),
      child: ClipRect(
        child: SingleChildScrollView(
          // To prevent overflow during animation
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            height: 44.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '📌 Đang lên kế hoạch: ${activeTrip?.name ?? ''}',
                      style: AppTypography.labelMD.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: activeTrip != null
                        ? () {
                            final tripId = activeTrip.id;
                            ref
                                .read(activeTripProvider.notifier)
                                .clearActiveTrip();
                            // Force reload trip data from Firestore
                            // so Visual Planner shows the latest state
                            ref
                                .read(visualPlannerProvider.notifier)
                                .loadTrip(tripId);
                            // Navigate back to trip detail
                            context.go('/trips/$tripId');
                          }
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Xong',
                      style: AppTypography.labelMD.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
