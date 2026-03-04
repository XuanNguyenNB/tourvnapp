import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/content_item.dart';
import './home_provider.dart';
import './home_filter_provider.dart';
import '../../../onboarding/presentation/providers/user_mood_preferences_provider.dart';

/// Provider for filtered home content based on user mood preferences.
///
/// **Filtering Logic:**
/// - Content with matching moods appears first, sorted by match score
/// - Match score = (number of matching moods) / (total user moods)
/// - Non-matching content follows, sorted by engagement count
/// - All content is still returned (no hard filtering)
///
/// **Reactive Updates:**
/// - Watches homeContentProvider, userMoodPreferencesProvider, and homeFilterProvider
/// - Automatically refreshes when any of these changes
///
/// **Fallback Behavior:**
/// - If no preferences set → returns original content order
/// - If content loading fails → propagates error
/// - If preferences loading fails → falls back to unfiltered content
///
/// Story 6.5: Implement Personalized Feed Filtering
/// Story 8-9: Added destination/category filtering with AND logic
final filteredHomeContentProvider =
    AsyncNotifierProvider<FilteredHomeContentNotifier, List<ContentItem>>(
      FilteredHomeContentNotifier.new,
    );

/// Notifier that handles content filtering based on user mood preferences.
///
/// Uses scoring algorithm to rank content by relevance to user preferences
/// while ensuring all content remains accessible.
class FilteredHomeContentNotifier extends AsyncNotifier<List<ContentItem>> {
  @override
  Future<List<ContentItem>> build() async {
    // Watch content provider for reactive updates
    final contentAsync = ref.watch(homeContentProvider);

    // Watch user mood preferences for reactive updates
    final moodsAsync = ref.watch(userMoodPreferencesProvider);

    // Wait for content to load
    final content = await contentAsync.when(
      data: (data) async => data,
      loading: () async => <ContentItem>[],
      error: (e, st) => throw e,
    );

    // Get user moods - fallback to empty list on error
    final userMoods = moodsAsync.when(
      data: (data) => data,
      loading: () => <String>[],
      error: (e, st) => <String>[],
    );

    // Watch home filter for destination/category filtering (Story 8-9)
    final homeFilter = ref.watch(homeFilterProvider);

    // Apply mood-based sorting first (Story 6-5)
    var sortedContent = content;
    if (userMoods.isNotEmpty) {
      sortedContent = _filterContentByMoods(content, userMoods);
    }

    // Apply destination/category filter (Story 8-9)
    if (homeFilter.hasFilters) {
      sortedContent = sortedContent.where(homeFilter.matchesFilter).toList();
    }

    return sortedContent;
  }

  /// Filters and sorts content based on user mood preferences.
  ///
  /// **Scoring Algorithm:**
  /// - Each content item gets a match score = matched_moods / total_user_moods
  /// - Score of 1.0 = perfect match (all user moods present)
  /// - Score of 0.0 = no matching moods
  ///
  /// **Sorting:**
  /// - Primary: match score (descending)
  /// - Secondary: engagement count (descending)
  ///
  /// **Returns:** Content sorted by relevance, with all items included
  List<ContentItem> _filterContentByMoods(
    List<ContentItem> content,
    List<String> userMoods,
  ) {
    // Calculate match score for each content item
    final scoredContent = content.map((item) {
      final contentMoods = _getMoodsFromContent(item);
      final matchCount = contentMoods
          .where((m) => userMoods.contains(m))
          .length;
      final score = userMoods.isNotEmpty ? matchCount / userMoods.length : 0.0;
      return _ScoredContent(item, score);
    }).toList();

    // Sort by score (descending), then by engagement
    scoredContent.sort((a, b) {
      // Primary sort: match score (higher is better)
      if (a.score != b.score) {
        return b.score.compareTo(a.score);
      }
      // Secondary sort: engagement count (higher is better)
      return _getEngagement(b.item).compareTo(_getEngagement(a.item));
    });

    return scoredContent.map((s) => s.item).toList();
  }

  /// Extracts mood tags from a content item.
  ///
  /// Uses Dart 3 pattern matching for type-safe extraction.
  List<String> _getMoodsFromContent(ContentItem item) {
    return switch (item) {
      DestinationContent(:final destination) => destination.moods ?? [],
      ReviewContent(:final review) => review.moods ?? [],
    };
  }

  /// Gets engagement count for secondary sorting.
  ///
  /// Destinations use engagementCount, Reviews use likeCount.
  int _getEngagement(ContentItem item) {
    return switch (item) {
      DestinationContent(:final destination) => destination.engagementCount,
      ReviewContent(:final review) => review.likeCount,
    };
  }
}

/// Internal class to hold content item with its match score.
///
/// Used during sorting to avoid recalculating scores.
class _ScoredContent {
  final ContentItem item;
  final double score;

  const _ScoredContent(this.item, this.score);
}
