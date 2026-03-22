import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../destination/domain/entities/destination.dart';
import '../../../destination/domain/entities/location.dart';
import '../../../destination/presentation/providers/destination_provider.dart';
import '../../../review/data/repositories/review_repository.dart';
import '../../../review/domain/entities/review.dart';
import '../../domain/services/ai_content_service.dart';

// ── AI Service Provider ──────────────────────────────────

/// Provider for the AI Content Service.
final aiContentServiceProvider = Provider<AiContentService>((ref) {
  return AiContentService(apiKey: AppConfig.geminiApiKey);
});

// ── Pending Content Providers ────────────────────────────

/// Fetches destinations with status 'draft_ai' for admin review.
final pendingDestinationsProvider = FutureProvider<List<Destination>>((
  ref,
) async {
  final repo = ref.watch(destinationRepositoryProvider);
  final all = await repo.getAllDestinations();
  return all.where((d) => d.status == 'draft_ai').toList();
});

/// Fetches locations with status 'draft_ai' for admin review.
final pendingLocationsProvider = FutureProvider<List<Location>>((ref) async {
  final repo = ref.watch(destinationRepositoryProvider);
  final all = await repo.getAllLocations();
  return all.where((l) => l.status == 'draft_ai').toList();
});

/// Fetches reviews with status 'draft_ai' for admin review.
final pendingReviewsProvider = FutureProvider<List<Review>>((ref) async {
  final repo = ref.watch(reviewRepositoryProvider);
  final all = await repo.getAllReviews();
  return all.where((r) => r.status == 'draft_ai').toList();
});

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
  }) async {
    state = state.copyWith(isGenerating: true, error: null);
    try {
      final service = ref.read(aiContentServiceProvider);
      final destRepo = ref.read(destinationRepositoryProvider);

      // Load existing locations for context
      List<Map<String, dynamic>>? locationContext;
      List<Location>? allLocs;
      if (destinationId != null) {
        allLocs = await destRepo.getLocationsByDestination(destinationId);
        locationContext = allLocs
            .where((l) => l.status == 'published')
            .map((l) => {
                  'id': l.id,
                  'name': l.name,
                  'category': l.category,
                  'tags': l.tags,
                  'rating': l.rating,
                  'address': l.address,
                })
            .toList();
      }

      final json = await service.generateReview(
        prompt: prompt,
        destinationId: destinationId,
        destinationName: destinationName,
        existingLocations: locationContext,
        articleStyle: articleStyle,
      );

      var review = Review.fromJson(json);

      // Auto-fill heroImage from first related location
      if (review.heroImage.isEmpty &&
          review.relatedLocationIds.isNotEmpty &&
          allLocs != null) {
        final firstLoc = allLocs.cast<Location?>().firstWhere(
              (l) => l!.id == review.relatedLocationIds.first,
              orElse: () => null,
            );
        if (firstLoc != null && firstLoc.image.isNotEmpty) {
          review = review.copyWith(heroImage: firstLoc.image);
        }
      }

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
    required String destinationId,
    required String destinationName,
    int count = 3,
  }) async {
    state = state.copyWith(isGenerating: true, error: null);
    try {
      final service = ref.read(aiContentServiceProvider);
      final destRepo = ref.read(destinationRepositoryProvider);

      // Load existing locations
      final allLocs =
          await destRepo.getLocationsByDestination(destinationId);
      final locationContext = allLocs
          .where((l) => l.status == 'published')
          .map((l) => {
                'id': l.id,
                'name': l.name,
                'category': l.category,
                'tags': l.tags,
                'rating': l.rating,
                'address': l.address,
              })
          .toList();

      final jsonList = await service.generateMultipleReviews(
        destinationName: destinationName,
        destinationId: destinationId,
        existingLocations: locationContext,
        count: count,
      );

      final repo = ref.read(reviewRepositoryProvider);
      for (final json in jsonList) {
        var review = Review.fromJson(json);

        // Auto-fill heroImage
        if (review.heroImage.isEmpty &&
            review.relatedLocationIds.isNotEmpty) {
          final firstLoc = allLocs.cast<Location?>().firstWhere(
                (l) => l!.id == review.relatedLocationIds.first,
                orElse: () => null,
              );
          if (firstLoc != null && firstLoc.image.isNotEmpty) {
            review = review.copyWith(heroImage: firstLoc.image);
          }
        }

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
