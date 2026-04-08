import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/ai_backend_service.dart';
import '../../../destination/domain/entities/destination.dart';
import '../../../destination/domain/entities/location.dart';
import '../../../destination/presentation/providers/destination_provider.dart';
import '../../../review/data/repositories/review_repository.dart';
import '../../../review/domain/entities/review.dart';
import '../../domain/services/ai_content_service.dart';
import 'admin_reference_data_provider.dart';
import 'admin_stats_provider.dart';

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

/// Fetches AI review ideas waiting for preview expansion.
final pendingDraftReviewsProvider = FutureProvider<List<Review>>((ref) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getReviewsByStatus('draft_ai');
});

/// Fetches AI review previews waiting for publication.
final pendingPreviewReviewsProvider = FutureProvider<List<Review>>((ref) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getReviewsByStatus('preview_ai');
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

bool _isValidHttpUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
}

void _invalidateReviewQueues(Ref ref) {
  ref.invalidate(pendingDraftReviewsProvider);
  ref.invalidate(pendingPreviewReviewsProvider);
}

// ── AI Content Notifier ──────────────────────────────────

enum DemoPackStep { idle, locations, reviews, completed }

/// State for AI generation operations.
class AiContentState {
  final bool isGenerating;
  final String? error;
  final String? lastGeneratedType; // 'destination', 'location', 'review'
  final int? generatedCount;
  final String? successMessage;
  final DemoPackStep demoPackStep;
  final Set<String> highlightedLocationIds;
  final Set<String> highlightedReviewIds;

  const AiContentState({
    this.isGenerating = false,
    this.error,
    this.lastGeneratedType,
    this.generatedCount,
    this.successMessage,
    this.demoPackStep = DemoPackStep.idle,
    this.highlightedLocationIds = const <String>{},
    this.highlightedReviewIds = const <String>{},
  });

  AiContentState copyWith({
    bool? isGenerating,
    String? error,
    String? lastGeneratedType,
    int? generatedCount,
    String? successMessage,
    DemoPackStep? demoPackStep,
    Set<String>? highlightedLocationIds,
    Set<String>? highlightedReviewIds,
    bool clearSuccessMessage = false,
    bool clearHighlights = false,
  }) {
    return AiContentState(
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      lastGeneratedType: lastGeneratedType ?? this.lastGeneratedType,
      generatedCount: generatedCount ?? this.generatedCount,
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
      demoPackStep: demoPackStep ?? this.demoPackStep,
      highlightedLocationIds: clearHighlights
          ? const <String>{}
          : (highlightedLocationIds ?? this.highlightedLocationIds),
      highlightedReviewIds: clearHighlights
          ? const <String>{}
          : (highlightedReviewIds ?? this.highlightedReviewIds),
    );
  }
}

class AiContentNotifier extends Notifier<AiContentState> {
  @override
  AiContentState build() => const AiContentState();

  /// Generate a destination and save as draft.
  Future<void> generateDestination(String prompt) async {
    state = state.copyWith(
      isGenerating: true,
      error: null,
      clearSuccessMessage: true,
    );
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
        successMessage: 'Đã tạo 1 điểm đến AI draft.',
      );

      ref.invalidate(pendingDestinationsProvider);
      ref.invalidate(adminDestinationLookupProvider);
      ref.invalidate(adminStatsProvider);
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
    state = state.copyWith(
      isGenerating: true,
      error: null,
      clearSuccessMessage: true,
    );
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
        successMessage: 'Đã tạo ${jsonList.length} địa điểm AI draft.',
      );

      ref.invalidate(pendingLocationsProvider);
      ref.invalidate(adminLocationLookupProvider);
      ref.invalidate(adminStatsProvider);
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
    state = state.copyWith(
      isGenerating: true,
      error: null,
      clearSuccessMessage: true,
    );
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
        successMessage: 'Đã tạo 1 bài viết AI draft.',
      );

      _invalidateReviewQueues(ref);
      ref.invalidate(adminStatsProvider);
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
    state = state.copyWith(
      isGenerating: true,
      error: null,
      clearSuccessMessage: true,
    );
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
        successMessage: 'Đã tạo ${jsonList.length} bài viết AI draft.',
      );

      _invalidateReviewQueues(ref);
      ref.invalidate(adminStatsProvider);
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }

  Future<void> generateDemoPack({
    required String destinationId,
    required String destinationName,
    String prompt = '',
  }) async {
    state = state.copyWith(
      isGenerating: true,
      error: null,
      demoPackStep: DemoPackStep.locations,
      clearSuccessMessage: true,
      clearHighlights: true,
    );

    try {
      final service = ref.read(aiContentServiceProvider);
      final destRepo = ref.read(destinationRepositoryProvider);

      final locationPrompt = prompt.trim().isNotEmpty
          ? '$prompt\n\nThêm 5 địa điểm nổi bật, đa dạng category, hợp demo bảo vệ đồ án.'
          : 'Tạo 5 địa điểm nổi bật, dễ demo web/mobile, có chất review và hình ảnh hợp lệ.';

      final locationJsonList = await service.generateLocations(
        destinationId: destinationId,
        destinationName: destinationName,
        prompt: locationPrompt,
        count: 5,
      );

      final createdLocationIds = <String>{};
      for (final json in locationJsonList) {
        final location = Location.fromJson(json);
        await destRepo.createLocation(location);
        createdLocationIds.add(location.id);
      }

      state = state.copyWith(
        demoPackStep: DemoPackStep.reviews,
        highlightedLocationIds: createdLocationIds,
      );

      final allLocs = await destRepo.getLocationsByDestination(destinationId);
      final contextLocations = _selectReviewContextLocations(
        allLocs,
        focusLocationIds: createdLocationIds,
      );
      final locationContext = _buildReviewLocationContext(contextLocations);

      final reviewPrompt = prompt.trim().isNotEmpty
          ? '$prompt\n\nTạo thêm 3 bài viết review/guide có giọng văn khác nhau để demo hội đồng.'
          : 'Tạo 3 bài viết review/guide khác góc nhìn, nội dung thuyết phục, để minh họa hệ thống AI.';

      final reviewJsonList = await service.generateMultipleReviews(
        prompt: reviewPrompt,
        destinationName: destinationName,
        destinationId: destinationId,
        existingLocations: locationContext,
        articleStyle: 'review',
        count: 3,
      );

      final reviewRepo = ref.read(reviewRepositoryProvider);
      final createdReviewIds = <String>{};
      for (final json in reviewJsonList) {
        var review = Review.fromJson(json);
        if (review.destinationId == null) {
          review = review.copyWith(
            destinationId: destinationId,
            destinationName: destinationName,
          );
        }
        review = _applyHeroFallback(review, contextLocations, allLocs);
        await reviewRepo.createReview(review);
        createdReviewIds.add(review.id);
      }

      state = state.copyWith(
        isGenerating: false,
        lastGeneratedType: 'demo-pack',
        generatedCount: locationJsonList.length + reviewJsonList.length,
        successMessage:
            'Đã tạo ${locationJsonList.length + reviewJsonList.length} AI drafts',
        demoPackStep: DemoPackStep.completed,
        highlightedLocationIds: createdLocationIds,
        highlightedReviewIds: createdReviewIds,
      );

      ref.invalidate(pendingLocationsProvider);
      _invalidateReviewQueues(ref);
      ref.invalidate(adminLocationLookupProvider);
      ref.invalidate(adminStatsProvider);
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: e.toString(),
        demoPackStep: DemoPackStep.idle,
      );
    }
  }

  Future<void> expandReviewDraft(
    Review review, {
    String? prompt,
    String articleStyle = 'review',
  }) async {
    state = state.copyWith(
      isGenerating: true,
      error: null,
      clearSuccessMessage: true,
    );

    try {
      final service = ref.read(aiContentServiceProvider);
      final destinationRepo = ref.read(destinationRepositoryProvider);
      final destinationId = review.destinationId;

      List<Location> allLocations = const [];
      List<Location> contextLocations = const [];

      if (destinationId != null && destinationId.isNotEmpty) {
        allLocations = await destinationRepo.getLocationsByDestination(
          destinationId,
        );
        contextLocations = _selectReviewContextLocations(
          allLocations,
          focusLocationIds: review.relatedLocationIds.toSet(),
        );
      }

      final json = await service.expandReviewDraft(
        draftReview: review.toJson(),
        existingLocations: _buildReviewLocationContext(contextLocations),
        prompt: prompt?.trim().isEmpty == true ? null : prompt?.trim(),
        destinationId: review.destinationId,
        destinationName: review.destinationName,
        articleStyle: articleStyle,
      );

      var preview = Review.fromJson(json);
      if (review.destinationId != null && preview.destinationId == null) {
        preview = preview.copyWith(
          destinationId: review.destinationId,
          destinationName: review.destinationName,
        );
      }

      preview = _applyHeroFallback(preview, contextLocations, allLocations);

      final reviewRepo = ref.read(reviewRepositoryProvider);
      await reviewRepo.updateReview(preview);

      state = state.copyWith(
        isGenerating: false,
        lastGeneratedType: 'review-preview',
        generatedCount: 1,
        successMessage: 'Đã tạo preview hoàn chỉnh cho bài viết AI.',
      );

      _invalidateReviewQueues(ref);
      ref.invalidate(adminStatsProvider);
    } catch (error) {
      state = state.copyWith(isGenerating: false, error: error.toString());
    }
  }

  /// Approve a pending item (change status to 'published').
  Future<void> approveDestination(Destination dest) async {
    final repo = ref.read(destinationRepositoryProvider);
    final normalizedId = dest.id.trim();
    final normalizedName = dest.name.trim();
    final normalizedDescription = dest.description.trim();
    final normalizedHeroImage = dest.heroImage.trim();

    if (normalizedId.isEmpty || normalizedName.isEmpty) {
      throw Exception('Điểm đến AI draft thiếu ID hoặc tên hợp lệ.');
    }
    if (normalizedDescription.isEmpty) {
      throw Exception('Điểm đến AI draft thiếu mô tả.');
    }
    // Auto-fill placeholder if heroImage is missing
    final heroImage = normalizedHeroImage.isNotEmpty && _isValidHttpUrl(normalizedHeroImage)
        ? normalizedHeroImage
        : 'https://images.unsplash.com/photo-1528127269322-539801943592?w=800&q=80';

    await repo.updateDestination(
      dest.copyWith(
        id: normalizedId,
        name: normalizedName,
        description: normalizedDescription,
        heroImage: heroImage,
        status: 'published',
        createdAt: dest.createdAt ?? DateTime.now(),
      ),
    );
    ref.invalidate(pendingDestinationsProvider);
    ref.invalidate(adminDestinationLookupProvider);
    ref.invalidate(adminStatsProvider);
  }

  Future<void> approveLocation(Location loc) async {
    final repo = ref.read(destinationRepositoryProvider);
    await repo.updateLocation(
      loc.copyWith(
        id: loc.id.trim(),
        name: loc.name.trim(),
        image: loc.image.trim(),
        category: loc.category.trim(),
        address: loc.address?.trim(),
        description: loc.description?.trim(),
        priceRange: loc.priceRange?.trim(),
        status: 'published',
      ),
    );
    ref.invalidate(pendingLocationsProvider);
    ref.invalidate(adminLocationLookupProvider);
    ref.invalidate(adminStatsProvider);
  }

  Future<void> publishReview(Review review) async {
    final repo = ref.read(reviewRepositoryProvider);
    await repo.updateReview(
      review.copyWith(
        id: review.id.trim(),
        title: review.title.trim(),
        heroImage: review.heroImage.trim(),
        authorName: review.authorName.trim(),
        authorAvatar: review.authorAvatar.trim(),
        fullText: review.fullText.trim(),
        destinationId: review.destinationId?.trim(),
        destinationName: review.destinationName?.trim(),
        category: review.category?.trim(),
        status: 'published',
      ),
    );
    _invalidateReviewQueues(ref);
    ref.invalidate(adminStatsProvider);
  }

  Future<void> approveReview(Review review) async {
    await publishReview(review);
  }

  /// Reject (delete) a pending item.
  Future<void> rejectDestination(String id) async {
    final repo = ref.read(destinationRepositoryProvider);
    await repo.deleteDestination(id);
    ref.invalidate(pendingDestinationsProvider);
    ref.invalidate(adminDestinationLookupProvider);
    ref.invalidate(adminStatsProvider);
  }

  Future<void> rejectLocation(String id) async {
    final repo = ref.read(destinationRepositoryProvider);
    await repo.deleteLocation(id);
    ref.invalidate(pendingLocationsProvider);
    ref.invalidate(adminLocationLookupProvider);
    ref.invalidate(adminStatsProvider);
  }

  Future<void> rejectReview(String id) async {
    final repo = ref.read(reviewRepositoryProvider);
    await repo.deleteReview(id);
    _invalidateReviewQueues(ref);
    ref.invalidate(adminStatsProvider);
  }
}

final aiContentNotifierProvider =
    NotifierProvider<AiContentNotifier, AiContentState>(() {
      return AiContentNotifier();
    });
