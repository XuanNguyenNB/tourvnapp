import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/vietnamese_text_utils.dart';
import '../../../destination/data/repositories/destination_repository.dart';
import '../../../destination/domain/entities/destination.dart';
import '../../../destination/domain/entities/location.dart';
import '../../../review/data/repositories/review_repository.dart';
import '../../../review/domain/entities/review.dart';
import '../../domain/utils/search_relevance_scorer.dart';

/// Maximum number of search results to return per category
const int _maxResultsPerCategory = 5;

/// State class for unified search
class LocationSearchState {
  final String query;
  final List<Destination> destinations;
  final List<Location> locations;
  final List<Review> reviews;
  final bool isLoading;
  final String? errorMessage;

  const LocationSearchState({
    this.query = '',
    this.destinations = const [],
    this.locations = const [],
    this.reviews = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  LocationSearchState copyWith({
    String? query,
    List<Destination>? destinations,
    List<Location>? locations,
    List<Review>? reviews,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LocationSearchState(
      query: query ?? this.query,
      destinations: destinations ?? this.destinations,
      locations: locations ?? this.locations,
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  /// Check if we have active search results
  bool get hasResults =>
      destinations.isNotEmpty || locations.isNotEmpty || reviews.isNotEmpty;

  /// Check if query is empty
  bool get isEmpty => query.isEmpty;

  /// Check if there's an error state
  bool get hasError => errorMessage != null;
}

/// Provider for DestinationRepository
final destinationRepositoryProvider = Provider<DestinationRepository>((ref) {
  return DestinationRepository();
});

/// Provider for ReviewRepository
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});

/// Notifier for managing location search state.
///
/// Story 8-6: Enhanced with relevance sorting and result limiting.
/// Uses SearchRelevanceScorer for tier-based relevance ordering.
class LocationSearchNotifier extends Notifier<LocationSearchState> {
  @override
  LocationSearchState build() {
    return const LocationSearchState();
  }

  /// Execute search with relevance sorting and result limiting.
  ///
  /// AC3: Results sorted by relevance (Tier 1-5)
  /// AC4: Maximum 10 results returned
  /// AC5: Empty query returns empty state
  /// AC6: Errors are handled gracefully
  Future<void> search(String query) async {
    // AC5: Empty query handling
    if (query.isEmpty) {
      state = const LocationSearchState();
      return;
    }

    // Set loading state, clear previous error
    state = state.copyWith(query: query, isLoading: true, errorMessage: null);

    try {
      final destRepo = ref.read(destinationRepositoryProvider);
      final reviewRepo = ref.read(reviewRepositoryProvider);

      final queryLower = query.toLowerCase().trim();
      final noDiacriticsQuery = VietnameseTextUtils.removeDiacritics(
        queryLower,
      );

      // Run searches in parallel
      final results = await Future.wait([
        destRepo.getAllDestinations(),
        destRepo.searchLocations(query),
        reviewRepo.searchReviewsByTitle(query),
      ]);

      // ── Destinations (client-side filter) ──
      final allDestinations = results[0] as List<Destination>;
      final matchedDestinations = allDestinations
          .where((d) {
            final nameLower = d.name.toLowerCase();
            final noDiacriticsName = VietnameseTextUtils.removeDiacritics(
              nameLower,
            );
            return nameLower.contains(queryLower) ||
                noDiacriticsName.contains(noDiacriticsQuery);
          })
          .take(_maxResultsPerCategory)
          .toList();

      // ── Locations (server + client-side fallback) ──
      final serverLocations = results[1] as List<Location>;
      List<Location> finalLocations;

      if (serverLocations.length >= _maxResultsPerCategory) {
        // Server returned enough results, just sort & limit
        final sorted = SearchRelevanceScorer.sortByRelevance(
          serverLocations,
          query,
        );
        finalLocations = sorted.take(_maxResultsPerCategory).toList();
      } else {
        // Server returned few results → fallback: fetch all & filter client-side
        final allLocations = await destRepo.getAllLocations();
        final clientMatched = allLocations.where((loc) {
          final nameLower = loc.name.toLowerCase();
          final noDiacriticsName = VietnameseTextUtils.removeDiacritics(
            nameLower,
          );
          final addrLower = (loc.address ?? '').toLowerCase();
          final noDiacriticsAddr = VietnameseTextUtils.removeDiacritics(
            addrLower,
          );
          return nameLower.contains(queryLower) ||
              noDiacriticsName.contains(noDiacriticsQuery) ||
              addrLower.contains(queryLower) ||
              noDiacriticsAddr.contains(noDiacriticsQuery) ||
              loc.matchesSearch(query);
        }).toList();

        // Merge server + client results, deduplicate
        final existingIds = serverLocations.map((l) => l.id).toSet();
        final merged = [...serverLocations];
        for (final loc in clientMatched) {
          if (!existingIds.contains(loc.id)) {
            merged.add(loc);
            existingIds.add(loc.id);
          }
        }

        final sorted = SearchRelevanceScorer.sortByRelevance(merged, query);
        finalLocations = sorted.take(_maxResultsPerCategory).toList();
      }

      // ── Reviews (server + client-side fallback) ──
      final serverReviews = results[2] as List<Review>;
      List<Review> finalReviews;

      if (serverReviews.length >= _maxResultsPerCategory) {
        finalReviews = serverReviews.take(_maxResultsPerCategory).toList();
      } else {
        // Fallback: fetch all & filter client-side
        final allReviews = await reviewRepo.getAllReviews();
        final clientMatched = allReviews.where((r) {
          final titleLower = r.title.toLowerCase();
          final noDiacriticsTitle = VietnameseTextUtils.removeDiacritics(
            titleLower,
          );
          final destName = (r.destinationName ?? '').toLowerCase();
          final noDiacriticsDestName = VietnameseTextUtils.removeDiacritics(
            destName,
          );
          return titleLower.contains(queryLower) ||
              noDiacriticsTitle.contains(noDiacriticsQuery) ||
              destName.contains(queryLower) ||
              noDiacriticsDestName.contains(noDiacriticsQuery);
        }).toList();

        // Merge & deduplicate
        final existingIds = serverReviews.map((r) => r.id).toSet();
        final merged = [...serverReviews];
        for (final r in clientMatched) {
          if (!existingIds.contains(r.id)) {
            merged.add(r);
            existingIds.add(r.id);
          }
        }
        finalReviews = merged.take(_maxResultsPerCategory).toList();
      }

      state = state.copyWith(
        destinations: matchedDestinations,
        locations: finalLocations,
        reviews: finalReviews,
        isLoading: false,
      );
    } catch (e) {
      // AC6: Error handling - set error state and clear results
      state = state.copyWith(
        isLoading: false,
        destinations: [],
        locations: [],
        reviews: [],
        errorMessage: 'Không thể tìm kiếm: ${e.toString()}',
      );
    }
  }

  /// Clear search state
  void clear() {
    state = const LocationSearchState();
  }
}

/// Provider for location search state
final locationSearchProvider =
    NotifierProvider<LocationSearchNotifier, LocationSearchState>(
      LocationSearchNotifier.new,
    );
