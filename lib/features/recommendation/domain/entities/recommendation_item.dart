class RecommendationScoreBreakdown {
  const RecommendationScoreBreakdown({
    this.category = 0,
    this.tags = 0,
    this.quality = 0,
    this.behavior = 0,
    this.novelty = 0,
    this.context = 0,
    this.proximity = 0,
    this.boost = 0,
  });

  final double category;
  final double tags;
  final double quality;
  final double behavior;
  final double novelty;
  final double context;
  final double proximity;
  final double boost;

  List<({String label, double value})> get factors => [
    (label: 'Sở thích', value: category),
    (label: 'Tags', value: tags),
    (label: 'Chất lượng', value: quality),
    (label: 'Hành vi', value: behavior),
    (label: 'Mới lạ', value: novelty),
    (label: 'Ngữ cảnh', value: context),
    (label: 'Gần bạn', value: proximity),
    (label: 'Boost', value: boost),
  ];

  double get maxValue {
    final values = [
      category,
      tags,
      quality,
      behavior,
      novelty,
      context,
      proximity,
      boost,
    ];
    return values.reduce((a, b) => a > b ? a : b);
  }
}

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

  /// Per-factor explainability breakdown for the final score.
  final RecommendationScoreBreakdown scoreBreakdown;

  const RecommendationItem({
    required this.locationId,
    required this.score,
    this.reasons = const [],
    this.scoreBreakdown = const RecommendationScoreBreakdown(),
  });

  @override
  String toString() =>
      'RecommendationItem(locationId: $locationId, score: ${score.toStringAsFixed(2)}, '
      'reasons: $reasons, scoreBreakdown: $scoreBreakdown)';
}
