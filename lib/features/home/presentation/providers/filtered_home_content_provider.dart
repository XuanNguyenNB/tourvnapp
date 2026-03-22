import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/content_item.dart';
import './home_provider.dart';
import './home_filter_provider.dart';
import './user_location_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../onboarding/presentation/providers/user_mood_preferences_provider.dart';
import '../../../recommendation/data/repositories/user_profile_repository.dart';
import '../../../../core/services/onboarding_service.dart';

/// Provider for filtered home content based on user mood preferences,
/// GPS proximity, and selected destination preferences from onboarding.
///
/// **Scoring Algorithm (composite):**
/// 1. Mood match score (0-1): matching moods / total user moods
/// 2. Proximity score (0-1): closer = higher (decay over 200km)
/// 3. Destination preference score (0 or 0.5): boost if review belongs to
///    a destination chosen during onboarding
///
/// **Fallback Behavior:**
/// - If no preferences set → returns original content order
/// - If no GPS → proximity score = 0 for all items
/// - If content loading fails → propagates error
///
/// Story 6.5: Implement Personalized Feed Filtering
/// Story 8-9: Added destination/category filtering with AND logic
final filteredHomeContentProvider =
    AsyncNotifierProvider<FilteredHomeContentNotifier, List<ContentItem>>(
      FilteredHomeContentNotifier.new,
    );

/// Notifier that handles content filtering based on user mood preferences,
/// GPS distance, and onboarding destination preferences.
class FilteredHomeContentNotifier extends AsyncNotifier<List<ContentItem>> {
  @override
  Future<List<ContentItem>> build() async {
    // Watch content provider for reactive updates
    final contentAsync = ref.watch(homeContentProvider);

    // Watch user mood preferences for reactive updates
    final moodsAsync = ref.watch(userMoodPreferencesProvider);

    // Watch user location for proximity scoring
    final locationState = ref.watch(userLocationProvider);

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

    // Load preferred destination IDs from onboarding UserProfile
    final preferredDestIds = await _loadPreferredDestinationIds();

    // Apply composite scoring (mood + proximity + destination preference)
    var sortedContent = _scoreAndSort(
      content,
      userMoods: userMoods,
      userPosition: locationState.position,
      preferredDestinationIds: preferredDestIds,
    );

    // Apply destination/category filter (Story 8-9)
    if (homeFilter.hasFilters) {
      sortedContent = sortedContent.where(homeFilter.matchesFilter).toList();
    }

    return sortedContent;
  }

  /// Load preferred destination IDs: Firestore first, then local fallback.
  Future<Set<String>> _loadPreferredDestinationIds() async {
    // 1. Try Firestore (authenticated users)
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final profileRepo = ref.read(userProfileRepositoryProvider);
        final profile = await profileRepo.getProfile(user.uid);
        if (profile != null && profile.preferredDestinationIds.isNotEmpty) {
          return profile.preferredDestinationIds.toSet();
        }
      }
    } catch (_) {
      // Firestore unavailable — try local
    }

    // 2. Fallback: SharedPreferences (anonymous users / offline)
    try {
      final service = ref.read(onboardingServiceProvider);
      final localIds = service.getDestinationPreferencesLocally();
      if (localIds.isNotEmpty) {
        return localIds.toSet();
      }
    } catch (_) {
      // onboardingService not yet initialized
    }

    return <String>{};
  }

  /// Composite scoring: combines mood match, proximity, and destination
  /// preference into a single score for sorting.
  List<ContentItem> _scoreAndSort(
    List<ContentItem> content, {
    required List<String> userMoods,
    required Position? userPosition,
    required Set<String> preferredDestinationIds,
  }) {
    final hasAnySignal =
        userMoods.isNotEmpty ||
        userPosition != null ||
        preferredDestinationIds.isNotEmpty;

    if (!hasAnySignal) return content;

    final scored = content.map((item) {
      double score = 0;

      // ── 1. Mood match score (weight: 40%) ──
      if (userMoods.isNotEmpty) {
        final contentMoods = _getMoodsFromContent(item);
        final matchCount = contentMoods
            .where((m) => userMoods.contains(m))
            .length;
        score += 0.4 * (matchCount / userMoods.length);
      }

      // ── 2. Proximity score (weight: 35%) ──
      if (userPosition != null) {
        final coords = _getCoordinates(item);
        if (coords != null) {
          final distKm =
              Geolocator.distanceBetween(
                userPosition.latitude,
                userPosition.longitude,
                coords.$1,
                coords.$2,
              ) /
              1000.0;
          // Exponential decay: score = 1 at 0 km, ~0.5 at 140 km, ~0 at 500+ km
          score += 0.35 * _proximityScore(distKm);
        }
      }

      // ── 3. Destination preference boost (weight: 25%) ──
      if (preferredDestinationIds.isNotEmpty) {
        final destId = _getDestinationId(item);
        if (destId != null && preferredDestinationIds.contains(destId)) {
          score += 0.25;
        }
      }

      return _ScoredContent(item, score);
    }).toList();

    // Sort by composite score (desc), then by engagement (desc)
    scored.sort((a, b) {
      if ((a.score - b.score).abs() > 0.01) {
        return b.score.compareTo(a.score);
      }
      return _getEngagement(b.item).compareTo(_getEngagement(a.item));
    });

    return scored.map((s) => s.item).toList();
  }

  /// Exponential decay for proximity: closer = higher score.
  /// Returns 1.0 at 0km, ~0.5 at ~140km, ~0.03 at 500km.
  double _proximityScore(double distKm) {
    const decayRate = 0.005; // controls how fast score drops
    return 1.0 / (1.0 + decayRate * distKm * distKm);
  }

  /// Extracts mood tags from a content item.
  List<String> _getMoodsFromContent(ContentItem item) {
    return switch (item) {
      DestinationContent(:final destination) => destination.moods ?? [],
      ReviewContent(:final review) => review.moods ?? [],
    };
  }

  /// Extracts GPS coordinates from a content item.
  (double, double)? _getCoordinates(ContentItem item) {
    return switch (item) {
      DestinationContent() => null, // Destinations don't carry GPS
      ReviewContent(:final review) =>
        review.hasCoordinates ? (review.latitude!, review.longitude!) : null,
    };
  }

  /// Extracts destination ID from a content item.
  String? _getDestinationId(ContentItem item) {
    return switch (item) {
      DestinationContent(:final destination) => destination.id,
      ReviewContent(:final review) => review.destinationId,
    };
  }

  /// Gets engagement count for secondary sorting.
  int _getEngagement(ContentItem item) {
    return switch (item) {
      DestinationContent(:final destination) => destination.engagementCount,
      ReviewContent(:final review) => review.likeCount,
    };
  }
}

/// Internal class to hold content item with its composite score.
class _ScoredContent {
  final ContentItem item;
  final double score;

  const _ScoredContent(this.item, this.score);
}
