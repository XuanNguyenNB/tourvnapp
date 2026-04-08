import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/map_launcher_service.dart';
import '../../../auth/presentation/helpers/sign_in_prompt_helper.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/pending_activity.dart';
import '../../domain/services/trip_share_service.dart';
import '../helpers/visual_planner_snackbars.dart';
import '../providers/pending_trip_provider.dart';
import '../providers/active_trip_provider.dart';
import '../providers/visual_planner_provider.dart';
import '../widgets/conflict_indicators.dart';
import '../widgets/day_pills_selector.dart';
import '../widgets/activity_timeline.dart';

/// Visual Planner Screen - displays trip as a visual timeline.
///
/// Shows:
/// - Header with "Day X in [Destination]" format
/// - Day selector pills for switching between days
/// - Activity timeline with cards and dotted connectors
/// - Empty state when no activities
/// - FAB for saving trip
///
/// Can be opened with a saved trip ID or from pending state.
class VisualPlannerScreen extends ConsumerStatefulWidget {
  /// Create screen for a saved trip by ID.
  const VisualPlannerScreen({super.key, required this.tripId})
    : isFromPending = false;

  /// Create screen for pending trip (not yet saved).
  const VisualPlannerScreen.fromPending({super.key})
    : tripId = null,
      isFromPending = true;

  /// Trip ID for saved trips (null for pending trips).
  final String? tripId;

  /// Whether this screen is displaying a pending trip.
  final bool isFromPending;

  @override
  ConsumerState<VisualPlannerScreen> createState() =>
      _VisualPlannerScreenState();
}

class _VisualPlannerScreenState extends ConsumerState<VisualPlannerScreen> {
  /// Temporarily store deleted activity for undo functionality.
  PendingActivity? _deletedActivity;


  @override
  void initState() {
    super.initState();
    // Use Future.microtask to avoid calling provider during build
    Future.microtask(() {
      if (widget.isFromPending) {
        // Load from pending activities
        ref.read(visualPlannerProvider.notifier).loadFromPending();
      } else if (widget.tripId != null) {
        // Load saved trip from Firestore
        ref.read(visualPlannerProvider.notifier).loadTrip(widget.tripId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visualPlannerProvider);


    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(state),
      body: _buildBody(state),
      bottomNavigationBar: _buildBottomBar(state),
    );
  }

  /// Build app bar with "Day X in [Destination]" header.
  PreferredSizeWidget _buildAppBar(VisualPlannerState state) {
    final trip = state.currentTrip;
    final headerText = trip != null
        ? 'Ngày ${state.selectedDayNumber} - ${trip.destinationName}'
        : 'Ngày ${state.selectedDayNumber}';

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        headerText,
        style: AppTypography.headingMD.copyWith(color: AppColors.textPrimary),
      ),
      centerTitle: true,
      actions: [
        // View route on Google Maps
        if (trip != null)
          IconButton(
            icon: const Icon(Icons.map_outlined, color: AppColors.textPrimary),
            tooltip: 'Xem lộ trình',
            onPressed: () => _openRouteInMaps(state),
          ),
        // Share trip
        if (trip != null)
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Chia sẻ',
            onPressed: () => _shareTrip(state),
          ),
      ],
    );
  }

  /// Build bottom bar above navigation bar.
  Widget? _buildBottomBar(VisualPlannerState state) {
    final trip = state.currentTrip;
    if (trip == null) return null;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Save button (only for pending trips)
          if (state.isPending) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.isSaving ? null : _saveTrip,
                icon: state.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.save, size: 20),
                label: Text(state.isSaving ? 'Đang lưu...' : 'Lưu chuyến đi'),
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
            const SizedBox(height: 8),
          ],
          // Add location button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(activeTripProvider.notifier).setActiveTrip(trip);
                context.pushNamed(
                  AppRoutes.destination,
                  pathParameters: {'id': trip.destinationId},
                );
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Thêm địa điểm'),
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
          // Completion progress bar (only for saved trips with activities)
          if (!state.isPending && trip.totalActivities > 0) ...[
            const SizedBox(height: 12),
            _buildCompletionProgressBar(state),
          ],
        ],
      ),
    );
  }

  /// Build completion progress bar for saved trips.
  Widget _buildCompletionProgressBar(VisualPlannerState state) {
    final completed = state.totalCompletedCount;
    final total = state.currentTrip?.totalActivities ?? 0;
    final progress = state.completionProgress;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: progress >= 1.0
            ? Colors.green.shade50
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: progress >= 1.0
              ? Colors.green.shade200
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            progress >= 1.0
                ? Icons.check_circle
                : Icons.checklist_rounded,
            size: 20,
            color: progress >= 1.0 ? Colors.green : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            progress >= 1.0
                ? 'Hoàn thành! 🎉'
                : 'Tiến độ: $completed/$total',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: progress >= 1.0
                  ? Colors.green.shade700
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? Colors.green : AppColors.primary,
                ),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build main body with day selector and timeline.
  Widget _buildBody(VisualPlannerState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _buildErrorState(state.error!);
    }

    final trip = state.currentTrip;
    if (trip == null) {
      return _buildEmptyTripState();
    }

    // Get conflict days for badge indicators
    final conflictDays = state.getConflictDays();
    final currentDayHasConflict = conflictDays.contains(
      state.selectedDayNumber,
    );

    return Column(
      children: [
        // Day selector pills with conflict badges
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: DayPillsSelector(
            totalDays: trip.totalDays,
            selectedDay: state.selectedDayNumber,
            conflictDays: conflictDays,
            onDaySelected: (day) {
              ref.read(visualPlannerProvider.notifier).selectDay(day);
            },
          ),
        ),
        // Date subtitle
        _buildDateSubtitle(state),
        const Divider(height: 1, color: AppColors.border),
        // Conflict warning header if current day has multiple destinations
        if (currentDayHasConflict) _buildConflictHeader(state),
        // Activity timeline
        Expanded(child: _buildTimelineContent(state)),
      ],
    );
  }

  /// Build a conflict warning header showing day has multiple destinations.
  Widget _buildConflictHeader(VisualPlannerState state) {
    final currentDay = state.currentDay;
    final destNames = currentDay?.allDestinationNames ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border(bottom: BorderSide(color: Colors.amber.shade200)),
      ),
      child: Row(
        children: [
          const MultiDestinationBadge(),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              destNames.length <= 2
                  ? destNames.join(' & ')
                  : '${destNames.length} điểm đến khác nhau',
              style: AppTypography.bodySM.copyWith(
                color: Colors.amber.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Build timeline or empty state based on activities.
  Widget _buildTimelineContent(VisualPlannerState state) {
    final activities = state.activitiesForCurrentDay;

    if (activities.isEmpty) {
      return _buildEmptyDayState();
    }

    return ActivityTimeline(
      activities: activities,
      onActivityTap: (activity) {
        context.pushNamed(
          AppRoutes.locationStandalone,
          pathParameters: {
            'destId': activity.destinationId ?? 'unknown',
            'locId': activity.locationId,
          },
        );
      },
      onActivityDelete: _handleActivityDelete,
      onReorder: (oldIndex, newIndex) => _handleActivityReorder(
        state.selectedDayNumber - 1,
        oldIndex,
        newIndex,
      ),
      // Only show completion toggle for saved trips
      onActivityComplete: !state.isPending
          ? (activity, isCompleted) {
              ref.read(visualPlannerProvider.notifier).toggleActivityCompletion(
                state.selectedDayNumber - 1,
                activity.id,
              );
            }
          : null,
      // Show map button only for saved trips
      showMapButton: !state.isPending,
    );
  }

  /// Handle activity reorder within current day.
  void _handleActivityReorder(int dayIndex, int oldIndex, int newIndex) {
    final state = ref.read(visualPlannerProvider);

    // Only handle reorder for pending trips
    if (state.isPending) {
      ref
          .read(pendingTripProvider.notifier)
          .reorderActivitiesForDay(dayIndex, oldIndex, newIndex);

      // Refresh visual planner to reflect changes
      ref.read(visualPlannerProvider.notifier).refresh();
    } else {
      // TODO: Handle saved trip reordering (Story 5-7)
    }
  }

  /// Temporarily store deleted activity info for undo (saved trips).
  Activity? _deletedSavedActivity;
  int? _deletedDayIndex;
  int? _deletedOriginalIndex;

  /// Handle activity deletion with undo support.
  /// Returns true if delete succeeded, false to cancel the dismiss animation.
  Future<bool> _handleActivityDelete(Activity activity) async {
    final state = ref.read(visualPlannerProvider);
    final dayIndex = state.selectedDayNumber - 1;

    if (state.isPending) {
      // --- Pending trip: delete from pending state ---
      final pendingState = ref.read(pendingTripProvider);
      final pendingActivity = pendingState.activities.firstWhere(
        (a) => a.id == activity.id,
        orElse: () => throw StateError('Activity not found in pending state'),
      );

      _deletedActivity = pendingActivity as PendingActivity?;

      ref.read(pendingTripProvider.notifier).removeActivity(activity.id);
      ref.read(visualPlannerProvider.notifier).refresh();

      VisualPlannerSnackBars.showUndoDelete(
        context: context,
        activityName: activity.locationName,
        onUndo: _undoDelete,
      );
      return true;
    } else {
      // --- Saved trip: delete from Firestore ---
      // Store info for undo
      final currentActivities = state.activitiesForCurrentDay;
      _deletedOriginalIndex = currentActivities.indexWhere(
        (a) => a.id == activity.id,
      );
      _deletedDayIndex = dayIndex;

      final removed = await ref
          .read(visualPlannerProvider.notifier)
          .removeActivityFromSavedTrip(dayIndex, activity.id);

      if (removed != null) {
        _deletedSavedActivity = removed;

        VisualPlannerSnackBars.showUndoDelete(
          context: context,
          activityName: activity.locationName,
          onUndo: _undoDeleteSaved,
        );
        return true;
      } else {
        VisualPlannerSnackBars.showError(
          context,
          message: 'Không thể xóa hoạt động',
        );
        return false;
      }
    }
  }

  /// Restore the last deleted activity (pending trips).
  void _undoDelete() {
    if (_deletedActivity == null) return;
    ref.read(pendingTripProvider.notifier).restoreActivity(_deletedActivity!);
    ref.read(visualPlannerProvider.notifier).refresh();
    HapticFeedback.lightImpact();
    _deletedActivity = null;
  }

  /// Restore the last deleted activity (saved trips).
  void _undoDeleteSaved() {
    if (_deletedSavedActivity == null ||
        _deletedDayIndex == null ||
        _deletedOriginalIndex == null) return;

    ref.read(visualPlannerProvider.notifier).restoreActivityToSavedTrip(
          _deletedDayIndex!,
          _deletedSavedActivity!,
          _deletedOriginalIndex!,
        );
    HapticFeedback.lightImpact();
    _deletedSavedActivity = null;
    _deletedDayIndex = null;
    _deletedOriginalIndex = null;
  }

  /// Open current day's activities as a multi-stop route in Google Maps.
  void _openRouteInMaps(VisualPlannerState state) {
    final activities = state.activitiesForCurrentDay;
    if (activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có hoạt động nào để xem lộ trình'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // We need to get coordinates — use the provider to fetch locations
    final trip = state.currentTrip;
    if (trip == null) return;

    // Build waypoints from activities
    // Note: Activities don't store coordinates directly,
    // so we open Google Maps with location names as search queries
    final locationNames = activities.map((a) => a.locationName).toList();
    final destination = trip.destinationName;

    // Build Google Maps directions URL with place names
    final origin = Uri.encodeComponent('${locationNames.first}, $destination');
    final dest = Uri.encodeComponent('${locationNames.last}, $destination');
    final middleWaypoints = locationNames.length > 2
        ? locationNames
            .sublist(1, locationNames.length - 1)
            .map((n) => Uri.encodeComponent('$n, $destination'))
            .join('|')
        : '';

    final url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=$origin'
        '&destination=$dest'
        '${middleWaypoints.isNotEmpty ? '&waypoints=$middleWaypoints' : ''}'
        '&travelmode=driving';

    HapticFeedback.lightImpact();
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// Share the current trip itinerary.
  void _shareTrip(VisualPlannerState state) {
    final trip = state.currentTrip;
    if (trip == null) return;
    HapticFeedback.lightImpact();
    const TripShareService().shareTrip(trip);
  }

  /// Build error state UI.
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Đã xảy ra lỗi', style: AppTypography.headingMD),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: AppTypography.bodySM.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state when trip has no data.
  Widget _buildEmptyTripState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.luggage_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Không tìm thấy chuyến đi',
              style: AppTypography.headingMD,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Chuyến đi này không tồn tại hoặc đã bị xóa.',
              style: AppTypography.bodySM.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state when current day has no activities.
  Widget _buildEmptyDayState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chưa có hoạt động nào',
              style: AppTypography.headingMD,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Khám phá các địa điểm và thêm vào lịch trình của bạn!',
              style: AppTypography.bodySM.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build date subtitle below day pills showing actual date.
  Widget _buildDateSubtitle(VisualPlannerState state) {
    final pendingState = ref.watch(pendingTripProvider);
    final startDate = pendingState.startDate;
    if (startDate == null) return const SizedBox.shrink();

    final dayOffset = state.selectedDayNumber - 1;
    final currentDate = startDate.add(Duration(days: dayOffset));
    final dateStr = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(currentDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        dateStr,
        style: AppTypography.bodySM.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  /// Save trip action with sign-in prompt for anonymous users.
  Future<void> _saveTrip() async {
    final result = await ref.read(visualPlannerProvider.notifier).saveTrip();
    if (!mounted) return;

    switch (result) {
      case SaveTripResult.success:
        _navigateToSavedTrip();
        break;
      case SaveTripResult.needsSignIn:
        await _showSignInPromptAndSave();
        break;
      case SaveTripResult.error:
        VisualPlannerSnackBars.showError(context);
        break;
      case SaveTripResult.noTrip:
        VisualPlannerSnackBars.showError(
          context,
          message: 'Không có chuyến đi để lưu',
        );
        break;
    }
  }

  /// Navigate to the saved trip detail, replacing AI plan and planner from stack.
  void _navigateToSavedTrip() {
    final savedTrip = ref.read(visualPlannerProvider).currentTrip;
    if (savedTrip != null && savedTrip.id != 'pending') {
      VisualPlannerSnackBars.showSuccess(context);
      context.goNamed(
        AppRoutes.tripDetail,
        pathParameters: {'id': savedTrip.id},
      );
    }
  }

  /// Show sign-in prompt and auto-save after successful sign-in.
  Future<void> _showSignInPromptAndSave() async {
    await showSignInPrompt(
      context: context,
      onSignInSuccess: () async {
        if (mounted) {
          final retryResult = await ref
              .read(visualPlannerProvider.notifier)
              .saveTrip();
          if (mounted && retryResult == SaveTripResult.success) {
            _navigateToSavedTrip();
          }
        }
      },
      onDismiss: () {
        if (mounted) VisualPlannerSnackBars.showNotSaved(context);
      },
    );
  }
}
