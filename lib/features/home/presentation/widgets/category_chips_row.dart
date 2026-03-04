import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/utils/category_filter_helper.dart';
import '../providers/category_filter_provider.dart';
import 'category_chip.dart';

/// A horizontally scrollable row of category filter chips.
///
/// Story 8-8: Renders category chips below the Destination Pills on Home Screen.
/// Each chip represents a category (Food, Cafe, Places, Stay) and tapping
/// toggles the filter selection.
///
/// Unlike DestinationPillsRow, categories are static (not from Firestore),
/// so no loading or error states are needed.
///
/// Layout specifications:
/// - Position: Below DestinationPillsRow, 8px gap
/// - Horizontal padding: 16px from screen edges
/// - Spacing between chips: 8px
/// - Scroll physics: BouncingScrollPhysics
///
/// Example integration in HomeScreen:
/// ```dart
/// Column(
///   children: [
///     SearchBarWidget(...),
///     const SizedBox(height: 8),
///     DestinationPillsRow(),
///     const SizedBox(height: 8),
///     CategoryChipsRow(), // THIS WIDGET
///   ],
/// )
/// ```
class CategoryChipsRow extends ConsumerWidget {
  /// Creates a CategoryChipsRow widget.
  const CategoryChipsRow({super.key});

  /// Fixed height for vertical layout consistency
  static const _rowHeight = 40.0;

  /// Horizontal padding from screen edges
  static const _horizontalPadding = 16.0;

  /// Spacing between chips
  static const _chipSpacing = 8.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(categoryFilterProvider);
    final categories = CategoryFilterHelper.categories;

    return SizedBox(
      height: _rowHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
        child: Row(children: _buildChips(ref, categories, filterState)),
      ),
    );
  }

  /// Build list of category chips with proper spacing.
  List<Widget> _buildChips(
    WidgetRef ref,
    List<CategoryData> categories,
    CategoryFilterState filterState,
  ) {
    return categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final isLast = index == categories.length - 1;

      return Padding(
        padding: EdgeInsets.only(right: isLast ? 0 : _chipSpacing),
        child: CategoryChip(
          categoryId: category.id,
          categoryName: category.name,
          isSelected: filterState.isSelected(category.id),
          onTap: () => _handleChipTap(ref, category),
        ),
      );
    }).toList();
  }

  /// Handle chip tap to toggle category filter.
  void _handleChipTap(WidgetRef ref, CategoryData category) {
    ref
        .read(categoryFilterProvider.notifier)
        .toggleCategory(category.id, category.name);
  }
}
