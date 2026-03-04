import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/itinerary_service.dart';
import '../../domain/models/itinerary_constraints.dart';
import '../../../destination/domain/entities/location.dart';
import '../../../destination/presentation/providers/location_provider.dart';
import '../../../trip/domain/entities/trip_day.dart';
import '../../../recommendation/domain/entities/user_profile.dart';
import '../../../recommendation/presentation/providers/recommendation_provider.dart';

/// Provider for ItineraryService (stateless singleton).
final itineraryServiceProvider = Provider<ItineraryService>((ref) {
  return const ItineraryService();
});

/// State class for itinerary generation.
class ItineraryGenerationState {
  final bool isGenerating;
  final List<TripDay>? generatedDays;
  final String? errorMessage;

  const ItineraryGenerationState({
    this.isGenerating = false,
    this.generatedDays,
    this.errorMessage,
  });

  ItineraryGenerationState copyWith({
    bool? isGenerating,
    List<TripDay>? generatedDays,
    String? errorMessage,
  }) {
    return ItineraryGenerationState(
      isGenerating: isGenerating ?? this.isGenerating,
      generatedDays: generatedDays ?? this.generatedDays,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier managing itinerary generation lifecycle.
class ItineraryGenerationNotifier extends Notifier<ItineraryGenerationState> {
  @override
  ItineraryGenerationState build() => const ItineraryGenerationState();

  /// Generate a smart itinerary for a destination.
  Future<void> generate({
    required String destinationId,
    required int numberOfDays,
    TravelPace? pace,
  }) async {
    state = state.copyWith(isGenerating: true, errorMessage: null);

    try {
      // 1. Load all locations for destination
      final locations = await ref.read(
        locationsForDestinationProvider(destinationId).future,
      );

      // Filter to locations with coordinates
      final validLocations = locations.where((l) => l.hasCoordinates).toList();

      if (validLocations.isEmpty) {
        state = state.copyWith(
          isGenerating: false,
          errorMessage: 'Không có địa điểm nào có tọa độ GPS',
        );
        return;
      }

      // 2. Get user pace preference from profile
      final resolvedPace = pace ?? await _getUserPace();

      // 3. Build constraints
      final constraints = ItineraryConstraints(
        numberOfDays: numberOfDays,
        pace: resolvedPace,
      );

      // 4. Generate itinerary
      final service = ref.read(itineraryServiceProvider);
      final generatedDays = service.generate(
        candidates: validLocations,
        constraints: constraints,
      );

      // 5. Convert to TripDays
      final tripDays = generatedDays.map((d) => d.toTripDay()).toList();

      state = state.copyWith(isGenerating: false, generatedDays: tripDays);
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        errorMessage: 'Lỗi khi tạo lịch trình: $e',
      );
    }
  }

  Future<TravelPace> _getUserPace() async {
    final profile = await ref.read(userProfileProvider.future);
    return profile?.travelPace ?? TravelPace.normal;
  }

  /// Clear the generated itinerary.
  void clear() {
    state = const ItineraryGenerationState();
  }
}

/// Provider for itinerary generation state.
final itineraryGenerationProvider =
    NotifierProvider<ItineraryGenerationNotifier, ItineraryGenerationState>(
      ItineraryGenerationNotifier.new,
    );
