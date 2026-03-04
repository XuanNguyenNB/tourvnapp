import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tour_vn/features/home/presentation/providers/home_filter_provider.dart';
import 'package:tour_vn/features/home/presentation/providers/destination_filter_provider.dart';
import 'package:tour_vn/features/home/presentation/providers/category_filter_provider.dart';
import 'package:tour_vn/features/home/domain/entities/content_item.dart';
import 'package:tour_vn/features/home/domain/entities/destination_preview.dart';
import 'package:tour_vn/features/home/domain/entities/review_preview.dart';

/// Integration tests for HomeFilterProvider with content filtering.
///
/// Story 8-9: Verifies combined filter behavior.
///
/// Note: These tests use mock data directly instead of filteredHomeContentProvider
/// to avoid async dependency issues in unit tests.
void main() {
  // Mock content for testing
  final testContent = <ContentItem>[
    // Destinations
    const DestinationContent(
      DestinationPreview(
        id: 'da-nang',
        name: 'Đà Nẵng',
        heroImage: 'https://example.com/danang.jpg',
        engagementCount: 1000,
      ),
    ),
    const DestinationContent(
      DestinationPreview(
        id: 'da-lat',
        name: 'Đà Lạt',
        heroImage: 'https://example.com/dalat.jpg',
        engagementCount: 1500,
      ),
    ),
    const DestinationContent(
      DestinationPreview(
        id: 'phu-quoc',
        name: 'Phú Quốc',
        heroImage: 'https://example.com/phuquoc.jpg',
        engagementCount: 1200,
      ),
    ),
    // Reviews
    const ReviewContent(
      ReviewPreview(
        title: 'Test Review',
        id: 'review-1',
        authorName: 'User 1',
        authorAvatar: 'https://example.com/avatar.jpg',
        shortText: 'Great food in Da Lat!',
        likeCount: 100,
        commentCount: 10,
        destinationId: 'da-lat',
        destinationName: 'Đà Lạt',
        category: 'food',
      ),
    ),
    const ReviewContent(
      ReviewPreview(
        title: 'Test Review',
        id: 'review-2',
        authorName: 'User 2',
        authorAvatar: 'https://example.com/avatar.jpg',
        shortText: 'Nice food in Da Nang!',
        likeCount: 150,
        commentCount: 15,
        destinationId: 'da-nang',
        destinationName: 'Đà Nẵng',
        category: 'food',
      ),
    ),
    const ReviewContent(
      ReviewPreview(
        title: 'Test Review',
        id: 'review-3',
        authorName: 'User 3',
        authorAvatar: 'https://example.com/avatar.jpg',
        shortText: 'Beautiful places in Da Nang!',
        likeCount: 200,
        commentCount: 20,
        destinationId: 'da-nang',
        destinationName: 'Đà Nẵng',
        category: 'places',
      ),
    ),
    const ReviewContent(
      ReviewPreview(
        title: 'Test Review',
        id: 'review-4',
        authorName: 'User 4',
        authorAvatar: 'https://example.com/avatar.jpg',
        shortText: 'Nice stay in Phu Quoc!',
        likeCount: 180,
        commentCount: 18,
        destinationId: 'phu-quoc',
        destinationName: 'Phú Quốc',
        category: 'stay',
      ),
    ),
  ];

  group('FilteredHomeContent Integration', () {
    test('should return all content when no filters are active', () {
      // Arrange
      const state = HomeFilterState();

      // Act
      final result = testContent.where(state.matchesFilter).toList();

      // Assert - should have all items
      expect(result.length, equals(testContent.length));
      // Should include both destinations and reviews
      expect(result.whereType<DestinationContent>().length, equals(3));
      expect(result.whereType<ReviewContent>().length, equals(4));
    });

    test('should filter content by destination when destination selected', () {
      // Arrange
      const state = HomeFilterState(selectedDestinationId: 'da-nang');

      // Act
      final result = testContent.where(state.matchesFilter).toList();

      // Assert - should only show content matching da-nang
      expect(result.length, equals(3)); // 1 destination + 2 reviews

      for (final item in result) {
        switch (item) {
          case DestinationContent(:final destination):
            expect(destination.id, equals('da-nang'));
          case ReviewContent(:final review):
            expect(review.destinationId, equals('da-nang'));
        }
      }
    });

    test('should filter content by category when category selected', () {
      // Arrange
      const state = HomeFilterState(selectedCategoryId: 'food');

      // Act
      final result = testContent.where(state.matchesFilter).toList();

      // Assert - should only show reviews with food category
      // (destinations are hidden when only category filter is active)
      expect(result.whereType<DestinationContent>(), isEmpty);

      // Only food reviews
      expect(result.length, equals(2));
      for (final item in result) {
        if (item is ReviewContent) {
          expect(item.review.category, equals('food'));
        }
      }
    });

    test('should apply AND logic when both filters are active', () {
      // Arrange
      const state = HomeFilterState(
        selectedDestinationId: 'da-nang',
        selectedCategoryId: 'food',
      );

      // Act
      final result = testContent.where(state.matchesFilter).toList();

      // Assert
      // Destinations should be hidden
      expect(result.whereType<DestinationContent>(), isEmpty);

      // Only food reviews in Da Nang (review-2)
      expect(result.length, equals(1));
      expect((result.first as ReviewContent).review.id, equals('review-2'));
    });

    test('should show all content when filters are cleared', () {
      // Arrange - start with filters
      const filteredState = HomeFilterState(
        selectedDestinationId: 'da-nang',
        selectedCategoryId: 'food',
      );
      final filteredResult = testContent
          .where(filteredState.matchesFilter)
          .toList();

      // Clear filters
      const clearedState = HomeFilterState();
      final allResult = testContent.where(clearedState.matchesFilter).toList();

      // Assert - should have more content than filtered
      expect(allResult.length, greaterThan(filteredResult.length));
      expect(allResult.length, equals(testContent.length));
    });

    test('should filter Da Lat food correctly', () {
      // Arrange
      const state = HomeFilterState(
        selectedDestinationId: 'da-lat',
        selectedCategoryId: 'food',
      );

      // Act
      final result = testContent.where(state.matchesFilter).toList();

      // Assert - should only get review-1 (food in Da Lat)
      expect(result.length, equals(1));
      expect((result.first as ReviewContent).review.id, equals('review-1'));
    });

    test('should filter Phu Quoc stay correctly', () {
      // Arrange
      const state = HomeFilterState(
        selectedDestinationId: 'phu-quoc',
        selectedCategoryId: 'stay',
      );

      // Act
      final result = testContent.where(state.matchesFilter).toList();

      // Assert - should only get review-4 (stay in Phu Quoc)
      expect(result.length, equals(1));
      expect((result.first as ReviewContent).review.id, equals('review-4'));
    });

    test('should return empty when no content matches combined filter', () {
      // Arrange - no food in Phu Quoc
      const state = HomeFilterState(
        selectedDestinationId: 'phu-quoc',
        selectedCategoryId: 'food',
      );

      // Act
      final result = testContent.where(state.matchesFilter).toList();

      // Assert - no matches
      expect(result, isEmpty);
    });
  });

  group('Filter Reactivity with ProviderContainer', () {
    test('homeFilterProvider should react to destination changes', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial state
      var state = container.read(homeFilterProvider);
      expect(state.hasDestinationFilter, isFalse);

      // Act
      container
          .read(destinationFilterProvider.notifier)
          .selectDestination('da-nang', 'Đà Nẵng');

      // Read again (should rebuild due to watch)
      state = container.read(homeFilterProvider);

      // Assert
      expect(state.hasDestinationFilter, isTrue);
      expect(state.selectedDestinationId, 'da-nang');
    });

    test('homeFilterProvider should react to category changes', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial state
      var state = container.read(homeFilterProvider);
      expect(state.hasCategoryFilter, isFalse);

      // Act
      container
          .read(categoryFilterProvider.notifier)
          .selectCategory('places', 'Điểm đến');

      // Read again (should rebuild due to watch)
      state = container.read(homeFilterProvider);

      // Assert
      expect(state.hasCategoryFilter, isTrue);
      expect(state.selectedCategoryId, 'places');
    });

    test('toggle destination should update filter state', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // First toggle - should select
      container
          .read(destinationFilterProvider.notifier)
          .toggleDestination('da-nang', 'Đà Nẵng');

      var state = container.read(homeFilterProvider);
      expect(state.selectedDestinationId, 'da-nang');

      // Second toggle - should deselect
      container
          .read(destinationFilterProvider.notifier)
          .toggleDestination('da-nang', 'Đà Nẵng');

      state = container.read(homeFilterProvider);
      expect(state.selectedDestinationId, isNull);
    });

    test('toggle category should update filter state', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // First toggle - should select
      container
          .read(categoryFilterProvider.notifier)
          .toggleCategory('food', 'Ăn uống');

      var state = container.read(homeFilterProvider);
      expect(state.selectedCategoryId, 'food');

      // Second toggle - should deselect
      container
          .read(categoryFilterProvider.notifier)
          .toggleCategory('food', 'Ăn uống');

      state = container.read(homeFilterProvider);
      expect(state.selectedCategoryId, isNull);
    });

    test('combined filter updates correctly', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set both filters
      container
          .read(destinationFilterProvider.notifier)
          .selectDestination('da-nang', 'Đà Nẵng');
      container
          .read(categoryFilterProvider.notifier)
          .selectCategory('food', 'Ăn uống');

      // Read combined state
      final state = container.read(homeFilterProvider);

      // Assert
      expect(state.selectedDestinationId, 'da-nang');
      expect(state.selectedCategoryId, 'food');
      expect(state.hasFilters, isTrue);
      expect(state.hasDestinationFilter, isTrue);
      expect(state.hasCategoryFilter, isTrue);

      // Filter content
      final filtered = testContent.where(state.matchesFilter).toList();
      expect(filtered.length, equals(1));
      expect((filtered.first as ReviewContent).review.id, equals('review-2'));
    });
  });
}
