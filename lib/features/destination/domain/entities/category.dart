/// Category entity for dynamic category management.
///
/// Categories are stored in Firestore and managed by admin.
/// Used by Location, Review, and filter systems.
class Category {
  /// Unique identifier (e.g., 'food', 'cafe', 'beach')
  final String id;

  /// Display name in Vietnamese (e.g., 'Ăn uống', 'Cà phê')
  final String name;

  /// Emoji icon (e.g., '🍜', '☕', '🏖️')
  final String emoji;

  /// Sort order for display
  final int sortOrder;

  /// Whether this category is active/visible
  final bool isActive;

  const Category({
    required this.id,
    required this.name,
    required this.emoji,
    this.sortOrder = 0,
    this.isActive = true,
  });

  /// Display text with emoji (e.g., '🍜 Ăn uống')
  String get displayText => '$emoji $name';

  /// Create from Firestore JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '📍',
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? emoji,
    int? sortOrder,
    bool? isActive,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Category(id: $id, name: $name, emoji: $emoji)';

  /// Default seed categories matching existing system
  static const List<Category> defaultCategories = [
    Category(id: 'food', name: 'Ăn uống', emoji: '🍜', sortOrder: 0),
    Category(id: 'cafe', name: 'Cà phê', emoji: '☕', sortOrder: 1),
    Category(id: 'places', name: 'Điểm tham quan', emoji: '📸', sortOrder: 2),
    Category(id: 'stay', name: 'Lưu trú', emoji: '🏨', sortOrder: 3),
    Category(id: 'beach', name: 'Biển', emoji: '🏖️', sortOrder: 4),
    Category(id: 'nature', name: 'Thiên nhiên', emoji: '🌄', sortOrder: 5),
    Category(id: 'shopping', name: 'Mua sắm', emoji: '🛍️', sortOrder: 6),
    Category(id: 'nightlife', name: 'Giải trí đêm', emoji: '🎉', sortOrder: 7),
  ];
}
