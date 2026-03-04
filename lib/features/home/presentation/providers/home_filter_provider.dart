import 'package:flutter_riverpod/flutter_riverpod.dart';

import './destination_filter_provider.dart';
import './category_filter_provider.dart';
import '../../domain/entities/content_item.dart';

/// Combined filter state for home feed filtering.
///
/// Story 8-9: Combines destination and category filters with AND logic.
/// Provides helper methods for filtering ContentItem collections.
///
/// Used by [filteredHomeContentProvider] to apply filters to the feed.
class HomeFilterState {
  /// Selected destination ID, or null if no destination filter.
  final String? selectedDestinationId;

  /// Selected category ID, or null if no category filter.
  final String? selectedCategoryId;

  /// Creates a HomeFilterState instance.
  const HomeFilterState({this.selectedDestinationId, this.selectedCategoryId});

  /// Whether any filter is active.
  bool get hasFilters =>
      selectedDestinationId != null || selectedCategoryId != null;

  /// Whether destination filter is active.
  bool get hasDestinationFilter => selectedDestinationId != null;

  /// Whether category filter is active.
  bool get hasCategoryFilter => selectedCategoryId != null;

  /// Check if a content item matches the current filters.
  ///
  /// Uses AND logic: if both filters are active, item must match both.
  ///
  /// Filtering logic:
  /// - If only destination filter: Show destinations AND reviews matching destination
  /// - If only category filter: Show ONLY reviews with matching category (hide destinations)
  /// - If both filters: Show ONLY reviews matching both (hide destinations)
  bool matchesFilter(ContentItem item) {
    // Extract item properties based on type using Dart 3 pattern matching
    final String? itemDestinationId;
    final String? itemCategory;

    switch (item) {
      case DestinationContent(:final destination):
        // DestinationPreview uses `id` as destinationId
        itemDestinationId = destination.id;
        itemCategory = null; // Destinations don't have category
      case ReviewContent(:final review):
        itemDestinationId = review.destinationId;
        itemCategory = review.category;
    }

    // If only category filter is active, hide DestinationContent
    // (destinations don't have category field)
    if (hasCategoryFilter && !hasDestinationFilter) {
      if (item is DestinationContent) {
        return false;
      }
    }

    // If both filters are active, only show ReviewContent that matches both
    if (hasDestinationFilter && hasCategoryFilter) {
      if (item is DestinationContent) {
        return false; // Hide destinations when both filters active
      }
    }

    // Check destination filter
    if (hasDestinationFilter) {
      if (itemDestinationId != selectedDestinationId) {
        return false;
      }
    }

    // Check category filter (only applies to ReviewContent with category)
    if (hasCategoryFilter && itemCategory != null) {
      if (itemCategory != selectedCategoryId) {
        return false;
      }
    }

    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HomeFilterState &&
        other.selectedDestinationId == selectedDestinationId &&
        other.selectedCategoryId == selectedCategoryId;
  }

  @override
  int get hashCode =>
      selectedDestinationId.hashCode ^ selectedCategoryId.hashCode;

  @override
  String toString() {
    return 'HomeFilterState('
        'destinationId: $selectedDestinationId, '
        'categoryId: $selectedCategoryId)';
  }
}

/// Provider that combines destination and category filter states.
///
/// Story 8-9: Used by filteredHomeContentProvider for feed filtering.
/// Watches both filter providers for reactive updates.
///
/// Usage:
/// ```dart
/// final filterState = ref.watch(homeFilterProvider);
/// final filteredContent = content.where(filterState.matchesFilter).toList();
/// ```
final homeFilterProvider = Provider<HomeFilterState>((ref) {
  // Watch convenience providers for efficient reactivity
  final destinationId = ref.watch(selectedDestinationIdProvider);
  final categoryId = ref.watch(selectedCategoryIdProvider);

  return HomeFilterState(
    selectedDestinationId: destinationId,
    selectedCategoryId: categoryId,
  );
});

/// Convenience provider to check if any filters are active.
///
/// More efficient for widgets that only need to know if filtering is applied.
final hasActiveFiltersProvider = Provider<bool>((ref) {
  return ref.watch(homeFilterProvider.select((state) => state.hasFilters));
});
