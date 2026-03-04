import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/review_like_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// State class for a review's like status
class ReviewLikeState {
  final bool isLiked;
  final int likeCount;
  final bool isLoading;

  const ReviewLikeState({
    required this.isLiked,
    required this.likeCount,
    this.isLoading = false,
  });

  ReviewLikeState copyWith({bool? isLiked, int? likeCount, bool? isLoading}) {
    return ReviewLikeState(
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Parameters for ReviewLikeNotifier
class ReviewLikeParams {
  final String reviewId;
  final int initialLikeCount;
  final bool initiallyLiked;

  const ReviewLikeParams({
    required this.reviewId,
    required this.initialLikeCount,
    this.initiallyLiked = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewLikeParams &&
        other.reviewId == reviewId &&
        other.initialLikeCount == initialLikeCount &&
        other.initiallyLiked == initiallyLiked;
  }

  @override
  int get hashCode => Object.hash(reviewId, initialLikeCount, initiallyLiked);
}

/// Notifier for managing like state per review (Riverpod 3.0+ style)
///
/// Handles optimistic updates and rollback on error.
/// See Story 3.9 AC #1, #4, #5
class ReviewLikeNotifier extends Notifier<ReviewLikeState> {
  ReviewLikeNotifier(this.params);
  final ReviewLikeParams params;

  @override
  ReviewLikeState build() {
    return ReviewLikeState(
      isLiked: params.initiallyLiked,
      likeCount: params.initialLikeCount,
    );
  }

  /// Toggle like state with optimistic update
  Future<void> toggleLike() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final userId = currentUser.uid;
    final wasLiked = state.isLiked;
    final previousCount = state.likeCount;

    // Optimistic update
    state = state.copyWith(
      isLiked: !wasLiked,
      likeCount: wasLiked ? previousCount - 1 : previousCount + 1,
      isLoading: true,
    );

    try {
      final repository = ref.read(reviewLikeRepositoryProvider);
      if (wasLiked) {
        await repository.unlikeReview(params.reviewId, userId);
      } else {
        await repository.likeReview(params.reviewId, userId);
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Rollback on error
      state = state.copyWith(
        isLiked: wasLiked,
        likeCount: previousCount,
        isLoading: false,
      );
      rethrow;
    }
  }

  /// Force refresh like state from repository
  Future<void> refreshState() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final repository = ref.read(reviewLikeRepositoryProvider);
    final isLiked = await repository.isLikedByUser(
      params.reviewId,
      currentUser.uid,
    );
    final delta = repository.getLikeCountDelta(params.reviewId);

    state = state.copyWith(
      isLiked: isLiked,
      likeCount: params.initialLikeCount + delta,
    );
  }
}

/// Family provider for ReviewLikeNotifier per review (Riverpod 3.0+ style)
final reviewLikeNotifierProvider =
    NotifierProvider.family<
      ReviewLikeNotifier,
      ReviewLikeState,
      ReviewLikeParams
    >((params) => ReviewLikeNotifier(params));

/// Provider to check if current user liked a specific review
///
/// Returns: Future of bool
final isReviewLikedProvider = FutureProvider.family.autoDispose<bool, String>((
  ref,
  reviewId,
) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return false;

  final repository = ref.watch(reviewLikeRepositoryProvider);
  return repository.isLikedByUser(reviewId, currentUser.uid);
});

/// Provider for real-time like count of a review
///
/// Combines initial count with delta from repository
final reviewLikeCountProvider = Provider.family.autoDispose<int, (String, int)>(
  (ref, params) {
    final (reviewId, initialCount) = params;
    final repository = ref.watch(reviewLikeRepositoryProvider);
    return initialCount + repository.getLikeCountDelta(reviewId);
  },
);
