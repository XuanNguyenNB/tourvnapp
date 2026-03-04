import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for category filter selection on Home Screen.
///
/// Story 8-8: Tracks which category chip is selected for filtering.
/// Used by CategoryChipsRow and consumed by HomeFilterProvider (Story 8-9).
///
/// Similar pattern to DestinationFilterState (Story 8-7) for consistency.
class CategoryFilterState {
  /// The ID of the currently selected category, or null if none.
  final String? selectedCategoryId;

  /// The name of the currently selected category, or null if none.
  final String? selectedCategoryName;

  /// Creates a CategoryFilterState.
  const CategoryFilterState({
    this.selectedCategoryId,
    this.selectedCategoryName,
  });

  /// Whether a category is currently selected.
  bool get hasSelection => selectedCategoryId != null;

  /// Check if a specific category ID is selected.
  bool isSelected(String categoryId) {
    return selectedCategoryId == categoryId;
  }

  /// Creates a copy with modified fields (immutability pattern).
  CategoryFilterState copyWith({
    String? selectedCategoryId,
    String? selectedCategoryName,
    bool clearSelection = false,
  }) {
    if (clearSelection) {
      return const CategoryFilterState();
    }
    return CategoryFilterState(
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedCategoryName: selectedCategoryName ?? this.selectedCategoryName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryFilterState &&
        other.selectedCategoryId == selectedCategoryId &&
        other.selectedCategoryName == selectedCategoryName;
  }

  @override
  int get hashCode =>
      selectedCategoryId.hashCode ^ selectedCategoryName.hashCode;

  @override
  String toString() {
    return 'CategoryFilterState('
        'selectedCategoryId: $selectedCategoryId, '
        'selectedCategoryName: $selectedCategoryName)';
  }
}

/// Notifier for managing category filter state.
///
/// Provides methods to select, deselect, and toggle categories.
/// Single selection mode: selecting a new category deselects the previous one.
class CategoryFilterNotifier extends Notifier<CategoryFilterState> {
  @override
  CategoryFilterState build() => const CategoryFilterState();

  /// Select a category for filtering.
  ///
  /// Replaces any previously selected category (single selection mode).
  void selectCategory(String id, String name) {
    state = CategoryFilterState(
      selectedCategoryId: id,
      selectedCategoryName: name,
    );
  }

  /// Clear the current selection.
  void clearSelection() {
    state = const CategoryFilterState();
  }

  /// Toggle a category: deselect if currently selected, select otherwise.
  ///
  /// [id] The category ID to toggle
  /// [name] The display name of the category
  void toggleCategory(String id, String name) {
    if (state.selectedCategoryId == id) {
      clearSelection();
    } else {
      selectCategory(id, name);
    }
  }
}

/// Provider for category filter state.
///
/// Usage:
/// ```dart
/// // Watch the state
/// final filterState = ref.watch(categoryFilterProvider);
///
/// // Toggle selection
/// ref.read(categoryFilterProvider.notifier).toggleCategory('food', 'Ăn uống');
///
/// // Check selection
/// final isSelected = filterState.isSelected('food');
/// ```
final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, CategoryFilterState>(
      CategoryFilterNotifier.new,
    );

/// Convenience provider for just the selected category ID.
///
/// More efficient for widgets that only need to know the selection.
final selectedCategoryIdProvider = Provider<String?>((ref) {
  return ref.watch(
    categoryFilterProvider.select((state) => state.selectedCategoryId),
  );
});

/// Convenience provider for just the selected category name.
final selectedCategoryNameProvider = Provider<String?>((ref) {
  return ref.watch(
    categoryFilterProvider.select((state) => state.selectedCategoryName),
  );
});
