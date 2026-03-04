import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/review_like.dart';

/// Repository for managing review likes.
///
/// Currently uses in-memory storage for MVP.
/// Will be replaced with Firestore integration in a later story.
///
/// See Story 3.9 for requirements.
class ReviewLikeRepository {
  /// In-memory storage for likes (MVP implementation)
  /// Key format: "userId:reviewId"
  final Map<String, ReviewLike> _likesStore = {};

  /// In-memory like count updates (delta from initial counts)
  final Map<String, int> _likeCountDeltas = {};

  /// Like a review
  ///
  /// [reviewId] - The review to like
  /// [userId] - The user who is liking
  ///
  /// Throws if the user has already liked this review.
  Future<void> likeReview(String reviewId, String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    final key = '$userId:$reviewId';

    if (_likesStore.containsKey(key)) {
      throw Exception('Review already liked by this user');
    }

    _likesStore[key] = ReviewLike(
      reviewId: reviewId,
      userId: userId,
      createdAt: DateTime.now(),
    );

    // Update like count delta
    _likeCountDeltas[reviewId] = (_likeCountDeltas[reviewId] ?? 0) + 1;
  }

  /// Unlike a review
  ///
  /// [reviewId] - The review to unlike
  /// [userId] - The user who is unliking
  Future<void> unlikeReview(String reviewId, String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    final key = '$userId:$reviewId';
    _likesStore.remove(key);

    // Update like count delta
    _likeCountDeltas[reviewId] = (_likeCountDeltas[reviewId] ?? 0) - 1;
  }

  /// Check if a user has liked a specific review
  ///
  /// [reviewId] - The review to check
  /// [userId] - The user to check
  ///
  /// Returns true if the user has liked this review.
  Future<bool> isLikedByUser(String reviewId, String userId) async {
    final key = '$userId:$reviewId';
    return _likesStore.containsKey(key);
  }

  /// Check if a user has liked a specific review (synchronous)
  ///
  /// [reviewId] - The review to check
  /// [userId] - The user to check
  ///
  /// Returns true if the user has liked this review.
  bool isLikedByUserSync(String reviewId, String userId) {
    final key = '$userId:$reviewId';
    return _likesStore.containsKey(key);
  }

  /// Get the like count delta for a review
  ///
  /// [reviewId] - The review to get delta for
  ///
  /// Returns the change in like count from the initial value.
  int getLikeCountDelta(String reviewId) {
    return _likeCountDeltas[reviewId] ?? 0;
  }

  /// Get all likes for a review
  ///
  /// [reviewId] - The review to get likes for
  ///
  /// Returns a list of all likes for this review.
  Future<List<ReviewLike>> getLikesForReview(String reviewId) async {
    return _likesStore.values
        .where((like) => like.reviewId == reviewId)
        .toList();
  }

  /// Toggle like state for a review
  ///
  /// [reviewId] - The review to toggle
  /// [userId] - The user toggling the like
  ///
  /// Returns true if the review is now liked, false if unliked.
  Future<bool> toggleLike(String reviewId, String userId) async {
    final isLiked = await isLikedByUser(reviewId, userId);

    if (isLiked) {
      await unlikeReview(reviewId, userId);
      return false;
    } else {
      await likeReview(reviewId, userId);
      return true;
    }
  }
}

/// Provider for ReviewLikeRepository
final reviewLikeRepositoryProvider = Provider<ReviewLikeRepository>((ref) {
  return ReviewLikeRepository();
});
