import 'package:tour_vn/core/config/destination_distances.dart';
import 'package:tour_vn/features/trip/domain/entities/destination_distance.dart';
import 'package:tour_vn/features/trip/domain/entities/pending_activity.dart';
import 'package:tour_vn/features/trip/domain/entities/schedule_validation_result.dart';

/// Service for validating trip schedules and detecting destination conflicts.
///
/// Provides methods to check if adding an activity creates conflicts,
/// suggest optimal days for placement, and calculate distances between
/// destinations.
class TripScheduleValidationService {
  /// Validate adding an activity to a specific day.
  ///
  /// Returns a [ScheduleValidationResult] indicating whether there are
  /// any destination conflicts and their severity.
  ///
  /// Parameters:
  /// - [existingActivities]: All current activities in the trip
  /// - [targetDayIndex]: The day (0-indexed) to add the activity to
  /// - [activityDestinationId]: The destination ID of the new activity
  /// - [activityDestinationName]: The destination name for display
  ScheduleValidationResult validateActivityAddition({
    required List<PendingActivity> existingActivities,
    required int targetDayIndex,
    required String activityDestinationId,
    required String activityDestinationName,
  }) {
    // Get activities for the target day
    final dayActivities = existingActivities
        .where((a) => a.dayIndex == targetDayIndex)
        .toList();

    // Empty day - no conflicts
    if (dayActivities.isEmpty) {
      return ScheduleValidationResult.valid();
    }

    // Get unique destinations in the target day (excluding null)
    final existingDestinations = dayActivities
        .where((a) => a.destinationId.isNotEmpty)
        .map((a) => a.destinationId)
        .toSet();

    // No existing destinations with IDs - treat as legacy data
    if (existingDestinations.isEmpty) {
      return ScheduleValidationResult.valid();
    }

    // Same destination as existing - no conflict
    if (existingDestinations.contains(activityDestinationId)) {
      return ScheduleValidationResult.valid();
    }

    // Find the closest existing destination
    DestinationDistance? closestDistance;
    String? closestDestinationId;

    for (final existingDestId in existingDestinations) {
      final distance = DestinationDistances.getDistance(
        existingDestId,
        activityDestinationId,
      );

      if (distance != null) {
        if (closestDistance == null ||
            distance.distanceKm < closestDistance.distanceKm) {
          closestDistance = distance;
          closestDestinationId = existingDestId;
        }
      }
    }

    // Unknown distance - can't determine conflict
    if (closestDistance == null || closestDestinationId == null) {
      return ScheduleValidationResult.valid();
    }

    // Get destination names for messages
    final existingDestName = dayActivities
        .firstWhere(
          (a) => a.destinationId == closestDestinationId,
          orElse: () => dayActivities.first,
        )
        .destinationName;

    // Suggest optimal day if different destination
    final suggestedDay = suggestOptimalDayForActivity(
      activities: existingActivities,
      totalDays: _getMaxDayCount(existingActivities),
      destinationId: activityDestinationId,
    );

    // Determine warning level based on distance
    final distanceKm = closestDistance.distanceKm;
    final travelTimeMin = closestDistance.travelTimeMin;

    if (distanceKm < DestinationDistances.adjacentThreshold) {
      // Adjacent destinations (<50km)
      return ScheduleValidationResult.adjacentWarning(
        message: _buildAdjacentMessage(
          existingDestName,
          activityDestinationName,
          closestDistance,
        ),
        distanceKm: distanceKm,
        travelTimeMin: travelTimeMin,
        suggestedDayIndex: suggestedDay,
      );
    } else if (distanceKm < DestinationDistances.differentThreshold) {
      // Different destinations (50-200km)
      return ScheduleValidationResult.differentWarning(
        message: _buildDifferentMessage(
          existingDestName,
          activityDestinationName,
          closestDistance,
        ),
        distanceKm: distanceKm,
        travelTimeMin: travelTimeMin,
        suggestedDayIndex: suggestedDay,
      );
    } else {
      // Distant destinations (>200km)
      return ScheduleValidationResult.distantWarning(
        message: _buildDistantMessage(
          existingDestName,
          activityDestinationName,
          closestDistance,
        ),
        distanceKm: distanceKm,
        travelTimeMin: travelTimeMin,
        suggestedDayIndex: suggestedDay,
      );
    }
  }

  /// Suggest the optimal day index for adding an activity.
  ///
  /// Finds a day that already has activities from the same destination,
  /// or returns null if no suitable day is found.
  int? suggestOptimalDayForActivity({
    required List<PendingActivity> activities,
    required int totalDays,
    required String destinationId,
  }) {
    // Find days with matching destination
    final daySet = <int>{};

    for (final activity in activities) {
      if (activity.destinationId == destinationId) {
        daySet.add(activity.dayIndex);
      }
    }

    // Return the first matching day if found
    if (daySet.isNotEmpty) {
      final sortedDays = daySet.toList()..sort();
      return sortedDays.first;
    }

    // Find empty days
    final usedDays = activities.map((a) => a.dayIndex).toSet();
    for (var i = 0; i < totalDays; i++) {
      if (!usedDays.contains(i)) {
        return i;
      }
    }

    // No suitable day found
    return null;
  }

  /// Get distance between two destinations.
  ///
  /// Performs bidirectional lookup.
  DestinationDistance? getDistanceBetween(String from, String to) {
    return DestinationDistances.getDistance(from, to);
  }

  /// Get maximum day count from activities list.
  int _getMaxDayCount(List<PendingActivity> activities) {
    if (activities.isEmpty) return 3; // Default
    final maxIndex = activities
        .map((a) => a.dayIndex)
        .reduce((a, b) => a > b ? a : b);
    return maxIndex + 1;
  }

  /// Build message for adjacent destinations.
  String _buildAdjacentMessage(
    String existingDest,
    String newDest,
    DestinationDistance distance,
  ) {
    return '$newDest cách $existingDest ${distance.formattedDistance} '
        '(~${distance.formattedTravelTime} di chuyển). '
        'Bạn có thể ghé cả hai trong cùng ngày.';
  }

  /// Build message for different destinations.
  String _buildDifferentMessage(
    String existingDest,
    String newDest,
    DestinationDistance distance,
  ) {
    return '$newDest cách $existingDest ${distance.formattedDistance} '
        '(~${distance.formattedTravelTime} di chuyển). '
        'Cân nhắc chia thành các ngày khác nhau để thoải mái hơn.';
  }

  /// Build message for distant destinations.
  String _buildDistantMessage(
    String existingDest,
    String newDest,
    DestinationDistance distance,
  ) {
    return '⚠️ $newDest cách $existingDest ${distance.formattedDistance} '
        '(~${distance.formattedTravelTime}). '
        'Khó thực hiện trong cùng một ngày.';
  }
}
