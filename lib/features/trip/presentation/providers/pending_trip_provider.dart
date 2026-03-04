import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/pending_activity.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/entities/trip_day.dart';

/// State holding pending activities before trip creation.
///
/// Activities are stored temporarily in memory until:
/// 1. User explicitly creates a trip (Story 4-5)
/// 2. Auto-create trip triggers
class PendingTripState {
  /// List of pending activities awaiting trip creation.
  final List<PendingActivity> activities;

  /// Manually set day count (from "+Thêm ngày" button).
  /// Default is 3 days for new trips.
  final int manualDayCount;

  /// Destination ID for the trip (extracted from first activity).
  final String? destinationId;

  /// Destination name for the trip (extracted from first activity).
  final String? destinationName;

  /// AI-generated trip name (e.g., "Nha Trang biển xanh cát trắng").
  /// If null, a default name is generated from destinationName.
  final String? tripName;

  /// Start date of the trip (optional, from date picker).
  final DateTime? startDate;

  const PendingTripState({
    this.activities = const [],
    this.manualDayCount = 3,
    this.destinationId,
    this.destinationName,
    this.tripName,
    this.startDate,
  });

  /// Whether there are any pending activities.
  bool get isEmpty => activities.isEmpty;

  /// Whether there are pending activities.
  bool get isNotEmpty => activities.isNotEmpty;

  /// Number of pending activities.
  int get count => activities.length;

  /// Group activities by day index.
  ///
  /// Returns a map where keys are day indices (0-based)
  /// and values are lists of activities for that day.
  Map<int, List<PendingActivity>> get activitiesByDay {
    final map = <int, List<PendingActivity>>{};
    for (final activity in activities) {
      map.putIfAbsent(activity.dayIndex, () => []).add(activity);
    }
    return map;
  }

  /// Total number of days for the trip.
  ///
  /// Returns the maximum of:
  /// - manualDayCount (set by "+Thêm ngày" button)
  /// - Highest activity day index + 1
  int get totalDays {
    if (activities.isEmpty) return manualDayCount;
    final maxActivityDay = activities.map((a) => a.dayIndex).reduce(max) + 1;
    return max(maxActivityDay, manualDayCount);
  }

  /// Create a copy with optional field overrides.
  PendingTripState copyWith({
    List<PendingActivity>? activities,
    int? manualDayCount,
    String? destinationId,
    String? destinationName,
    String? tripName,
    DateTime? startDate,
    bool clearStartDate = false,
    bool clearTripName = false,
  }) {
    return PendingTripState(
      activities: activities ?? this.activities,
      manualDayCount: manualDayCount ?? this.manualDayCount,
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
      tripName: clearTripName ? null : (tripName ?? this.tripName),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
    );
  }

  @override
  String toString() =>
      'PendingTripState(activities: ${activities.length}, days: $totalDays)';
}

/// Notifier for managing pending trip activities.
///
/// Provides methods to:
/// - Add activities from Day Picker selection
/// - Remove activities by ID
/// - Clear all activities after trip creation
class PendingTripNotifier extends Notifier<PendingTripState> {
  @override
  PendingTripState build() => const PendingTripState();

  /// Add a pending activity to the state.
  ///
  /// Called when user confirms a selection in Day Picker.
  /// [destinationId] and [destinationName] are required for trip creation.
  void addActivity(
    PendingActivity activity, {
    required String destinationId,
    required String destinationName,
  }) {
    state = state.copyWith(
      activities: [...state.activities, activity],
      destinationId: destinationId,
      destinationName: destinationName,
    );
  }

  /// Remove a pending activity by its ID.
  ///
  /// Used when user undoes or cancels an addition.
  void removeActivity(String activityId) {
    state = state.copyWith(
      activities: state.activities.where((a) => a.id != activityId).toList(),
    );
  }

  /// Restore a previously deleted activity.
  ///
  /// Used for undo functionality after swipe-to-delete.
  /// Inserts the activity back with its original [dayIndex] and [timeSlot].
  void restoreActivity(PendingActivity activity) {
    final updatedActivities = [...state.activities, activity];
    // Sort by day index first, then by time slot order within each day
    updatedActivities.sort((a, b) {
      final dayCompare = a.dayIndex.compareTo(b.dayIndex);
      if (dayCompare != 0) return dayCompare;
      return a.timeSlot.index.compareTo(b.timeSlot.index);
    });
    state = state.copyWith(activities: updatedActivities);
  }

  /// Remove all activities for a specific day.
  void removeActivitiesForDay(int dayIndex) {
    state = state.copyWith(
      activities: state.activities
          .where((a) => a.dayIndex != dayIndex)
          .toList(),
    );
  }

  /// Add a new day to the trip plan.
  ///
  /// Called when user taps "+ Thêm ngày" button.
  void addNewDay() {
    state = state.copyWith(manualDayCount: state.totalDays + 1);
  }

  /// Reorder activities within a specific day.
  ///
  /// [dayIndex] - The day to reorder within
  /// [oldIndex] - Original position in day's activity list
  /// [newIndex] - Target position in day's activity list
  void reorderActivitiesForDay(int dayIndex, int oldIndex, int newIndex) {
    // Get activities for the specific day
    final dayActivities = state.activities
        .where((a) => a.dayIndex == dayIndex)
        .toList();

    // Skip if not enough activities or invalid indices
    if (dayActivities.length <= 1) return;
    if (oldIndex < 0 || oldIndex >= dayActivities.length) return;
    if (newIndex < 0 || newIndex >= dayActivities.length) return;
    if (oldIndex == newIndex) return;

    // Perform the reorder on a copy
    final reorderedDay = List<PendingActivity>.from(dayActivities);
    final item = reorderedDay.removeAt(oldIndex);
    reorderedDay.insert(newIndex, item);

    // Get IDs of reordered activities to replace in state
    final reorderedIds = reorderedDay.map((a) => a.id).toSet();

    // Build new activities list: keep other days, replace current day
    final otherActivities = state.activities
        .where((a) => a.dayIndex != dayIndex)
        .toList();

    state = state.copyWith(activities: [...otherActivities, ...reorderedDay]);
  }

  /// Set pending state from auto-planned [TripDay] list.
  ///
  /// Unlike [applyOptimization], this also sets destination info and day count
  /// so the resulting pending state is fully ready for trip creation.
  void setFromTripDays({
    required List<TripDay> days,
    required String destinationId,
    required String destinationName,
    String? tripName,
    DateTime? startDate,
  }) {
    final newActivities = <PendingActivity>[];

    for (final day in days) {
      for (final activity in day.activities) {
        newActivities.add(
          PendingActivity(
            id: activity.id,
            locationId: activity.locationId,
            locationName: activity.locationName,
            emoji: activity.emoji,
            imageUrl: activity.imageUrl,
            estimatedDuration: activity.estimatedDuration,
            estimatedDurationMin: activity.estimatedDurationMin,
            destinationId: activity.destinationId ?? destinationId,
            destinationName: activity.destinationName ?? destinationName,
            dayIndex: day.dayNumber - 1,
            timeSlot: TimeSlot.values.firstWhere(
              (e) => e.name.toLowerCase() == activity.timeSlot.toLowerCase(),
              orElse: () => TimeSlot.morning,
            ),
            addedAt: DateTime.now(),
          ),
        );
      }
    }

    state = state.copyWith(
      activities: newActivities,
      manualDayCount: days.length,
      destinationId: destinationId,
      destinationName: destinationName,
      tripName: tripName,
      startDate: startDate,
    );
  }

  /// Clear all pending activities and reset days.
  ///
  /// Called after trip is successfully created.
  void clear() {
    state = const PendingTripState();
  }

  /// Apply optimized schedule to pending state.
  ///
  /// Validates and replaces current activities with ones from optimized days.
  void applyOptimization(List<TripDay> optimizedDays) {
    if (optimizedDays.isEmpty) return;

    final newActivities = <PendingActivity>[];

    for (final day in optimizedDays) {
      for (final activity in day.activities) {
        newActivities.add(
          PendingActivity(
            id: activity.id,
            locationId: activity.locationId,
            locationName: activity.locationName,
            destinationId: activity.destinationId ?? state.destinationId ?? '',
            destinationName:
                activity.destinationName ?? state.destinationName ?? '',
            imageUrl: activity.imageUrl,
            emoji: activity.emoji,
            dayIndex: day.dayNumber - 1, // Convert 1-based day to 0-based index
            timeSlot: TimeSlot.values.firstWhere(
              (e) => e.name.toLowerCase() == activity.timeSlot.toLowerCase(),
              orElse: () => TimeSlot.morning,
            ),
            addedAt: DateTime.now(), // Use current time or pass it if available
          ),
        );
      }
    }

    state = state.copyWith(activities: newActivities);
  }
}

/// Provider for accessing pending trip state.
///
/// Usage:
/// ```dart
/// // Read current state
/// final pendingTrip = ref.watch(pendingTripProvider);
///
/// // Add activity
/// ref.read(pendingTripProvider.notifier).addActivity(activity);
/// ```
final pendingTripProvider =
    NotifierProvider<PendingTripNotifier, PendingTripState>(
      PendingTripNotifier.new,
    );
