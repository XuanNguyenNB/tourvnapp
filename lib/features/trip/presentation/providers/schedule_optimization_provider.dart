import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/features/destination/presentation/providers/destination_provider.dart';
import 'package:tour_vn/features/trip/domain/entities/schedule_optimization_result.dart';
import 'package:tour_vn/features/trip/domain/entities/trip.dart';
import 'package:tour_vn/features/trip/domain/services/schedule_optimization_service.dart';

/// State of the schedule optimization process.
class ScheduleOptimizationState {
  final bool isLoading;
  final ScheduleOptimizationResult? result;
  final String? error;

  const ScheduleOptimizationState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  ScheduleOptimizationState copyWith({
    bool? isLoading,
    ScheduleOptimizationResult? result,
    String? error,
  }) {
    return ScheduleOptimizationState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleOptimizationState &&
        other.isLoading == isLoading &&
        other.result == result &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(isLoading, result, error);
}

/// Notifier that manages the schedule optimization state.
class ScheduleOptimizationNotifier extends Notifier<ScheduleOptimizationState> {
  @override
  ScheduleOptimizationState build() {
    return const ScheduleOptimizationState();
  }

  Future<void> optimizeTrip(Trip trip) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Gather all unique location IDs
      final locationIds = trip.days
          .expand((d) => d.activities)
          .map((a) => a.locationId)
          .toSet()
          .toList();

      debugPrint('🔵 [Optimize] Fetching ${locationIds.length} locations...');

      // 2. Fetch location data from Firestore
      final locations = await ref
          .read(destinationRepositoryProvider)
          .getLocationsByIds(locationIds);

      debugPrint('🔵 [Optimize] Got ${locations.length} locations');

      // 3. Extract coordinates into simple map
      final coords = <String, ({double lat, double lng})>{};
      for (final loc in locations) {
        if (loc.latitude != null && loc.longitude != null) {
          coords[loc.id] = (lat: loc.latitude!, lng: loc.longitude!);
        }
      }

      debugPrint(
        '🔵 [Optimize] Running optimization with ${coords.length} coords...',
      );

      // 4. Run optimization directly (fast enough for typical trip sizes)
      final service = ScheduleOptimizationService();
      final result = service.optimizeScheduleWithCoords(trip, coords);

      debugPrint('🔵 [Optimize] Done! hasChanges=${result.hasChanges}');

      state = ScheduleOptimizationState(isLoading: false, result: result);
    } catch (e, st) {
      debugPrint('🔴 [Optimize] Error: $e\n$st');
      state = ScheduleOptimizationState(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = const ScheduleOptimizationState();
  }
}

/// Provider for the schedule optimization notifier.
final scheduleOptimizationProvider =
    NotifierProvider<ScheduleOptimizationNotifier, ScheduleOptimizationState>(
      ScheduleOptimizationNotifier.new,
    );
