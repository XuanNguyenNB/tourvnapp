import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tour_vn/core/router/app_router.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_radius.dart';
import 'package:tour_vn/core/theme/app_typography.dart';
import 'package:tour_vn/features/auth/presentation/providers/auth_provider.dart';
import 'package:tour_vn/features/trip/domain/entities/trip.dart';
import 'package:tour_vn/features/trip/data/repositories/trip_repository.dart';
import 'package:tour_vn/features/trip/presentation/providers/trip_save_provider.dart';
import 'package:tour_vn/features/trip/presentation/providers/trips_provider.dart';
import 'package:tour_vn/features/trip/presentation/widgets/empty_trips_state.dart';
import 'package:tour_vn/features/trip/presentation/widgets/trip_card.dart';
import 'package:tour_vn/features/trip/presentation/widgets/trip_card_shimmer.dart';

/// TripsScreen - Display user's saved trips.
///
/// Shows a list of all saved trips for the current user.
/// Handles empty state, loading state, and error state.
/// Tapping a trip navigates to Visual Planner.
///
/// Stories: 5-8 (Implement Trips List Screen), 5-9 (Implement Delete Trip)
class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  /// Tracks trips currently being deleted to prevent double-tap
  static final Set<String> _deletingTrips = {};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnonymous = ref.watch(isAnonymousProvider);
    final currentUser = ref.watch(currentUserProvider);
    final tripsAsync = ref.watch(userTripsProvider);

    // If truly anonymous (no user at all or anonymous user), show sign-in prompt
    final bool showSignInPrompt = currentUser == null || isAnonymous;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Chuyến đi của bạn',
          style: AppTypography.headingLG.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
      ),
      body: showSignInPrompt
          ? _buildAnonymousState(context, ref)
          : _buildTripsContent(context, ref, tripsAsync),
      bottomNavigationBar: _buildBottomCreateBar(context, ref, showSignInPrompt, tripsAsync),
    );
  }

  /// Builds content for anonymous/signed-out users.
  Widget _buildAnonymousState(BuildContext context, WidgetRef ref) {
    return EmptyTripsState(
      isSignedIn: false,
      onSignIn: () => _handleSignIn(context),
    );
  }

  /// Builds a persistent bottom bar with create options.
  /// Only shown when user is signed in and has trips.
  Widget? _buildBottomCreateBar(
    BuildContext context,
    WidgetRef ref,
    bool showSignInPrompt,
    AsyncValue<List<Trip>> tripsAsync,
  ) {
    final hasTrips = tripsAsync.hasValue && (tripsAsync.value?.isNotEmpty ?? false);
    if (showSignInPrompt || !hasTrips) return null;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: 12,
        bottom: MediaQuery.paddingOf(context).bottom + 80,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.pushNamed(AppRoutes.aiPlan);
              },
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('AI lên lịch'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.pushNamed(AppRoutes.createTrip);
              },
              icon: const Icon(Icons.edit_calendar, size: 18),
              label: const Text('Tự lên lịch'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main trips content based on AsyncValue state.
  Widget _buildTripsContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Trip>> tripsAsync,
  ) {
    return tripsAsync.when(
      data: (trips) => trips.isEmpty
          ? _buildEmptyState(context, ref)
          : _buildTripsList(context, ref, trips),
      loading: () => const TripCardsShimmerList(),
      error: (error, stack) => _buildErrorState(context, ref, error),
    );
  }

  /// Builds empty state for signed-in users with no trips.
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return EmptyTripsState(
      isSignedIn: true,
      onAutoPlan: () {
        HapticFeedback.lightImpact();
        context.pushNamed(AppRoutes.aiPlan);
      },
      onExplore: () {
        HapticFeedback.lightImpact();
        context.pushNamed(AppRoutes.createTrip);
      },
    );
  }

  /// Builds the list of trip cards with swipe-to-delete.
  Widget _buildTripsList(
    BuildContext context,
    WidgetRef ref,
    List<Trip> trips,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: 160,
      ),
      itemCount: trips.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final trip = trips[index];
        return _buildDismissibleTripCard(context, ref, trip);
      },
    );
  }

  /// Wraps TripCard with Dismissible for swipe-to-delete.
  Widget _buildDismissibleTripCard(
    BuildContext context,
    WidgetRef ref,
    Trip trip,
  ) {
    return Dismissible(
      key: Key('dismiss_${trip.id}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.4},
      confirmDismiss: (_) => _showDeleteConfirmationDialog(context, trip),
      onDismissed: (_) => _deleteTrip(context, ref, trip),
      background: _buildDeleteBackground(),
      child: TripCard(
        key: ValueKey('trip_${trip.id}'),
        trip: trip,
        coverImageUrl: trip.coverImageUrl,
        onTap: () => _navigateToTrip(context, trip),
      ),
    );
  }

  /// Builds red delete background with trash icon for swipe action.
  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.delete_outline, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            'Xóa',
            style: AppTypography.labelMD.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Shows confirmation dialog before deleting a trip.
  Future<bool> _showDeleteConfirmationDialog(
    BuildContext context,
    Trip trip,
  ) async {
    // Prevent deletion if already in progress
    if (_deletingTrips.contains(trip.id)) {
      return false;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Xóa chuyến đi?',
          style: AppTypography.headingMD.copyWith(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc muốn xóa "${trip.name}"?',
              style: AppTypography.bodyMD.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Hành động này không thể hoàn tác.',
              style: AppTypography.bodySM.copyWith(color: AppColors.error),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Hủy',
              style: AppTypography.labelMD.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Xóa',
              style: AppTypography.labelMD.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Deletes trip from Firestore and shows snackbar feedback.
  Future<void> _deleteTrip(
    BuildContext context,
    WidgetRef ref,
    Trip trip,
  ) async {
    // Mark as deleting to prevent double-tap
    _deletingTrips.add(trip.id);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        _deletingTrips.remove(trip.id);
        return;
      }

      // Haptic feedback for delete action
      HapticFeedback.mediumImpact();

      // Delete from Firestore
      await ref.read(tripRepositoryProvider).deleteTrip(userId, trip.id);

      // Show success SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa chuyến đi "${trip.name}"'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Show error SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể xóa chuyến đi. Vui lòng thử lại.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _deletingTrips.remove(trip.id);
    }
  }

  /// Builds error state with retry button.
  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.error_outline,
                  size: 40,
                  color: AppColors.error,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Không thể tải chuyến đi',
              style: AppTypography.headingMD.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Đã xảy ra lỗi khi tải danh sách chuyến đi. Vui lòng thử lại.',
              style: AppTypography.bodyMD.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            // Retry button
            TextButton.icon(
              onPressed: () => _handleRetry(ref),
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              label: Text(
                'Thử lại',
                style: AppTypography.labelMD.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTrip(BuildContext context, Trip trip) {
    HapticFeedback.lightImpact();
    context.pushNamed(AppRoutes.tripDetail, pathParameters: {'id': trip.id});
  }

  void _navigateToExplore(BuildContext context) {
    HapticFeedback.lightImpact();
    context.goNamed(AppRoutes.home);
  }

  void _handleSignIn(BuildContext context) {
    HapticFeedback.lightImpact();
    context.pushNamed(AppRoutes.login);
  }

  void _handleRetry(WidgetRef ref) {
    HapticFeedback.lightImpact();
    ref.invalidate(userTripsProvider);
  }

}
