import 'package:flutter/foundation.dart';
import 'trip_day.dart';

/// Represents a specific change made during schedule optimization.
@immutable
class OptimizationChange {
  final int fromDay;
  final int toDay;
  final String activityName;
  final String reason;

  const OptimizationChange({
    required this.fromDay,
    required this.toDay,
    required this.activityName,
    required this.reason,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OptimizationChange &&
        other.fromDay == fromDay &&
        other.toDay == toDay &&
        other.activityName == activityName &&
        other.reason == reason;
  }

  @override
  int get hashCode =>
      fromDay.hashCode ^
      toDay.hashCode ^
      activityName.hashCode ^
      reason.hashCode;

  @override
  String toString() {
    return 'OptimizationChange(from: Day $fromDay, to: Day $toDay, activity: $activityName, reason: $reason)';
  }
}

/// Result of running the AI Schedule Optimization algorithm on a trip.
@immutable
class ScheduleOptimizationResult {
  /// The newly ordered list of days with their activities.
  final List<TripDay> optimizedDays;

  /// The estimated travel time saved in minutes.
  final int totalTravelTimeSavedMin;

  /// The estimated travel distance saved in kilometers.
  final double totalDistanceSavedKm;

  /// A human-readable list of changes that were made.
  final List<OptimizationChange> changes;

  /// The total estimated travel time (in minutes) BEFORE optimization.
  final int originalTravelTimeMin;

  /// The total estimated travel time (in minutes) AFTER optimization.
  final int optimizedTravelTimeMin;

  /// Indicates if any meaningful changes were made to the schedule.
  bool get hasChanges => changes.isNotEmpty;

  const ScheduleOptimizationResult({
    required this.optimizedDays,
    required this.totalTravelTimeSavedMin,
    required this.totalDistanceSavedKm,
    required this.changes,
    required this.originalTravelTimeMin,
    required this.optimizedTravelTimeMin,
  });

  /// Factory constructor for a result where no changes were necessary or possible.
  factory ScheduleOptimizationResult.noChanges({
    required List<TripDay> originalDays,
    required int originalTravelTimeMin,
  }) {
    return ScheduleOptimizationResult(
      optimizedDays: originalDays,
      totalTravelTimeSavedMin: 0,
      totalDistanceSavedKm: 0.0,
      changes: const [],
      originalTravelTimeMin: originalTravelTimeMin,
      optimizedTravelTimeMin: originalTravelTimeMin,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleOptimizationResult &&
        listEquals(other.optimizedDays, optimizedDays) &&
        other.totalTravelTimeSavedMin == totalTravelTimeSavedMin &&
        other.totalDistanceSavedKm == totalDistanceSavedKm &&
        listEquals(other.changes, changes) &&
        other.originalTravelTimeMin == originalTravelTimeMin &&
        other.optimizedTravelTimeMin == optimizedTravelTimeMin;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(optimizedDays),
      totalTravelTimeSavedMin,
      totalDistanceSavedKm,
      Object.hashAll(changes),
      originalTravelTimeMin,
      optimizedTravelTimeMin,
    );
  }

  @override
  String toString() {
    return 'ScheduleOptimizationResult(optimizedDays: ${optimizedDays.length}, saved: ${totalTravelTimeSavedMin}m, changes: ${changes.length})';
  }
}
