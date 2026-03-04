import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tour_vn/features/home/presentation/providers/home_filter_provider.dart';
import 'package:tour_vn/features/home/presentation/providers/destination_filter_provider.dart';
import 'package:tour_vn/features/home/presentation/providers/category_filter_provider.dart';
import 'package:tour_vn/features/home/domain/entities/content_item.dart';
import 'package:tour_vn/features/home/domain/entities/destination_preview.dart';
import 'package:tour_vn/features/home/domain/entities/review_preview.dart';

void main() {
  group('HomeFilterState', () {
    group('construction and properties', () {
      test('should create with null values by default', () {
        // Arrange & Act
        const state = HomeFilterState();

        // Assert
        expect(state.selectedDestinationId, isNull);
        expect(state.selectedCategoryId, isNull);
      });

      test('should create with provided values', () {
        // Arrange & Act
        const state = HomeFilterState(
          selectedDestinationId: 'da-nang',
          selectedCategoryId: 'food',
        );

        // Assert
        expect(state.selectedDestinationId, 'da-nang');
        expect(state.selectedCategoryId, 'food');
      });
    });

    group('hasFilters', () {
      test('should return false when no filters are set', () {
        // Arrange
        const state = HomeFilterState();

        // Assert
        expect(state.hasFilters, isFalse);
      });

      test('should return true when destination filter is set', () {
        // Arrange
        const state = HomeFilterState(selectedDestinationId: 'da-nang');

        // Assert
        expect(state.hasFilters, isTrue);
      });

      test('should return true when category filter is set', () {
        // Arrange
        const state = HomeFilterState(selectedCategoryId: 'food');

        // Assert
        expect(state.hasFilters, isTrue);
      });

      test('should return true when both filters are set', () {
        // Arrange
        const state = HomeFilterState(
          selectedDestinationId: 'da-nang',
          selectedCategoryId: 'food',
        );

        // Assert
        expect(state.hasFilters, isTrue);
      });
    });

    group('hasDestinationFilter', () {
      test('should return false when destination is null', () {
        // Arrange
        const state = HomeFilterState();

        // Assert
        expect(state.hasDestinationFilter, isFalse);
      });

      test('should return true when destination is set', () {
        // Arrange
        const state = HomeFilterState(selectedDestinationId: 'da-nang');

        // Assert
        expect(state.hasDestinationFilter, isTrue);
      });
    });

    group('hasCategoryFilter', () {
      test('should return false when category is null', () {
        // Arrange
        const state = HomeFilterState();

        // Assert
        expect(state.hasCategoryFilter, isFalse);
      });

      test('should return true when category is set', () {
        // Arrange
        const state = HomeFilterState(selectedCategoryId: 'food');

        // Assert
        expect(state.hasCategoryFilter, isTrue);
      });
    });

    group('equality and hashCode', () {
      test('should be equal when both values are same', () {
        // Arrange
        const state1 = HomeFilterState(
          selectedDestinationId: 'da-nang',
          selectedCategoryId: 'food',
        );
        const state2 = HomeFilterState(
          selectedDestinationId: 'da-nang',
          selectedCategoryId: 'food',
        );

        // Assert
        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('should not be equal when values differ', () {
        // Arrange
        const state1 = HomeFilterState(selectedDestinationId: 'da-nang');
        const state2 = HomeFilterState(selectedDestinationId: 'da-lat');

        // Assert
        expect(state1, isNot(equals(state2)));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        // Arrange
        const state = HomeFilterState(
          selectedDestinationId: 'da-nang',
          selectedCategoryId: 'food',
        );

        // Act
        final result = state.toString();

        // Assert
        expect(result, contains('destinationId: da-nang'));
        expect(result, contains('categoryId: food'));
      });
    });
  });

  group('HomeFilterState.matchesFilter', () {
    // Test data
    const destinationDaNang = DestinationPreview(
      id: 'da-nang',
      name: 'Đà Nẵng',
      heroImage: 'https://example.com/danang.jpg',
      engagementCount: 1000,
    );

    const destinationDaLat = DestinationPreview(
      id: 'da-lat',
      name: 'Đà Lạt',
      heroImage: 'https://example.com/dalat.jpg',
      engagementCount: 1500,
    );

    const reviewFoodDaNang = ReviewPreview(
      title: 'Test Review',
      id: 'review-1',
      authorName: 'Test User',
      authorAvatar: 'https://example.com/avatar.jpg',
      shortText: 'Great food!',
      likeCount: 100,
      commentCount: 10,
      destinationId: 'da-nang',
      destinationName: 'Đà Nẵng',
      category: 'food',
    );

    const reviewPlacesDaNang = ReviewPreview(
      id: 'review-2',
      authorName: 'Test User 2',
      authorAvatar: 'https://example.com/avatar2.jpg',
      shortText: 'Nice places!',
      likeCount: 200,
      commentCount: 20,
      destinationId: 'da-nang',
      destinationName: 'Đà Nẵng',
      category: 'places',
    );

    const reviewFoodDaLat = ReviewPreview(
      id: 'review-3',
      authorName: 'Test User 3',
      authorAvatar: 'https://example.com/avatar3.jpg',
      shortText: 'Dalat food!',
      likeCount: 150,
      commentCount: 15,
      destinationId: 'da-lat',
      destinationName: 'Đà Lạt',
      category: 'food',
    );

    const reviewWithoutCategory = ReviewPreview(
      id: 'review-4',
      authorName: 'Test User 4',
      authorAvatar: 'https://example.com/avatar4.jpg',
      shortText: 'No category!',
      likeCount: 50,
      commentCount: 5,
      destinationId: 'da-nang',
      destinationName: 'Đà Nẵng',
      category: null,
    );

    group('no filters', () {
      test('should match all content when no filters active', () {
        // Arrange
        const state = HomeFilterState();

        // Assert
        expect(
          state.matchesFilter(DestinationContent(destinationDaNang)),
          isTrue,
        );
        expect(
          state.matchesFilter(DestinationContent(destinationDaLat)),
          isTrue,
        );
        expect(state.matchesFilter(ReviewContent(reviewFoodDaNang)), isTrue);
        expect(state.matchesFilter(ReviewContent(reviewPlacesDaNang)), isTrue);
        expect(state.matchesFilter(ReviewContent(reviewFoodDaLat)), isTrue);
      });
    });

    group('destination filter only', () {
      test('should match destination with same id', () {
        // Arrange
        const state = HomeFilterState(selectedDestinationId: 'da-nang');

        // Assert
        expect(
          state.matchesFilter(DestinationContent(destinationDaNang)),
          isTrue,
        );
      });

      test('should not match destination with different id', () {
        // Arrange
        const state = HomeFilterState(selectedDestinationId: 'da-nang');

        // Assert
        expect(
          state.matchesFilter(DestinationContent(destinationDaLat)),
          isFalse,
        );
      });

      test('should match review with matching destinationId', () {
        // Arrange
        const state = HomeFilterState(selectedDestinationId: 'da-nang');

        // Assert
        expect(state.matchesFilter(ReviewContent(reviewFoodDaNang)), isTrue);
        expect(state.matchesFilter(ReviewContent(reviewPlacesDaNang)), isTrue);
      });

      test('should not match review with different destinationId', () {
        // Arrange
        const state = HomeFilterState(selectedDestinationId: 'da-nang');

        // Assert
        expect(state.matchesFilter(ReviewContent(reviewFoodDaLat)), isFalse);
      });
    });

    group('category filter only', () {
      test('should hide destinations when only category filter active', () {
        // Arrange
        const state = HomeFilterState(selectedCategoryId: 'food');

        // Assert - destinations should be hidden
        expect(
          state.matchesFilter(DestinationContent(destinationDaNang)),
          isFalse,
        );
        expect(
          state.matchesFilter(DestinationContent(destinationDaLat)),
          isFalse,
        );
      });

      test('should match reviews with matching category', () {
        // Arrange
        const state = HomeFilterState(selectedCategoryId: 'food');

        // Assert
        expect(state.matchesFilter(ReviewContent(reviewFoodDaNang)), isTrue);
        expect(state.matchesFilter(ReviewContent(reviewFoodDaLat)), isTrue);
      });

      test('should not match reviews with different category', () {
        // Arrange
        const state = HomeFilterState(selectedCategoryId: 'food');

        // Assert
        expect(state.matchesFilter(ReviewContent(reviewPlacesDaNang)), isFalse);
      });

      test('should handle reviews without category', () {
        // Arrange
        const state = HomeFilterState(selectedCategoryId: 'food');

        // Assert - reviews without category should still match
        // (null category means category filter doesn't apply)
        expect(
          state.matchesFilter(ReviewContent(reviewWithoutCategory)),
          isTrue,
        );
      });
    });

    group('combined filters (AND logic)', () {
      test('should hide destinations when both filters active', () {
        // Arrange
        const state = HomeFilterState(
          selectedDestinationId: 'da-nang',
          selectedCategoryId: 'food',
        );

        // Assert - destinations should be hidden
        expect(
          state.matchesFilter(DestinationContent(destinationDaNang)),
          isFalse,
        );
      });

      test('should match only reviews matching BOTH filters', () {
        // Arrange
        const state = HomeFilterState(
          selectedDestinationId: 'da-nang',
          selectedCategoryId: 'food',
        );

        // Assert
        // Food in Da Nang - should match
        expect(state.matchesFilter(ReviewContent(reviewFoodDaNang)), isTrue);

        // Places in Da Nang - wrong category
        expect(state.matchesFilter(ReviewContent(reviewPlacesDaNang)), isFalse);

        // Food in Da Lat - wrong destination
        expect(state.matchesFilter(ReviewContent(reviewFoodDaLat)), isFalse);
      });

      test('should apply correct AND logic for multiple combinations', () {
        // Arrange
        const state = HomeFilterState(
          selectedDestinationId: 'da-lat',
          selectedCategoryId: 'food',
        );

        // Assert
        // Food in Da Lat - should match both
        expect(state.matchesFilter(ReviewContent(reviewFoodDaLat)), isTrue);

        // Food in Da Nang - wrong destination
        expect(state.matchesFilter(ReviewContent(reviewFoodDaNang)), isFalse);

        // Places in Da Nang - wrong destination AND wrong category
        expect(state.matchesFilter(ReviewContent(reviewPlacesDaNang)), isFalse);
      });
    });
  });

  group('HomeFilterProvider', () {
    test('should return empty filter state when no filters selected', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      final state = container.read(homeFilterProvider);

      // Assert
      expect(state.selectedDestinationId, isNull);
      expect(state.selectedCategoryId, isNull);
      expect(state.hasFilters, isFalse);
    });

    test('should update when destination filter changes', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act - select destination
      container
          .read(destinationFilterProvider.notifier)
          .selectDestination('da-nang', 'Đà Nẵng');

      // Assert
      final state = container.read(homeFilterProvider);
      expect(state.selectedDestinationId, 'da-nang');
      expect(state.hasDestinationFilter, isTrue);
    });

    test('should update when category filter changes', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act - select category
      container
          .read(categoryFilterProvider.notifier)
          .selectCategory('food', 'Ăn uống');

      // Assert
      final state = container.read(homeFilterProvider);
      expect(state.selectedCategoryId, 'food');
      expect(state.hasCategoryFilter, isTrue);
    });

    test('should combine both filters reactively', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act - select both
      container
          .read(destinationFilterProvider.notifier)
          .selectDestination('da-nang', 'Đà Nẵng');
      container
          .read(categoryFilterProvider.notifier)
          .selectCategory('food', 'Ăn uống');

      // Assert
      final state = container.read(homeFilterProvider);
      expect(state.selectedDestinationId, 'da-nang');
      expect(state.selectedCategoryId, 'food');
      expect(state.hasFilters, isTrue);
    });

    test('should clear when filters are cleared', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Select filters first
      container
          .read(destinationFilterProvider.notifier)
          .selectDestination('da-nang', 'Đà Nẵng');
      container
          .read(categoryFilterProvider.notifier)
          .selectCategory('food', 'Ăn uống');

      // Act - clear filters
      container.read(destinationFilterProvider.notifier).clearSelection();
      container.read(categoryFilterProvider.notifier).clearSelection();

      // Assert
      final state = container.read(homeFilterProvider);
      expect(state.hasFilters, isFalse);
    });
  });

  group('hasActiveFiltersProvider', () {
    test('should return false when no filters active', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      final hasFilters = container.read(hasActiveFiltersProvider);

      // Assert
      expect(hasFilters, isFalse);
    });

    test('should return true when destination filter is active', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      container
          .read(destinationFilterProvider.notifier)
          .selectDestination('da-nang', 'Đà Nẵng');

      // Assert
      final hasFilters = container.read(hasActiveFiltersProvider);
      expect(hasFilters, isTrue);
    });

    test('should return true when category filter is active', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      container
          .read(categoryFilterProvider.notifier)
          .selectCategory('food', 'Ăn uống');

      // Assert
      final hasFilters = container.read(hasActiveFiltersProvider);
      expect(hasFilters, isTrue);
    });
  });
}
