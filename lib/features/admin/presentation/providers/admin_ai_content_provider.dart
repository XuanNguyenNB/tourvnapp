import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/ai_backend_service.dart';
import '../../../destination/domain/entities/destination.dart';
import '../../../destination/domain/entities/location.dart';
import '../../../destination/presentation/providers/destination_provider.dart';
import '../../../review/data/repositories/review_repository.dart';
import '../../../review/domain/entities/review.dart';
import '../../domain/services/ai_content_service.dart';

// ── AI Service Provider ──────────────────────────────────

/// Provider for the AI Content Service.
final aiContentServiceProvider = Provider<AiContentService>((ref) {
  return AiContentService(backendService: ref.watch(aiBackendServiceProvider));
});

// ── Pending Content Providers ────────────────────────────

/// Fetches destinations with status 'draft_ai' for admin review.
final pendingDestinationsProvider = FutureProvider<List<Destination>>((
  ref,
) async {
  final repo = ref.watch(destinationRepositoryProvider);
  return repo.getDestinationsByStatus('draft_ai');
});

/// Fetches locations with status 'draft_ai' for admin review.
final pendingLocationsProvider = FutureProvider<List<Location>>((ref) async {
  final repo = ref.watch(destinationRepositoryProvider);
  return repo.getLocationsByStatus('draft_ai');
});

/// Fetches reviews with status 'draft_ai' for admin review.
final pendingReviewsProvider = FutureProvider<List<Review>>((ref) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getReviewsByStatus('draft_ai');
});

const _reviewContextStatuses = {'published', 'draft_ai'};

Iterable<Location> _orderedUniqueLocations(
  List<Location> primary,
  List<Location> secondary,
) sync* {
  final seenIds = <String>{};
  for (final location in [...primary, ...secondary]) {
    if (seenIds.add(location.id)) {
      yield location;
    }
  }
}

List<Location> _selectReviewContextLocations(
  List<Location> locations, {
  Set<String> focusLocationIds = const {},
}) {
  final eligible = locations
      .where((location) => _reviewContextStatuses.contains(location.status))
      .toList();

  if (focusLocationIds.isEmpty) {
    return eligible;
  }

  final focused = eligible
      .where((location) => focusLocationIds.contains(location.id))
      .toList();

  return focused.isNotEmpty ? focused : eligible;
}

List<Map<String, dynamic>> _buildReviewLocationContext(
  List<Location> locations,
) {
  return locations
      .map(
        (location) => {
          'id': location.id,
          'name': location.name,
          'category': location.category,
          'tags': location.tags,
          'rating': location.rating,
          'address': location.address,
          'description': location.description,
        },
      )
      .toList();
}

Review _applyHeroFallback(
  Review review,
  List<Location> prioritizedLocations,
  List<Location> allLocations,
) {
  if (review.heroImage.isNotEmpty) {
    return review;
  }

  final relatedIds = review.relatedLocationIds.toSet();

  for (final location in _orderedUniqueLocations(
    prioritizedLocations,
    allLocations,
  )) {
    if (relatedIds.contains(location.id) && location.image.isNotEmpty) {
      return review.copyWith(heroImage: location.image);
    }
  }

  for (final location in _orderedUniqueLocations(
    prioritizedLocations,
    allLocations,
  )) {
    if (location.image.isNotEmpty) {
      return review.copyWith(heroImage: location.image);
    }
  }

  return review;
}

// ── AI Content Notifier ──────────────────────────────────

/// State for AI generation operations.
class AiContentState {
  final bool isGenerating;
  final String? error;
  final String? lastGeneratedType; // 'destination', 'location', 'review'
  final int? generatedCount;

  const AiContentState({
    this.isGenerating = false,
    this.error,
    this.lastGeneratedType,
    this.generatedCount,
  });

  AiContentState copyWith({
    bool? isGenerating,
    String? error,
    String? lastGeneratedType,
    int? generatedCount,
  }) {
    return AiContentState(
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      lastGeneratedType: lastGeneratedType ?? this.lastGeneratedType,
      generatedCount: generatedCount ?? this.generatedCount,
    );
  }
}

class AiContentNotifier extends Notifier<AiContentState> {
  @override
  AiContentState build() => const AiContentState();

  /// Generate a destination and save as draft.
  Future<void> generateDestination(String prompt) async {
    state = state.copyWith(isGenerating: true, error: null);
    try {
      final service = ref.read(aiContentServiceProvider);
      final json = await service.generateDestination(prompt);
      final destination = Destination.fromJson(json);

      final repo = ref.read(destinationRepositoryProvider);
      await repo.createDestination(destination);

      state = state.copyWith(
        isGenerating: false,
        lastGeneratedType: 'destination',
        generatedCount: 1,
      );

      // Refresh pending list
      ref.invalidate(pendingDestinationsProvider);
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }

  /// Generate locations for a destination and save as drafts.
  Future<void> generateLocations({
    required String destinationId,
    required String destinationName,
    required String prompt,
    int count = 5,
  }) async {
    state = state.copyWith(isGenerating: true, error: null);
    try {
      final service = ref.read(aiContentServiceProvider);
      final jsonList = await service.generateLocations(
        destinationId: destinationId,
        destinationName: destinationName,
        prompt: prompt,
        count: count,
      );

      final repo = ref.read(destinationRepositoryProvider);
      for (final json in jsonList) {
        final location = Location.fromJson(json);
        await repo.createLocation(location);
      }

      state = state.copyWith(
        isGenerating: false,
        lastGeneratedType: 'location',
        generatedCount: jsonList.length,
      );

      ref.invalidate(pendingLocationsProvider);
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }

  /// Generate a review/article with context-aware location data.
  ///
  /// Loads existing locations from Firestore for the selected destination,
  /// passes them to the AI so it writes about real places. After generation,
  /// auto-fills heroImage from the first related location.
  Future<void> generateReview({
    required String prompt,
    String? destinationId,
    String? destinationName,
    String articleStyle = 'review',
    Set<String> focusLocationIds = const {},
  }) async {
    state = state.copyWith(isGenerating: true, error: null);
    try {
      final service = ref.read(aiContentServiceProvider);
      final destRepo = ref.read(destinationRepositoryProvider);

      // Load existing locations for context
      List<Map<String, dynamic>>? locationContext;
      List<Location> allLocs = const [];
      List<Location> contextLocations = const [];
      if (destinationId != null) {
        allLocs = await destRepo.getLocationsByDestination(destinationId);
        contextLocations = _selectReviewContextLocations(
          allLocs,
          focusLocationIds: focusLocationIds,
        );
        locationContext = _buildReviewLocationContext(contextLocations);
      }

      final json = await service.generateReview(
        prompt: prompt,
        destinationId: destinationId,
        destinationName: destinationName,
        existingLocations: locationContext,
        articleStyle: articleStyle,
      );

      var review = Review.fromJson(json);

      if (destinationId != null && review.destinationId == null) {
        review = review.copyWith(
          destinationId: destinationId,
          destinationName: destinationName,
        );
      }

      review = _applyHeroFallback(review, contextLocations, allLocs);

      final repo = ref.read(reviewRepositoryProvider);
      await repo.createReview(review);

      state = state.copyWith(
        isGenerating: false,
        lastGeneratedType: 'review',
        generatedCount: 1,
      );

      ref.invalidate(pendingReviewsProvider);
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }

  /// Batch generate multiple reviews for a destination.
  ///
  /// Each article will have a different style, focus, and location set.
  Future<void> generateMultipleReviews({
    required String prompt,
    required String destinationId,
    required String destinationName,
    String articleStyle = 'review',
    Set<String> focusLocationIds = const {},
    int count = 3,
  }) async {
    state = state.copyWith(isGenerating: true, error: null);
    try {
      final service = ref.read(aiContentServiceProvider);
      final destRepo = ref.read(destinationRepositoryProvider);

      // Load existing locations
      final allLocs = await destRepo.getLocationsByDestination(destinationId);
      final contextLocations = _selectReviewContextLocations(
        allLocs,
        focusLocationIds: focusLocationIds,
      );
      final locationContext = _buildReviewLocationContext(contextLocations);

      final jsonList = await service.generateMultipleReviews(
        prompt: prompt,
        destinationName: destinationName,
        destinationId: destinationId,
        existingLocations: locationContext,
        articleStyle: articleStyle,
        count: count,
      );

      final repo = ref.read(reviewRepositoryProvider);
      for (final json in jsonList) {
        var review = Review.fromJson(json);
        if (review.destinationId == null) {
          review = review.copyWith(
            destinationId: destinationId,
            destinationName: destinationName,
          );
        }
        review = _applyHeroFallback(review, contextLocations, allLocs);
        await repo.createReview(review);
      }

      state = state.copyWith(
        isGenerating: false,
        lastGeneratedType: 'review',
        generatedCount: jsonList.length,
      );

      ref.invalidate(pendingReviewsProvider);
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }

  /// Approve a pending item (change status to 'published').
  Future<void> approveDestination(Destination dest) async {
    final repo = ref.read(destinationRepositoryProvider);
    await repo.updateDestination(dest.copyWith(status: 'published'));
    ref.invalidate(pendingDestinationsProvider);
  }

  Future<void> approveLocation(Location loc) async {
    final repo = ref.read(destinationRepositoryProvider);
    await repo.updateLocation(loc.copyWith(status: 'published'));
    ref.invalidate(pendingLocationsProvider);
  }

  Future<void> approveReview(Review review) async {
    final repo = ref.read(reviewRepositoryProvider);
    await repo.updateReview(review.copyWith(status: 'published'));
    ref.invalidate(pendingReviewsProvider);
  }

  /// Reject (delete) a pending item.
  Future<void> rejectDestination(String id) async {
    final repo = ref.read(destinationRepositoryProvider);
    await repo.deleteDestination(id);
    ref.invalidate(pendingDestinationsProvider);
  }

  Future<void> rejectLocation(String id) async {
    final repo = ref.read(destinationRepositoryProvider);
    await repo.deleteLocation(id);
    ref.invalidate(pendingLocationsProvider);
  }

  Future<void> rejectReview(String id) async {
    final repo = ref.read(reviewRepositoryProvider);
    await repo.deleteReview(id);
    ref.invalidate(pendingReviewsProvider);
  }
}

final aiContentNotifierProvider =
    NotifierProvider<AiContentNotifier, AiContentState>(() {
      return AiContentNotifier();
    });
