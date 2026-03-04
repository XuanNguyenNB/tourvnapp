import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/trip_repository.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/trip_day.dart';
import 'pending_trip_provider.dart';

/// Result of a save trip operation.
enum SaveTripResult {
  /// Trip was saved successfully.
  success,

  /// User needs to sign in before saving (anonymous user).
  needsSignIn,

  /// Save operation failed with an error.
  error,

  /// No trip to save (empty state).
  noTrip,
}

/// State for Visual Planner screen.
///
/// Manages:
/// - Current trip being viewed
/// - Selected day for filtering activities
/// - Loading and error states
/// - Save operation state
class VisualPlannerState {
  /// The current trip being displayed.
  final Trip? currentTrip;

  /// Currently selected day number (1-based).
  final int selectedDayNumber;

  /// Whether the trip is loading.
  final bool isLoading;

  /// Whether a save operation is in progress.
  final bool isSaving;

  /// Error message if any.
  final String? error;

  /// Whether this is a pending trip (not yet saved).
  final bool isPending;

  const VisualPlannerState({
    this.currentTrip,
    this.selectedDayNumber = 1,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.isPending = false,
  });

  /// Get the current day (TripDay) based on selectedDayNumber.
  TripDay? get currentDay {
    return currentTrip?.getDay(selectedDayNumber);
  }

  /// Get activities for the currently selected day, sorted by time slot.
  List<Activity> get activitiesForCurrentDay {
    if (currentTrip == null) return [];

    final day = currentTrip!.days.firstWhere(
      (d) => d.dayNumber == selectedDayNumber,
      orElse: () => TripDay(dayNumber: selectedDayNumber, activities: const []),
    );

    // Sort by time slot order
    final sorted = List<Activity>.from(day.activities)
      ..sort((a, b) {
        final t = _timeSlotOrder(
          a.timeSlot,
        ).compareTo(_timeSlotOrder(b.timeSlot));
        if (t != 0) return t;
        return a.sortOrder.compareTo(b.sortOrder);
      });

    return sorted;
  }

  /// Get set of day numbers (1-based) that have multi-destination conflicts.
  Set<int> getConflictDays() {
    if (currentTrip == null) return {};

    final conflictDays = <int>{};
    for (final day in currentTrip!.days) {
      if (day.hasMultipleDestinations) {
        conflictDays.add(day.dayNumber);
      }
    }
    return conflictDays;
  }

  /// Convert time slot string to sort order.
  int _timeSlotOrder(String slot) {
    switch (slot.toLowerCase()) {
      case 'morning':
        return 0;
      case 'noon':
        return 1;
      case 'afternoon':
        return 2;
      case 'evening':
        return 3;
      default:
        return 4;
    }
  }

  /// Create a copy with optional field overrides.
  VisualPlannerState copyWith({
    Trip? currentTrip,
    int? selectedDayNumber,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool? isPending,
    bool clearError = false,
    bool clearTrip = false,
  }) {
    return VisualPlannerState(
      currentTrip: clearTrip ? null : (currentTrip ?? this.currentTrip),
      selectedDayNumber: selectedDayNumber ?? this.selectedDayNumber,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      isPending: isPending ?? this.isPending,
    );
  }

  @override
  String toString() =>
      'VisualPlannerState(trip: ${currentTrip?.id}, day: $selectedDayNumber)';
}

/// Notifier for Visual Planner screen state.
///
/// Handles:
/// - Loading trips from Firestore or pending state
/// - Day selection
/// - Save operations
class VisualPlannerNotifier extends Notifier<VisualPlannerState> {
  @override
  VisualPlannerState build() {
    // Return initial loading state - screen will call loadTrip() or loadFromPending()
    // Do NOT auto-load here, as it causes issues with saved trips
    return const VisualPlannerState(isLoading: true);
  }

  /// Load trip from pending activities.
  /// Called by VisualPlannerScreen.fromPending()
  void loadFromPending() {
    _loadFromPendingInternal();
  }

  void _loadFromPendingInternal() {
    try {
      final pendingState = ref.read(pendingTripProvider);

      if (pendingState.isEmpty) {
        state = const VisualPlannerState(
          isLoading: false,
          isPending: true,
          currentTrip: null,
        );
        return;
      }

      // Create a temporary Trip from pending state for display
      final tempTrip = _createTripFromPending(pendingState);

      state = VisualPlannerState(
        currentTrip: tempTrip,
        isLoading: false,
        isPending: true,
      );
    } catch (e) {
      debugPrint('Error loading pending state: $e');
      state = VisualPlannerState(
        isLoading: false,
        error: e.toString(),
        isPending: true,
      );
    }
  }

  /// Create a temporary Trip from PendingTripState for display.
  Trip _createTripFromPending(PendingTripState pendingState) {
    final days = <TripDay>[];

    for (int i = 0; i < pendingState.totalDays; i++) {
      final dayActivities = pendingState.activitiesByDay[i] ?? [];
      final activities = dayActivities
          .asMap()
          .entries
          .map((e) => Activity.fromPendingActivity(e.value, e.key))
          .toList();

      days.add(TripDay(dayNumber: i + 1, activities: activities));
    }

    final destName = pendingState.destinationName ?? 'Đích đến mới';
    final tripName = pendingState.tripName?.isNotEmpty == true
        ? pendingState.tripName!
        : 'Khám phá $destName';

    return Trip(
      id: 'pending',
      userId: 'pending',
      name: tripName,
      destinationId: pendingState.destinationId ?? '',
      destinationName: destName,
      days: days,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Load trip by ID from Firestore.
  Future<void> loadTrip(String tripId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final userId = ref.read(currentUserProvider)?.uid;
      if (userId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Vui lòng đăng nhập để xem chuyến đi',
        );
        return;
      }

      final trip = await ref
          .read(tripRepositoryProvider)
          .getTrip(userId, tripId);

      state = state.copyWith(
        currentTrip: trip,
        isLoading: false,
        isPending: false,
      );
    } catch (e) {
      debugPrint('Error loading trip: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể tải chuyến đi: ${e.toString()}',
      );
    }
  }

  /// Change selected day.
  void selectDay(int dayNumber) {
    if (dayNumber == state.selectedDayNumber) return;

    state = state.copyWith(selectedDayNumber: dayNumber);
  }

  /// Save the current trip to Firestore.
  ///
  /// Returns [SaveTripResult] indicating the outcome:
  /// - [SaveTripResult.success]: Trip saved successfully
  /// - [SaveTripResult.needsSignIn]: User is anonymous, needs sign-in
  /// - [SaveTripResult.error]: Save operation failed
  /// - [SaveTripResult.noTrip]: No trip data to save
  Future<SaveTripResult> saveTrip() async {
    if (state.currentTrip == null) return SaveTripResult.noTrip;

    // Check if user is anonymous BEFORE setting loading state
    // This provides immediate feedback without UI flicker
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null || firebaseUser.isAnonymous) {
      debugPrint('🔵 [SaveTrip] User is anonymous, needs sign-in');
      return SaveTripResult.needsSignIn;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final userId = firebaseUser.uid;
      final pendingState = ref.read(pendingTripProvider);
      final tripRepo = ref.read(tripRepositoryProvider);

      // Create a proper Trip from pending state
      final trip = Trip.fromPendingState(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        pendingState: pendingState,
        destinationId: pendingState.destinationId ?? '',
        destinationName: pendingState.destinationName ?? 'Trip',
      );

      debugPrint('🔵 [SaveTrip] Saving trip: ${trip.id}');

      // Save to Firestore
      await tripRepo.createTrip(trip);

      debugPrint('✅ [SaveTrip] Trip saved successfully!');

      // Clear pending state AFTER successful save
      ref.read(pendingTripProvider.notifier).clear();

      // Update local state
      state = state.copyWith(
        currentTrip: trip,
        isSaving: false,
        isPending: false,
      );

      return SaveTripResult.success;
    } catch (e) {
      debugPrint('🔴 [SaveTrip] Error: $e');
      state = state.copyWith(
        isSaving: false,
        error: 'Không thể lưu chuyến đi: ${e.toString()}',
      );
      return SaveTripResult.error;
    }
  }

  /// Update an existing saved trip in Firestore.
  ///
  /// Used when user makes changes to a saved trip (reorder, delete activities).
  /// Returns [SaveTripResult] indicating the outcome.
  Future<SaveTripResult> updateTrip() async {
    final trip = state.currentTrip;
    if (trip == null || state.isPending) {
      // Cannot update a pending trip - use saveTrip() instead
      return SaveTripResult.noTrip;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final tripRepo = ref.read(tripRepositoryProvider);

      // Update with new timestamp
      final updatedTrip = trip.copyWith(updatedAt: DateTime.now());

      debugPrint('🔵 [UpdateTrip] Updating trip: ${updatedTrip.id}');

      // Update in Firestore
      await tripRepo.updateTrip(updatedTrip);

      debugPrint('✅ [UpdateTrip] Trip updated successfully!');

      // Update local state
      state = state.copyWith(currentTrip: updatedTrip, isSaving: false);

      return SaveTripResult.success;
    } catch (e) {
      debugPrint('🔴 [UpdateTrip] Error: $e');
      state = state.copyWith(
        isSaving: false,
        error: 'Không thể cập nhật chuyến đi: ${e.toString()}',
      );
      return SaveTripResult.error;
    }
  }

  /// Refresh trip data from source (pending or Firestore).
  Future<void> refresh() async {
    if (state.isPending) {
      _loadFromPendingInternal();
    } else if (state.currentTrip != null) {
      await loadTrip(state.currentTrip!.id);
    }
  }

  /// Apply optimized days to the current saved trip and persist.
  Future<void> applyOptimizedDays(List<TripDay> optimizedDays) async {
    final trip = state.currentTrip;
    if (trip == null) return;

    final optimizedTrip = trip.copyWith(
      days: optimizedDays,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(currentTrip: optimizedTrip);
    await updateTrip();
  }
}

/// Provider for Visual Planner screen state.
///
/// Usage:
/// ```dart
/// // Read state
/// final state = ref.watch(visualPlannerProvider);
///
/// // Select day
/// ref.read(visualPlannerProvider.notifier).selectDay(2);
///
/// // Load specific trip
/// ref.read(visualPlannerProvider.notifier).loadTrip(tripId);
/// ```
final visualPlannerProvider =
    NotifierProvider<VisualPlannerNotifier, VisualPlannerState>(
      VisualPlannerNotifier.new,
    );
