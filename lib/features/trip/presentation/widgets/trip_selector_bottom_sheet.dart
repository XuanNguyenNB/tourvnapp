import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/trip.dart';
import '../providers/trips_provider.dart';
import 'trip_selector_item.dart';

class TripSelectorBottomSheet extends ConsumerWidget {
  const TripSelectorBottomSheet({super.key});

  static Future<Trip?> show({required BuildContext context}) async {
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true, // Allow custom height
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const TripSelectorBottomSheet(),
    );

    if (result == 'CREATE_NEW') {
      if (context.mounted) {
        context.pushNamed(AppRoutes.createTrip);
      }
      return null;
    }

    if (result is Trip) {
      return result;
    }

    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(userTripsProvider);
    // Limit max height to 60% of screen
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Title
            Text(
              'Thêm vào chuyến đi nào?',
              style: AppTypography.headingMD.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),

            // Content
            Flexible(
              child: tripsAsync.when(
                data: (trips) {
                  // Sort newest first
                  final sortedTrips = List<Trip>.from(trips)
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  // Take up to 5
                  final displayTrips = sortedTrips.take(5).toList();
                  final hasMore = sortedTrips.length > 5;

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: displayTrips.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                      color: AppColors.border,
                    ),
                    itemBuilder: (context, index) {
                      final trip = displayTrips[index];
                      return TripSelectorItem(
                        trip: trip,
                        onTap: () => Navigator.of(context).pop(trip),
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Text(
                      'Lỗi tải danh sách chuyến đi',
                      style: AppTypography.bodyMD.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // "+X more" indication if applicable
            if (tripsAsync.hasValue && tripsAsync.value!.length > 5) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '+${tripsAsync.value!.length - 5} chuyến đi khác...',
                style: AppTypography.bodySM.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            const Divider(height: 1, color: AppColors.border),

            // Create New Trip Button
            InkWell(
              onTap: () {
                Navigator.of(context).pop('CREATE_NEW');
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('➕', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Tạo chuyến đi mới',
                      style: AppTypography.labelMD.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
