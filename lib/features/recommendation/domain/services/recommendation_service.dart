import 'dart:math';

import 'package:geolocator/geolocator.dart';

import '../../domain/entities/recommendation_item.dart';
import '../../domain/entities/user_profile.dart';
import '../../../destination/domain/entities/location.dart';

/// Service implementing the personalized recommendation algorithm.
///
/// Scoring formula per location:
///   score = w1*matchCategory + w2*matchTags + w3*quality
///         + w4*behaviorAffinity + w5*novelty + w6*contextBoost
///
/// After scoring, results are optionally diversified using MMR
/// (Maximal Marginal Relevance) to avoid homogeneous recommendations.
class RecommendationService {
  const RecommendationService();

  // ──── Weight constants ────
  static const double _wCategory = 0.20;
  static const double _wTags = 0.15;
  static const double _wQuality = 0.15;
  static const double _wBehavior = 0.15;
  static const double _wNovelty = 0.10;
  static const double _wContext = 0.10;
  static const double _wProximity = 0.15;

  /// Generate ranked recommendations.
  ///
  /// [candidates] — all candidate locations.
  /// [profile] — user's explicit preferences (nullable if no profile).
  /// [categoryInterests] — weighted category scores from user events.
  /// [tagInterests] — weighted tag scores from user events.
  /// [interactedLocationIds] — locations user has saved/added (for novelty).
  /// [userLat], [userLng] — user GPS for proximity scoring (nullable).
  /// [boostCategory] — category to boost (e.g. 'places' for check-in).
  /// [topN] — number of recommendations to return.
  /// [diversify] — whether to apply MMR diversity re-ranking.
  List<RecommendationItem> recommend({
    required List<Location> candidates,
    UserProfile? profile,
    Map<String, double> categoryInterests = const {},
    Map<String, double> tagInterests = const {},
    Set<String> interactedLocationIds = const {},
    double? userLat,
    double? userLng,
    String? boostCategory,
    int topN = 10,
    bool diversify = true,
  }) {
    if (candidates.isEmpty) return [];

    // Step 1: Score each candidate
    final scored = <_ScoredLocation>[];
    for (final loc in candidates) {
      final result = _scoreLocation(
        loc,
        profile: profile,
        categoryInterests: categoryInterests,
        tagInterests: tagInterests,
        interactedLocationIds: interactedLocationIds,
        userLat: userLat,
        userLng: userLng,
        boostCategory: boostCategory,
      );
      scored.add(result);
    }

    // Step 2: Sort by score descending
    scored.sort((a, b) => b.score.compareTo(a.score));

    // Step 3: Optional MMR diversity re-ranking
    final selected = diversify
        ? _applyMMR(scored, topN: topN, lambda: 0.7)
        : scored.take(topN).toList();

    // Step 4: Convert to RecommendationItem
    return selected
        .map(
          (s) => RecommendationItem(
            locationId: s.location.id,
            score: s.score,
            reasons: s.reasons,
          ),
        )
        .toList();
  }

  // ──── Scoring ────

  _ScoredLocation _scoreLocation(
    Location loc, {
    UserProfile? profile,
    required Map<String, double> categoryInterests,
    required Map<String, double> tagInterests,
    required Set<String> interactedLocationIds,
    double? userLat,
    double? userLng,
    String? boostCategory,
  }) {
    final reasons = <String>[];
    double score = 0;

    // 1. Category match
    final catMatch = _categoryMatchScore(loc, profile);
    if (catMatch > 0) {
      reasons.add('Hợp sở thích ${_categoryLabel(loc.category)}');
    }
    score += _wCategory * catMatch;

    // 2. Tag match (Jaccard similarity)
    final tagMatch = _tagMatchScore(loc, profile);
    if (tagMatch > 0.3) reasons.add('Phù hợp phong cách');
    score += _wTags * tagMatch;

    // 3. Quality (rating + popularity)
    final quality = _qualityScore(loc);
    if (quality > 0.7) reasons.add('Được đánh giá cao');
    score += _wQuality * quality;

    // 4. Behavior affinity (from interaction history)
    final behavior = _behaviorScore(loc, categoryInterests, tagInterests);
    if (behavior > 0.3) reasons.add('Dựa trên hoạt động gần đây');
    score += _wBehavior * behavior;

    // 5. Novelty (locations not yet interacted)
    final novelty = interactedLocationIds.contains(loc.id) ? 0.0 : 1.0;
    if (novelty > 0) reasons.add('Chưa khám phá');
    score += _wNovelty * novelty;

    // 6. Context boost (group type, budget match)
    final context = _contextScore(loc, profile);
    if (context > 0.3) reasons.add('Phù hợp nhóm đi');
    score += _wContext * context;

    // 7. Proximity scoring (GPS-based)
    final proximity = _proximityScore(loc, userLat, userLng);
    if (proximity > 0.7 && userLat != null) {
      final dist = _distanceKm(
        userLat,
        userLng!,
        loc.latitude!,
        loc.longitude!,
      );
      reasons.add('📍 Cách ${_formatDist(dist)}');
    }
    score += _wProximity * proximity;

    // 8. Category boost (e.g. check-in → places)
    if (boostCategory != null && loc.category == boostCategory) {
      score += 0.30;
      reasons.add('📸 Điểm check-in hot');
    }

    // 9. Destination preference boost (onboarding pick)
    if (profile != null &&
        profile.preferredDestinationIds.isNotEmpty &&
        profile.preferredDestinationIds.contains(loc.destinationId)) {
      score += 0.25;
      reasons.add('🗺️ Nơi bạn muốn đến');
    }

    // Fallback: if no profile, boost popular items
    if (profile == null || !profile.hasPreferences) {
      if (loc.saveCount > 50 || loc.viewCount > 200) {
        reasons.add('Đang thịnh hành');
      }
    }

    return _ScoredLocation(
      location: loc,
      score: score,
      reasons: reasons.take(3).toList(), // Max 3 reasons for UI
    );
  }

  double _categoryMatchScore(Location loc, UserProfile? profile) {
    if (profile == null || profile.preferredCategoryIds.isEmpty) return 0.3;
    return profile.preferredCategoryIds.contains(loc.category) ? 1.0 : 0.0;
  }

  double _tagMatchScore(Location loc, UserProfile? profile) {
    if (profile == null || profile.preferredTags.isEmpty || loc.tags.isEmpty) {
      return 0.0;
    }
    // Jaccard similarity
    final setA = profile.preferredTags.toSet();
    final setB = loc.tags.toSet();
    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    return union > 0 ? intersection / union : 0.0;
  }

  double _qualityScore(Location loc) {
    // Normalize rating to 0-1 (rating is 0-5)
    final ratingScore = (loc.rating ?? 0) / 5.0;
    // Log-scale popularity
    final popScore = min(
      1.0,
      (log(1 + loc.viewCount + loc.saveCount * 2) / 10),
    );
    return ratingScore * 0.6 + popScore * 0.4;
  }

  double _behaviorScore(
    Location loc,
    Map<String, double> categoryInterests,
    Map<String, double> tagInterests,
  ) {
    if (categoryInterests.isEmpty && tagInterests.isEmpty) return 0.0;

    double score = 0;
    double maxPossible = 0;

    // Category affinity from behavior
    if (categoryInterests.isNotEmpty) {
      final maxCatScore = categoryInterests.values.reduce(
        (a, b) => a > b ? a : b,
      );
      if (maxCatScore > 0) {
        score += (categoryInterests[loc.category] ?? 0) / maxCatScore;
      }
      maxPossible += 1;
    }

    // Tag affinity from behavior
    if (tagInterests.isNotEmpty && loc.tags.isNotEmpty) {
      final maxTagScore = tagInterests.values.reduce((a, b) => a > b ? a : b);
      if (maxTagScore > 0) {
        double tagAffin = 0;
        for (final tag in loc.tags) {
          tagAffin += (tagInterests[tag] ?? 0) / maxTagScore;
        }
        score += min(1.0, tagAffin / loc.tags.length);
      }
      maxPossible += 1;
    }

    return maxPossible > 0 ? score / maxPossible : 0;
  }

  double _contextScore(Location loc, UserProfile? profile) {
    if (profile == null) return 0.0;
    double score = 0;

    // Budget match via priceRange
    if (loc.priceRange != null) {
      final locBudget = loc.priceRange!.length; // '$' = 1, '$$' = 2, '$$$' = 3
      final userBudget = profile.budgetLevel.index + 1; // low=1, med=2, high=3
      if (locBudget <= userBudget) score += 0.5;
    }

    // Group type tag match
    final groupTags = {
      GroupType.family: ['family-friendly'],
      GroupType.couple: ['romantic'],
      GroupType.friends: ['nightlife', 'adventure'],
      GroupType.solo: ['hidden-gem', 'local-favorite'],
    };
    final boostTags = groupTags[profile.groupType] ?? [];
    if (loc.tags.any((t) => boostTags.contains(t))) {
      score += 0.5;
    }

    return score;
  }

  /// Vietnamese label for category IDs.
  static String _categoryLabel(String category) {
    const labels = {
      'places': 'Địa điểm',
      'food': 'Ẩm thực',
      'cafe': 'Cafe',
      'stay': 'Lưu trú',
      'shopping': 'Mua sắm',
    };
    return labels[category] ?? category;
  }

  /// Proximity score: 1.0 if < 5km, decays to 0 at 100km+.
  double _proximityScore(Location loc, double? userLat, double? userLng) {
    if (userLat == null || userLng == null) return 0.3; // neutral if no GPS
    if (loc.latitude == null || loc.longitude == null) return 0.1;

    final dist = _distanceKm(userLat, userLng, loc.latitude!, loc.longitude!);
    if (dist < 5) return 1.0;
    if (dist < 20) return 0.8;
    if (dist < 50) return 0.5;
    if (dist < 100) return 0.3;
    return 0.1;
  }

  /// Distance in km between two GPS points.
  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000.0;
  }

  /// Format distance for display.
  String _formatDist(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 100) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }

  // ──── MMR Diversity ────

  /// Maximal Marginal Relevance re-ranking.
  ///
  /// Picks items that balance relevance (score) with diversity
  /// (dissimilarity to already picked items).
  /// Lambda controls the trade-off: 1.0 = pure relevance, 0.0 = pure diversity.
  List<_ScoredLocation> _applyMMR(
    List<_ScoredLocation> candidates, {
    required int topN,
    required double lambda,
  }) {
    if (candidates.length <= topN) return candidates;

    final selected = <_ScoredLocation>[candidates.first];
    final remaining = candidates.sublist(1).toList();

    while (selected.length < topN && remaining.isNotEmpty) {
      double bestMmrScore = double.negativeInfinity;
      int bestIdx = 0;

      for (int i = 0; i < remaining.length; i++) {
        final candidate = remaining[i];

        // Max similarity to any already selected item
        double maxSim = 0;
        for (final sel in selected) {
          maxSim = max(maxSim, _similarity(candidate, sel));
        }

        final mmr = lambda * candidate.score - (1 - lambda) * maxSim;
        if (mmr > bestMmrScore) {
          bestMmrScore = mmr;
          bestIdx = i;
        }
      }

      selected.add(remaining.removeAt(bestIdx));
    }

    return selected;
  }

  /// Similarity between two locations based on category + tag overlap.
  double _similarity(_ScoredLocation a, _ScoredLocation b) {
    double sim = 0;
    // Same category = high similarity
    if (a.location.category == b.location.category) sim += 0.5;
    // Tag overlap
    if (a.location.tags.isNotEmpty && b.location.tags.isNotEmpty) {
      final setA = a.location.tags.toSet();
      final setB = b.location.tags.toSet();
      final overlap = setA.intersection(setB).length;
      final union = setA.union(setB).length;
      if (union > 0) sim += 0.5 * overlap / union;
    }
    return sim;
  }
}

/// Internal scored location for ranking.
class _ScoredLocation {
  final Location location;
  final double score;
  final List<String> reasons;

  const _ScoredLocation({
    required this.location,
    required this.score,
    required this.reasons,
  });
}
