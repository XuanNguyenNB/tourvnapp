/// A single recommendation item with score and reasons.
///
/// Produced by the recommendation engine and consumed by UI
/// to display personalized suggestions with explanations.
class RecommendationItem {
  /// Location ID being recommended.
  final String locationId;

  /// Computed recommendation score (higher = more relevant).
  final double score;

  /// Human-readable reasons for the recommendation.
  /// Examples: "Hợp sở thích thiên nhiên", "Đang thịnh hành"
  final List<String> reasons;

  const RecommendationItem({
    required this.locationId,
    required this.score,
    this.reasons = const [],
  });

  @override
  String toString() =>
      'RecommendationItem(locationId: $locationId, score: ${score.toStringAsFixed(2)}, '
      'reasons: $reasons)';
}
