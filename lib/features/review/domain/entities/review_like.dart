/// Entity representing a like on a review.
///
/// This is an immutable value object containing like information.
/// Used for tracking which users have liked which reviews.
///
/// See Story 3.9 for acceptance criteria.
class ReviewLike {
  /// Unique identifier for the review that was liked
  final String reviewId;

  /// ID of the user who liked the review
  final String userId;

  /// When the like was created
  final DateTime createdAt;

  const ReviewLike({
    required this.reviewId,
    required this.userId,
    required this.createdAt,
  });

  /// Creates a copy with modified fields (immutability pattern)
  ReviewLike copyWith({String? reviewId, String? userId, DateTime? createdAt}) {
    return ReviewLike(
      reviewId: reviewId ?? this.reviewId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Creates a unique key for this like (used for storage)
  String get key => '$userId:$reviewId';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewLike &&
        other.reviewId == reviewId &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(reviewId, userId);

  @override
  String toString() {
    return 'ReviewLike(reviewId: $reviewId, userId: $userId, createdAt: $createdAt)';
  }
}
