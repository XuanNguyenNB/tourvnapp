import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/trip.dart';
import '../../domain/entities/trip_day.dart';
import '../../data/repositories/trip_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// State object for the Trip Creation flow (Story 9-2).
class TripCreationState {
  final String? selectedDestinationId;
  final String? selectedDestinationName;
  final int dayCount;
  final String tripName;
  final bool isCreating;
  final String? error;

  /// Start date of the trip (optional but recommended).
  final DateTime? startDate;

  /// End date of the trip (computed from startDate + dayCount - 1).
  final DateTime? endDate;

  /// Whether the user has manually edited the trip name.
  final bool userEditedName;

  const TripCreationState({
    this.selectedDestinationId,
    this.selectedDestinationName,
    this.dayCount = 3,
    this.tripName = '',
    this.isCreating = false,
    this.error,
    this.startDate,
    this.endDate,
    this.userEditedName = false,
  });

  bool get isValid =>
      selectedDestinationId != null && tripName.trim().isNotEmpty;

  /// Whether dates have been picked by user.
  bool get hasDates => startDate != null && endDate != null;

  TripCreationState copyWith({
    String? selectedDestinationId,
    String? selectedDestinationName,
    int? dayCount,
    String? tripName,
    bool? isCreating,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
    bool? userEditedName,
    bool clearDates = false,
  }) {
    return TripCreationState(
      selectedDestinationId:
          selectedDestinationId ?? this.selectedDestinationId,
      selectedDestinationName:
          selectedDestinationName ?? this.selectedDestinationName,
      dayCount: dayCount ?? this.dayCount,
      tripName: tripName ?? this.tripName,
      isCreating: isCreating ?? this.isCreating,
      error: error, // Can reset error
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      userEditedName: userEditedName ?? this.userEditedName,
    );
  }
}

/// Auto-disposed provider to manage local state of the Create Trip screen.
/// State is reset when screen is popped.
class TripCreationNotifier extends Notifier<TripCreationState> {
  TripCreationNotifier() : super();

  @override
  TripCreationState build() => const TripCreationState();

  void selectDestination(String id, String name) {
    // Only auto-fill trip name if user hasn't manually edited it
    final autoName = 'Khám phá $name';
    final shouldAutoFill =
        !state.userEditedName || state.tripName.trim().isEmpty;

    state = state.copyWith(
      selectedDestinationId: id,
      selectedDestinationName: name,
      tripName: shouldAutoFill ? autoName : state.tripName,
      userEditedName: shouldAutoFill ? false : state.userEditedName,
    );
  }

  void deselectDestination() {
    state = state.copyWith(
      selectedDestinationId: null,
      selectedDestinationName: null,
      tripName: '',
      userEditedName: false,
    );
  }

  /// Set date range and auto-compute dayCount from it.
  void setDateRange(DateTime start, DateTime end) {
    final days = end.difference(start).inDays + 1;
    state = state.copyWith(startDate: start, endDate: end, dayCount: days);
  }

  /// Clear date range (revert to manual dayCount).
  void clearDates() {
    state = state.copyWith(clearDates: true);
  }

  void setDayCount(int count) {
    state = state.copyWith(dayCount: count);
  }

  void setTripName(String name) {
    // Detect if user is manually typing (different from auto-generated name)
    final autoName = state.selectedDestinationName != null
        ? 'Khám phá ${state.selectedDestinationName}'
        : '';
    final isManualEdit = name != autoName;

    state = state.copyWith(
      tripName: name,
      userEditedName: isManualEdit && name.trim().isNotEmpty,
    );
  }

  /// Initiates trip creation and persists to Firestore.
  /// Throws an exception or sets error state if something goes wrong.
  /// Returns the newly created Trip if successful.
  Future<Trip?> createTrip() async {
    if (!state.isValid) return null;

    state = state.copyWith(isCreating: true, error: null);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User must be logged in to create a trip');
      }

      final repo = ref.read(tripRepositoryProvider);
      final uuid = const Uuid().v4();
      final now = DateTime.now();

      // Create empty days
      final days = List.generate(
        state.dayCount,
        (index) => TripDay(dayNumber: index + 1, activities: const []),
      );

      final newTrip = Trip(
        id: uuid,
        userId: user.uid,
        name: state.tripName.trim(),
        destinationId: state.selectedDestinationId!,
        destinationName: state.selectedDestinationName!,
        days: days,
        createdAt: now,
        updatedAt: now,
      );

      final createdTrip = await repo.createTrip(newTrip);

      state = state.copyWith(isCreating: false);
      return createdTrip;
    } catch (e) {
      state = state.copyWith(isCreating: false, error: e.toString());
      return null;
    }
  }
}

final tripCreationProvider =
    NotifierProvider<TripCreationNotifier, TripCreationState>(
      TripCreationNotifier.new,
    );
