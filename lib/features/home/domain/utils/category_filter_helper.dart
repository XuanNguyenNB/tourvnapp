/// Helper class for category filter chip data and formatting.
///
/// Story 8-8: Provides static category data for the category filter chips
/// on the Home Screen. Categories are static (not from Firestore).
///
/// Example:
/// ```dart
/// final categories = CategoryFilterHelper.categories;
/// final emoji = CategoryFilterHelper.getEmoji('food'); // '🍜'
/// final formatted = CategoryFilterHelper.formatChipText('food'); // '🍜 Ăn uống'
/// ```
abstract class CategoryFilterHelper {
  // Private constructor - this class should not be instantiated.
  CategoryFilterHelper._();

  /// List of available categories with Vietnamese display names.
  ///
  /// Order determines display order in the chips row.
  static const List<CategoryData> categories = [
    CategoryData(id: 'food', name: 'Ăn uống', emoji: '🍜'),
    CategoryData(id: 'cafe', name: 'Cafe', emoji: '☕'),
    CategoryData(id: 'places', name: 'Địa điểm', emoji: '📸'),
    CategoryData(id: 'stay', name: 'Lưu trú', emoji: '🏨'),
  ];

  /// Default category data used when ID is not found.
  static const _defaultCategory = CategoryData(
    id: 'other',
    name: 'Khác',
    emoji: '📍',
  );

  /// Get the emoji for a category ID.
  ///
  /// Returns the mapped emoji if found, otherwise returns default location pin.
  static String getEmoji(String categoryId) {
    final category = _findCategory(categoryId);
    return category.emoji;
  }

  /// Get the display name for a category ID.
  ///
  /// Returns the Vietnamese name for the category, or default if not found.
  static String getName(String categoryId) {
    final category = _findCategory(categoryId);
    return category.name;
  }

  /// Format the display text for a category chip.
  ///
  /// Combines emoji and category name for display.
  /// Example: formatChipText('food') returns '🍜 Ăn uống'
  static String formatChipText(String categoryId) {
    final category = _findCategory(categoryId);
    return '${category.emoji} ${category.name}';
  }

  /// Check if a category ID exists in the known categories.
  static bool hasCategory(String categoryId) {
    final normalized = categoryId.toLowerCase().trim();
    return categories.any((c) => c.id == normalized);
  }

  /// Get all known category IDs.
  static List<String> get knownCategoryIds =>
      categories.map((c) => c.id).toList();

  /// Find a category by ID with fallback to default.
  static CategoryData _findCategory(String categoryId) {
    final normalized = categoryId.toLowerCase().trim();
    return categories.firstWhere(
      (c) => c.id == normalized,
      orElse: () => _defaultCategory,
    );
  }
}

/// Data model for a category filter option.
///
/// Immutable value class containing category metadata.
class CategoryData {
  /// Unique identifier for the category (e.g., 'food', 'cafe').
  final String id;

  /// Display name in Vietnamese (e.g., 'Ăn uống').
  final String name;

  /// Emoji representation of the category.
  final String emoji;

  /// Creates a CategoryData instance.
  const CategoryData({
    required this.id,
    required this.name,
    required this.emoji,
  });

  /// Get formatted display text with emoji.
  String get displayText => '$emoji $name';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryData &&
        other.id == id &&
        other.name == name &&
        other.emoji == emoji;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ emoji.hashCode;

  @override
  String toString() => 'CategoryData(id: $id, name: $name, emoji: $emoji)';
}
