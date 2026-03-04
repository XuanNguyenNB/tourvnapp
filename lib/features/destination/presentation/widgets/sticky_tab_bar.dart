import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';

/// Custom SliverPersistentHeaderDelegate for sticky category tabs.
///
/// This delegate creates a sticky header that remains pinned at the top
/// when scrolling, containing the category filter tabs.
///
/// Based on Figma design node 1-220 (Destination Hub).
class StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  /// The TabBar widget to display
  final Widget child;

  /// Background color for the sticky header
  final Color backgroundColor;

  /// Height of the header
  final double height;

  StickyTabBarDelegate({
    required this.child,
    this.backgroundColor = Colors.white,
    this.height = 56,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Constrain child to fixed height to prevent SliverGeometry errors
    return SizedBox(
      height: height,
      child: Container(color: backgroundColor, child: child),
    );
  }

  @override
  bool shouldRebuild(covariant StickyTabBarDelegate oldDelegate) {
    return child != oldDelegate.child ||
        backgroundColor != oldDelegate.backgroundColor ||
        height != oldDelegate.height;
  }
}

/// Category tab chip widget matching Figma design.
///
/// Active state: Primary color background (#8B5CF6), white text
/// Inactive state: Light gray background, dark gray text
class CategoryTabChip extends StatelessWidget {
  /// Tab label text
  final String label;

  /// Tab emoji icon
  final String emoji;

  /// Whether this tab is currently selected
  final bool isSelected;

  /// Callback when tab is tapped
  final VoidCallback onTap;

  const CategoryTabChip({
    super.key,
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category tabs row widget — renders dynamic categories from Firestore.
///
/// Horizontal scrollable row with categories fetched via [categoryTabsProvider].
class CategoryTabsRow extends StatelessWidget {
  /// Currently selected category ID
  final String selectedCategory;

  /// Callback when a category is selected
  final ValueChanged<String> onCategorySelected;

  /// Dynamic list of categories to display as tabs
  final List<Category> categories;

  const CategoryTabsRow({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Fixed height to prevent SliverGeometry issues
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      // Use Center + SingleChildScrollView for consistent height
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < categories.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                CategoryTabChip(
                  label: categories[i].name,
                  emoji: categories[i].emoji,
                  isSelected: selectedCategory == categories[i].id,
                  onTap: () => onCategorySelected(categories[i].id),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
