/// UserStats - Entity representing user statistics for profile display
///
/// Contains counts for trips, saved locations, and reviews.
/// Provides formatted display strings for large numbers (e.g., 1.2k).
class UserStats {
  final int tripCount;
  final int savesCount;
  final int reviewsCount;

  const UserStats({
    required this.tripCount,
    required this.savesCount,
    required this.reviewsCount,
  });

  /// Factory for empty/default stats
  factory UserStats.empty() =>
      const UserStats(tripCount: 0, savesCount: 0, reviewsCount: 0);

  /// Format count for display (e.g., 1200 -> "1.2k")
  String get formattedTripCount => _formatCount(tripCount);
  String get formattedSavesCount => _formatCount(savesCount);
  String get formattedReviewsCount => _formatCount(reviewsCount);

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  /// CopyWith for immutability pattern
  UserStats copyWith({int? tripCount, int? savesCount, int? reviewsCount}) {
    return UserStats(
      tripCount: tripCount ?? this.tripCount,
      savesCount: savesCount ?? this.savesCount,
      reviewsCount: reviewsCount ?? this.reviewsCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserStats &&
        other.tripCount == tripCount &&
        other.savesCount == savesCount &&
        other.reviewsCount == reviewsCount;
  }

  @override
  int get hashCode =>
      tripCount.hashCode ^ savesCount.hashCode ^ reviewsCount.hashCode;

  @override
  String toString() =>
      'UserStats(trips: $tripCount, saves: $savesCount, reviews: $reviewsCount)';
}
