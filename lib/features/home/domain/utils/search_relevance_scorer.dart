import '../../../destination/domain/entities/location.dart';

/// Utility for calculating relevance scores for location search results.
///
/// Uses a tier-based scoring system where exact matches score highest,
/// followed by prefix matches, contains matches, destination matches,
/// and keyword matches.
///
/// Story 8-6: Implement Location Search Provider
abstract class SearchRelevanceScorer {
  /// Calculate relevance score for a location given a search query.
  ///
  /// Returns a score from 0-100 where higher is more relevant:
  /// - Tier 1 (100): Exact match in name
  /// - Tier 2 (80): Name starts with query
  /// - Tier 3 (60): Name contains query
  /// - Tier 4 (40): Destination name matches
  /// - Tier 5 (20): Search keywords match
  /// - (0): No match
  static int calculateScore(Location location, String query) {
    if (query.isEmpty) return 0;

    final lowerQuery = query.toLowerCase().trim();
    final lowerName = location.name.toLowerCase();

    // Tier 1: Exact match in name (score 100)
    if (lowerName == lowerQuery) {
      return 100;
    }

    // Tier 2: Name starts with query (score 80)
    if (lowerName.startsWith(lowerQuery)) {
      return 80;
    }

    // Tier 3: Name contains query (score 60)
    if (lowerName.contains(lowerQuery)) {
      return 60;
    }

    // Tier 4: Destination name matches (score 40)
    final destName = location.destinationName?.toLowerCase() ?? '';
    if (destName.contains(lowerQuery)) {
      return 40;
    }

    // Tier 5: Search keywords match (score 20)
    if (location.searchKeywords.any(
      (keyword) => keyword.toLowerCase().contains(lowerQuery),
    )) {
      return 20;
    }

    return 0;
  }

  /// Sort locations by relevance score (descending).
  ///
  /// Primary sort: relevance score (higher first)
  /// Secondary sort: viewCount (higher first) for equal scores
  ///
  /// Returns a new sorted list without modifying the original.
  static List<Location> sortByRelevance(
    List<Location> locations,
    String query,
  ) {
    if (query.isEmpty || locations.isEmpty) {
      return locations;
    }

    // Create list of scored locations for sorting
    final scoredLocations = locations.map((location) {
      return _ScoredLocation(
        location: location,
        score: calculateScore(location, query),
      );
    }).toList();

    // Sort by score descending, then by viewCount descending
    scoredLocations.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return b.location.viewCount.compareTo(a.location.viewCount);
    });

    return scoredLocations.map((s) => s.location).toList();
  }

  /// Filter and sort locations by relevance, returning only matching results.
  ///
  /// This combines filtering (score > 0) with sorting in one operation.
  static List<Location> filterAndSort(List<Location> locations, String query) {
    if (query.isEmpty || locations.isEmpty) {
      return [];
    }

    // Score, filter, and sort in one pass
    final scoredLocations = <_ScoredLocation>[];
    for (final location in locations) {
      final score = calculateScore(location, query);
      if (score > 0) {
        scoredLocations.add(_ScoredLocation(location: location, score: score));
      }
    }

    // Sort by score descending, then by viewCount descending
    scoredLocations.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return b.location.viewCount.compareTo(a.location.viewCount);
    });

    return scoredLocations.map((s) => s.location).toList();
  }
}

/// Internal class for tracking scored locations during sorting.
class _ScoredLocation {
  final Location location;
  final int score;

  const _ScoredLocation({required this.location, required this.score});
}
