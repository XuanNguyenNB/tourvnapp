import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';
import 'package:tour_vn/features/home/presentation/providers/location_search_provider.dart';

/// Helper to create mock Location for testing state
Location _createMockLocation(String id, {int viewCount = 0}) {
  return Location(
    id: id,
    destinationId: 'da-nang',
    name: 'Test Location $id',
    image: 'https://example.com/image.jpg',
    category: 'food',
    viewCount: viewCount,
  );
}

void main() {
  group('LocationSearchState', () {
    test('should have default empty state', () {
      const state = LocationSearchState();

      expect(state.query, equals(''));
      expect(state.destinations, isEmpty);
      expect(state.locations, isEmpty);
      expect(state.reviews, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('hasResults should return true when results exist', () {
      final state = LocationSearchState(
        locations: [_createMockLocation('loc-1')],
      );

      expect(state.hasResults, isTrue);
    });

    test('hasResults should return false when results empty', () {
      const state = LocationSearchState(locations: []);

      expect(state.hasResults, isFalse);
    });

    test('isEmpty should return true when query is empty', () {
      const state = LocationSearchState(query: '');

      expect(state.isEmpty, isTrue);
    });

    test('isEmpty should return false when query has value', () {
      const state = LocationSearchState(query: 'bánh mì');

      expect(state.isEmpty, isFalse);
    });

    test('hasError should return true when errorMessage is set', () {
      const state = LocationSearchState(errorMessage: 'Error occurred');

      expect(state.hasError, isTrue);
    });

    test('hasError should return false when errorMessage is null', () {
      const state = LocationSearchState();

      expect(state.hasError, isFalse);
    });

    test('copyWith should preserve existing values', () {
      const original = LocationSearchState(query: 'test', isLoading: true);

      final copied = original.copyWith(isLoading: false);

      expect(copied.query, equals('test'));
      expect(copied.isLoading, isFalse);
    });

    test('copyWith should clear errorMessage when passing null', () {
      const original = LocationSearchState(errorMessage: 'Error');

      final copied = original.copyWith(errorMessage: null);

      expect(copied.errorMessage, isNull);
    });
  });

  group('LocationSearchNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should have initial empty state', () {
      final state = container.read(locationSearchProvider);

      expect(state.query, equals(''));
      expect(state.destinations, isEmpty);
      expect(state.locations, isEmpty);
      expect(state.reviews, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('search with empty query should clear results (AC5)', () async {
      final notifier = container.read(locationSearchProvider.notifier);

      await notifier.search('');

      final state = container.read(locationSearchProvider);
      expect(state.query, equals(''));
      expect(state.destinations, isEmpty);
      expect(state.locations, isEmpty);
      expect(state.reviews, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('search should set loading state initially', () async {
      final notifier = container.read(locationSearchProvider.notifier);

      // Don't await to check loading state
      final searchFuture = notifier.search('test');

      // Initially should be loading
      final loadingState = container.read(locationSearchProvider);
      expect(loadingState.isLoading, isTrue);

      await searchFuture;
    });

    test('search should complete with isLoading false', () async {
      final notifier = container.read(locationSearchProvider.notifier);

      await notifier.search('bánh');

      final state = container.read(locationSearchProvider);
      expect(state.isLoading, isFalse);
      expect(state.query, equals('bánh'));
    });

    test('search should return matching results', () async {
      final notifier = container.read(locationSearchProvider.notifier);

      // Search for "bánh" which should match "Bánh Mì Phượng" etc.
      await notifier.search('bánh');

      final state = container.read(locationSearchProvider);

      // Should have results matching "bánh"
      expect(state.locations.isNotEmpty, isTrue);
      expect(
        state.locations.any((loc) => loc.name.toLowerCase().contains('bánh')),
        isTrue,
      );
    });

    test('search should limit results to maximum 10 (AC4)', () async {
      final notifier = container.read(locationSearchProvider.notifier);

      // Search for a common term that might match many locations
      await notifier.search('');
      notifier.clear();

      // Try a broad search
      await notifier.search('a'); // Should match many locations

      final state = container.read(locationSearchProvider);

      // Results should not exceed 5 per category
      expect(state.locations.length, lessThanOrEqualTo(5));
    });

    test('search should sort results by relevance (AC3)', () async {
      final notifier = container.read(locationSearchProvider.notifier);

      // Search for something specific
      await notifier.search('Bánh');

      final state = container.read(locationSearchProvider);

      if (state.locations.length > 1) {
        // Results starting with the search term should come before those just containing it
        final startsWithQuery = state.locations.where(
          (loc) => loc.name.toLowerCase().startsWith('bánh'),
        );

        // If there are exact/prefix matches, they should appear first
        if (startsWithQuery.isNotEmpty) {
          final firstResult = state.locations.first;
          expect(
            firstResult.name.toLowerCase().startsWith('bánh'),
            isTrue,
            reason: 'First result should start with search query',
          );
        }
      }
    });

    test('clear should reset to initial state', () async {
      final notifier = container.read(locationSearchProvider.notifier);

      // First search
      await notifier.search('test');

      // Then clear
      notifier.clear();

      final state = container.read(locationSearchProvider);
      expect(state.query, equals(''));
      expect(state.destinations, isEmpty);
      expect(state.locations, isEmpty);
      expect(state.reviews, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('search should update query', () async {
      final notifier = container.read(locationSearchProvider.notifier);

      await notifier.search('đà nẵng');

      final state = container.read(locationSearchProvider);
      expect(state.query, equals('đà nẵng'));
    });

    test('search should match Vietnamese without diacritics (AC7)', () async {
      final notifier = container.read(locationSearchProvider.notifier);

      // Search without diacritics
      await notifier.search('da nang');

      final state = container.read(locationSearchProvider);

      // Should find locations in Đà Nẵng
      expect(
        state.locations.any(
          (loc) =>
              loc.destinationName?.toLowerCase().contains('đà nẵng') == true ||
              loc.destinationId == 'da-nang',
        ),
        isTrue,
        reason: 'Should match "Đà Nẵng" when searching for "da nang"',
      );
    });

    test('search should clear previous error on new search', () async {
      final notifier = container.read(locationSearchProvider.notifier);

      // Simulate a search
      await notifier.search('test1');

      // Perform another search
      await notifier.search('test2');

      final state = container.read(locationSearchProvider);
      expect(state.errorMessage, isNull);
    });
  });

  group('destinationRepositoryProvider', () {
    test('should provide a DestinationRepository instance', () {
      final container = ProviderContainer();

      final repository = container.read(destinationRepositoryProvider);

      expect(repository, isNotNull);
      container.dispose();
    });
  });
}
