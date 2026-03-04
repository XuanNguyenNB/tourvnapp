import 'dart:math' as math;

import 'package:tour_vn/core/config/destination_distances.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';
import 'package:tour_vn/features/trip/domain/entities/activity.dart';
import 'package:tour_vn/features/trip/domain/entities/schedule_optimization_result.dart';
import 'package:tour_vn/features/trip/domain/entities/trip.dart';
import 'package:tour_vn/features/trip/domain/entities/trip_day.dart';

class _ActivityMeta {
  final Activity activity;
  final int originalDayIndex;
  final int originalOrder;

  const _ActivityMeta({
    required this.activity,
    required this.originalDayIndex,
    required this.originalOrder,
  });
}

class ScheduleOptimizationService {
  /// Version that uses simple coordinate map (safe for Isolate).
  ScheduleOptimizationResult optimizeScheduleWithCoords(
    Trip trip,
    Map<String, ({double lat, double lng})> coords,
  ) {
    return _doOptimize(trip, coords);
  }

  /// Legacy version that uses Location objects (for tests / direct calls).
  ScheduleOptimizationResult optimizeSchedule(
    Trip trip, [
    Map<String, Location>? locationMap,
  ]) {
    // Convert Location map to simple coord map
    final coords = <String, ({double lat, double lng})>{};
    if (locationMap != null) {
      for (final entry in locationMap.entries) {
        final loc = entry.value;
        if (loc.latitude != null && loc.longitude != null) {
          coords[entry.key] = (lat: loc.latitude!, lng: loc.longitude!);
        }
      }
    }
    return _doOptimize(trip, coords.isEmpty ? null : coords);
  }

  /// Core optimization logic.
  ScheduleOptimizationResult _doOptimize(
    Trip trip,
    Map<String, ({double lat, double lng})>? coords,
  ) {
    final validActivities = <_ActivityMeta>[];

    for (int d = 0; d < trip.days.length; d++) {
      final day = trip.days[d];
      for (int a = 0; a < day.activities.length; a++) {
        final activity = day.activities[a];
        if (activity.destinationId != null) {
          validActivities.add(
            _ActivityMeta(
              activity: activity,
              originalDayIndex: d,
              originalOrder: a,
            ),
          );
        }
      }
    }

    final uniqueDests = validActivities
        .map((e) => e.activity.destinationId!)
        .toSet();

    final destOrder = _findOptimalDayOrder(uniqueDests, validActivities);

    final destIndex = <String, int>{};
    for (int i = 0; i < destOrder.length; i++) {
      destIndex[destOrder[i]] = i;
    }

    validActivities.sort((a, b) {
      final idxA = destIndex[a.activity.destinationId!] ?? 999;
      final idxB = destIndex[b.activity.destinationId!] ?? 999;
      if (idxA != idxB) return idxA.compareTo(idxB);
      if (a.originalDayIndex != b.originalDayIndex) {
        return a.originalDayIndex.compareTo(b.originalDayIndex);
      }
      return a.originalOrder.compareTo(b.originalOrder);
    });

    final optimizedDays = <TripDay>[];
    final changes = <OptimizationChange>[];
    int validIdx = 0;

    for (int d = 0; d < trip.days.length; d++) {
      final originalDay = trip.days[d];
      final newActivities = <Activity>[];

      for (int a = 0; a < originalDay.activities.length; a++) {
        final originalActivity = originalDay.activities[a];

        if (originalActivity.destinationId == null) {
          newActivities.add(originalActivity);
        } else {
          final assignedMeta = validActivities[validIdx++];
          newActivities.add(assignedMeta.activity);

          if (assignedMeta.originalDayIndex != d) {
            changes.add(
              OptimizationChange(
                fromDay: assignedMeta.originalDayIndex + 1,
                toDay: d + 1,
                activityName: assignedMeta.activity.locationName,
                reason:
                    'Grouped by destination (${assignedMeta.activity.destinationName})',
              ),
            );
          }
        }
      }

      // Group by timeSlot
      final groupedBySlot = <String, List<Activity>>{};
      for (final act in newActivities) {
        groupedBySlot.putIfAbsent(act.timeSlot, () => []).add(act);
      }

      final sortedSlots = groupedBySlot.keys.toList()
        ..sort(
          (a, b) => _getTimeSlotWeight(a).compareTo(_getTimeSlotWeight(b)),
        );

      final finalActivities = <Activity>[];
      for (final slot in sortedSlots) {
        var slotActivities = groupedBySlot[slot]!;
        if (slotActivities.length > 1 && coords != null) {
          slotActivities = _optimizeActivitiesOrderByCoords(
            slotActivities,
            coords,
          );
        }
        finalActivities.addAll(slotActivities);
      }

      // Check for intra-day reordering
      if (finalActivities.length == originalDay.activities.length) {
        for (int i = 0; i < finalActivities.length; i++) {
          final actA = originalDay.activities[i];
          final actB = finalActivities[i];
          if (actA.id != actB.id &&
              !changes.any((c) => c.activityName == actB.locationName)) {
            changes.add(
              OptimizationChange(
                fromDay: d + 1,
                toDay: d + 1,
                activityName: actB.locationName,
                reason: 'Được sắp xếp lại để tối ưu thời gian di chuyển',
              ),
            );
          }
        }
      }

      optimizedDays.add(originalDay.copyWith(activities: finalActivities));
    }

    final originalTotals = _calculateTravelTotals(trip.days);
    final optimizedTotals = _calculateTravelTotals(optimizedDays);

    if (changes.isEmpty) {
      return ScheduleOptimizationResult.noChanges(
        originalDays: trip.days,
        originalTravelTimeMin: originalTotals.time,
      );
    }

    return ScheduleOptimizationResult(
      optimizedDays: optimizedDays,
      totalTravelTimeSavedMin: (originalTotals.time - optimizedTotals.time)
          .clamp(0, 9999),
      totalDistanceSavedKm: (originalTotals.distance - optimizedTotals.distance)
          .clamp(0.0, 9999.0),
      changes: changes,
      originalTravelTimeMin: originalTotals.time,
      optimizedTravelTimeMin: optimizedTotals.time,
    );
  }

  List<String> _findOptimalDayOrder(
    Set<String> destinations,
    List<_ActivityMeta> validActivities,
  ) {
    if (destinations.isEmpty) return [];

    final destCounts = <String, int>{};
    for (final meta in validActivities) {
      destCounts[meta.activity.destinationId!] =
          (destCounts[meta.activity.destinationId!] ?? 0) + 1;
    }

    String startDest = destCounts.keys.first;
    int maxCount = -1;
    for (final entry in destCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        startDest = entry.key;
      }
    }

    final unvisited = Set<String>.from(destinations);
    final result = <String>[];

    String current = startDest;
    result.add(current);
    unvisited.remove(current);

    while (unvisited.isNotEmpty) {
      String? nextDest;
      double minDistance = double.infinity;

      for (final candidate in unvisited) {
        final dist = DestinationDistances.getDistance(current, candidate);
        final distVal = dist?.distanceKm ?? 9999.0;

        if (distVal < minDistance) {
          minDistance = distVal;
          nextDest = candidate;
        }
      }

      if (nextDest == null) {
        nextDest = unvisited.first;
      }

      result.add(nextDest);
      unvisited.remove(nextDest);
      current = nextDest;
    }

    return result;
  }

  ({int time, double distance}) _calculateTravelTotals(List<TripDay> days) {
    int totalMinutes = 0;
    double totalDistance = 0.0;

    for (int i = 0; i < days.length - 1; i++) {
      final currentDest = days[i].primaryDestinationId;
      final nextDest = days[i + 1].primaryDestinationId;
      if (currentDest != null && nextDest != null && currentDest != nextDest) {
        final distanceMap = DestinationDistances.getDistance(
          currentDest,
          nextDest,
        );
        if (distanceMap != null) {
          totalMinutes += distanceMap.travelTimeMin;
          totalDistance += distanceMap.distanceKm;
        }
      }
    }
    return (time: totalMinutes, distance: totalDistance);
  }

  static int getTimeSlotWeight(String slot) {
    switch (slot) {
      case 'morning':
        return 0;
      case 'noon':
        return 1;
      case 'afternoon':
        return 2;
      case 'evening':
        return 3;
      default:
        return 99;
    }
  }

  int _getTimeSlotWeight(String slot) => getTimeSlotWeight(slot);

  /// Optimize activity order using simple coordinate map.
  List<Activity> _optimizeActivitiesOrderByCoords(
    List<Activity> activities,
    Map<String, ({double lat, double lng})> coords,
  ) {
    if (activities.length <= 1) return activities;

    final unvisited = List<Activity>.from(activities)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final result = <Activity>[];
    var current = unvisited.removeAt(0);
    result.add(current);

    while (unvisited.isNotEmpty) {
      Activity? nextAct;
      double minDistance = double.infinity;

      final coordCurrent = coords[current.locationId];
      if (coordCurrent == null) {
        nextAct = unvisited.first;
      } else {
        for (final candidate in unvisited) {
          final coordCandidate = coords[candidate.locationId];
          if (coordCandidate == null) continue;

          final dist = _haversine(
            coordCurrent.lat,
            coordCurrent.lng,
            coordCandidate.lat,
            coordCandidate.lng,
          );

          if (dist < minDistance) {
            minDistance = dist;
            nextAct = candidate;
          }
        }
      }

      nextAct ??= unvisited.first;
      result.add(nextAct);
      unvisited.remove(nextAct);
      current = nextAct;
    }

    return result;
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }
}
