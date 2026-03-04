import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/utils/category_filter_helper.dart';

/// A chip-shaped widget representing a category filter option.
///
/// Story 8-8: Individual chip for category filtering on Home Screen.
/// Shows emoji + category name (e.g., "🍜 Ăn uống"), with visual states
/// for selection (purple) and unselected (white with border).
///
/// Follows the same visual pattern as DestinationPill (Story 8-7) for
/// UI consistency. Uses AnimatedContainer for smooth state transitions.
///
/// Example:
/// ```dart
/// CategoryChip(
///   categoryId: 'food',
///   categoryName: 'Ăn uống',
///   isSelected: true,
///   onTap: () => print('Food tapped'),
/// )
/// ```
class CategoryChip extends StatelessWidget {
  /// The category ID (e.g., 'food', 'cafe', 'places', 'stay').
  final String categoryId;

  /// The display name of the category (e.g., 'Ăn uống').
  final String categoryName;

  /// Whether this chip is currently selected.
  final bool isSelected;

  /// Callback fired when the chip is tapped.
  ///
  /// Should handle selection toggle logic via CategoryFilterProvider.
  final VoidCallback? onTap;

  /// Creates a CategoryChip widget.
  const CategoryChip({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.isSelected = false,
    this.onTap,
  });

  // Color constants matching Figma design specs.
  // Same as DestinationPill for visual consistency.
  static const _selectedBackground = Color(0xFF8B5CF6);
  static const _unselectedBackground = Colors.white;
  static const _unselectedBorderColor = Color(0xFFE2E8F0);
  static const _selectedTextColor = Colors.white;
  static const _unselectedTextColor = Color(0xFF64748B);

  // Animation configuration
  static const _animationDuration = Duration(milliseconds: 200);
  static const _animationCurve = Curves.easeInOut;

  /// Get formatted display text (emoji + name).
  String get _displayText => CategoryFilterHelper.formatChipText(categoryId);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: _animationDuration,
        curve: _animationCurve,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _selectedBackground : _unselectedBackground,
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? null
              : Border.all(color: _unselectedBorderColor, width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _selectedBackground.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          _displayText,
          style: TextStyle(
            color: isSelected ? _selectedTextColor : _unselectedTextColor,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Handle tap with haptic feedback.
  void _handleTap() {
    HapticFeedback.lightImpact();
    onTap?.call();
  }
}
