import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/trip_repository.dart';
import '../../domain/entities/trip.dart';
import '../../domain/services/trip_creation_service.dart';
import 'pending_trip_provider.dart';
import '../../../recommendation/presentation/providers/recommendation_provider.dart';
import '../../../recommendation/domain/entities/user_interaction_event.dart';

/// State for trip save operations.
sealed class TripSaveState {
  const TripSaveState();
}

/// Initial state - no save operation in progress.
class TripSaveInitial extends TripSaveState {
  const TripSaveInitial();
}

/// Save operation in progress.
class TripSaveLoading extends TripSaveState {
  const TripSaveLoading();
}

/// Save operation completed successfully.
class TripSaveSuccess extends TripSaveState {
  final Trip trip;
  final bool isNewTrip;

  const TripSaveSuccess({required this.trip, required this.isNewTrip});
}

/// Save operation failed.
class TripSaveError extends TripSaveState {
  final String message;

  const TripSaveError(this.message);
}

/// Duplicate location detected - location already exists in trip.
class TripSaveDuplicate extends TripSaveState {
  final String locationName;
  final int dayNumber;
  final String timeSlotLabel;

  const TripSaveDuplicate({
    required this.locationName,
    required this.dayNumber,
    required this.timeSlotLabel,
  });

  String get message =>
      '$locationName đã có trong Ngày $dayNumber - $timeSlotLabel';
}

/// User needs to sign in before saving trip.
class TripSaveNeedsSignIn extends TripSaveState {
  const TripSaveNeedsSignIn();
}

/// Notifier for trip save operations.
///
/// Handles creating new trips or adding to existing trips
/// from pending activities.
class TripSaveNotifier extends Notifier<TripSaveState> {
  @override
  TripSaveState build() => const TripSaveInitial();

  /// Save current pending trip.
  ///
  /// Creates a new trip or adds to existing trip for the same destination.
  /// Set [forceSave] to true to bypass the duplicate location check.
  /// Returns true if save was successful, false otherwise.
  Future<bool> saveCurrentTrip({
    required String destinationId,
    required String destinationName,
    bool forceSave = false,
  }) async {
    state = const TripSaveLoading();
    debugPrint('🔵 [TripSave] Starting save: $destinationName');

    try {
      // Get current user directly from Firebase Auth (not cached provider)
      // This ensures we have the latest auth state after sign-in
      final firebaseUser = FirebaseAuth.instance.currentUser;

      debugPrint(
        '🔵 [TripSave] User: ${firebaseUser?.uid ?? 'null'}, isAnonymous: ${firebaseUser?.isAnonymous}',
      );

      if (firebaseUser == null) {
        state = const TripSaveError('Vui lòng đăng nhập để lưu chuyến đi');
        debugPrint('🔴 [TripSave] Error: User is null');
        return false;
      }

      // Check if still anonymous
      if (firebaseUser.isAnonymous) {
        state = const TripSaveNeedsSignIn();
        debugPrint('🔵 [TripSave] User is anonymous, needs sign-in');
        return false;
      }

      final userId = firebaseUser.uid;
      final pendingState = ref.read(pendingTripProvider);

      debugPrint(
        '🔵 [TripSave] Pending activities: ${pendingState.activities.length}',
      );

      if (pendingState.isEmpty) {
        state = const TripSaveError('Không có hoạt động nào để lưu');
        debugPrint('🔴 [TripSave] Error: No pending activities');
        return false;
      }

      final repository = ref.read(tripRepositoryProvider);

      // Check for existing trip for this destination
      debugPrint('🔵 [TripSave] Checking for existing trip...');
      final existingTrip = await repository.getTripByDestination(
        userId,
        destinationId,
      );

      Trip savedTrip;
      bool isNewTrip;

      if (existingTrip != null) {
        // Check for duplicate location before adding (skip if forceSave)
        debugPrint('🔵 [TripSave] Found existing trip: ${existingTrip.id}');

        if (!forceSave) {
          // Get the first pending activity to check for duplicates
          final firstPendingActivity = pendingState.activities.firstOrNull;
          if (firstPendingActivity != null) {
            final existingActivity = existingTrip.findActivityByLocationId(
              firstPendingActivity.locationId,
            );

            if (existingActivity != null) {
              // Location already exists in trip — let UI ask for confirmation
              debugPrint(
                '⚠️ [TripSave] Duplicate found: ${existingActivity.activity.locationName} at Day ${existingActivity.dayNumber}',
              );
              state = TripSaveDuplicate(
                locationName: existingActivity.activity.locationName,
                dayNumber: existingActivity.dayNumber,
                timeSlotLabel: existingActivity.activity.timeSlot,
              );
              return false;
            }
          }
        }

        // No duplicate, proceed with adding
        final updatedTrip = existingTrip.addFromPendingState(pendingState);
        debugPrint('🔵 [TripSave] Calling updateTrip...');
        await repository.updateTrip(updatedTrip);
        debugPrint('✅ [TripSave] Existing trip updated!');
        savedTrip = updatedTrip;
        isNewTrip = false;
      } else {
        // Create new trip
        debugPrint('🔵 [TripSave] Creating new trip...');
        final newTrip = tripCreationService.createTripFromPendingState(
          userId: userId,
          pendingState: pendingState,
          destinationId: destinationId,
          destinationName: destinationName,
        );

        if (newTrip == null) {
          state = const TripSaveError('Không thể tạo chuyến đi');
          debugPrint('🔴 [TripSave] Error: Failed to create trip');
          return false;
        }

        debugPrint('🔵 [TripSave] Saving to Firestore: ${newTrip.id}');
        await repository.createTrip(newTrip);
        savedTrip = newTrip;
        isNewTrip = true;
        debugPrint('✅ [TripSave] Trip saved successfully!');
      }

      // Log addToTrip events for recommendation engine (non-blocking)
      for (final activity in pendingState.activities) {
        logUserEventFromProvider(
          ref,
          locationId: activity.locationId,
          destinationId: destinationId,
          type: InteractionType.addToTrip,
        );
      }

      // Clear pending state after successful save
      ref.read(pendingTripProvider.notifier).clear();

      state = TripSaveSuccess(trip: savedTrip, isNewTrip: isNewTrip);
      return true;
    } catch (e, stackTrace) {
      debugPrint('🔴 [TripSave] Exception: $e');
      debugPrint('🔴 [TripSave] StackTrace: $stackTrace');
      state = TripSaveError('Lỗi khi lưu chuyến đi: ${e.toString()}');
      return false;
    }
  }

  /// Reset to initial state.
  void reset() {
    state = const TripSaveInitial();
  }
}

/// Provider for trip save operations.
final tripSaveProvider = NotifierProvider<TripSaveNotifier, TripSaveState>(
  TripSaveNotifier.new,
);

/// Stream provider for Firebase auth state changes.
final _firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provider for checking if user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(_firebaseAuthStateProvider);
  return authState.hasValue &&
      authState.value != null &&
      !authState.value!.isAnonymous;
});

/// Provider for current user ID.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(_firebaseAuthStateProvider);
  return authState.value?.uid;
});

/// Provider that auto-saves pending trips when user signs in.
///
/// This provider should be watched at the app level to enable auto-save.
/// When a user signs in from anywhere (Profile, Sign-in prompt, etc.),
/// any pending trips will be automatically saved.
final autoSavePendingTripsProvider = Provider<void>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final pendingState = ref.watch(pendingTripProvider);

  // Check if user is authenticated and has pending trips
  if (isAuthenticated && pendingState.isNotEmpty) {
    final destinationId = pendingState.destinationId;
    final destinationName = pendingState.destinationName;

    if (destinationId != null && destinationName != null) {
      debugPrint(
        '🔵 [AutoSave] User signed in with pending trips, auto-saving...',
      );

      // Trigger save after microtask to avoid issues with provider rebuild
      Future.microtask(() {
        ref
            .read(tripSaveProvider.notifier)
            .saveCurrentTrip(
              destinationId: destinationId,
              destinationName: destinationName,
            );
      });
    }
  }
});
