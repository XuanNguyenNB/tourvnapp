/// Location entity for Destination Hub screen.
///
/// Represents a specific place within a destination that users can explore.
/// Used in the location cards grid on the Destination Hub screen.
///
/// See Story 3.4 for acceptance criteria.
class Location {
  /// Unique identifier
  final String id;

  /// Parent destination ID (e.g., 'da-nang', 'da-lat')
  final String destinationId;

  /// Destination name for display (denormalized, e.g., 'Đà Nẵng', 'Đà Lạt')
  final String? destinationName;

  /// Display name (e.g., 'Bánh Mì Hàng Dài Ở Hội An')
  final String name;

  /// Image URL for card display
  final String image;

  /// Category: 'food', 'places', 'stay'
  final String category;

  /// Number of views/engagements
  final int viewCount;

  /// Number of saves/bookmarks
  final int saveCount;

  /// Optional address
  final String? address;

  /// Optional short description
  final String? description;

  /// Price range (e.g., '$$', '$$$')
  final String? priceRange;

  /// Rating out of 5
  final double? rating;

  /// GPS latitude coordinate (nullable for locations without GPS data)
  final double? latitude;

  /// GPS longitude coordinate (nullable for locations without GPS data)
  final double? longitude;

  /// Mood/feature tags for filtering (e.g., "romantic", "family-friendly")
  final List<String> tags;

  /// Search keywords for fuzzy matching (supports Vietnamese diacritics)
  final List<String> searchKeywords;

  /// Estimated duration in minutes to visit this location.
  /// Used for trip planning algorithms.
  final int? estimatedDurationMin;

  /// Content status: 'published' (visible to users) or 'draft_ai' (pending review)
  final String status;

  /// Check if location has valid GPS coordinates
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Check if location has tags
  bool get hasTags => tags.isNotEmpty;

  /// Human-readable duration label computed from [estimatedDurationMin].
  /// Returns null if no duration is set.
  String? get durationLabel {
    if (estimatedDurationMin == null) return null;
    final min = estimatedDurationMin!;
    if (min < 60) return '${min}m';
    final h = min ~/ 60;
    final m = min % 60;
    return m > 0 ? '${h}h${m}m' : '${h}h';
  }

  const Location({
    required this.id,
    required this.destinationId,
    this.destinationName,
    required this.name,
    required this.image,
    required this.category,
    this.viewCount = 0,
    this.saveCount = 0,
    this.address,
    this.description,
    this.priceRange,
    this.rating,
    this.latitude,
    this.longitude,
    this.tags = const [],
    this.searchKeywords = const [],
    this.estimatedDurationMin,
    this.status = 'published',
  });

  /// Get destination name, with fallback to destinationId if not set.
  /// Previously used a hardcoded static map — now relies on actual data
  /// from Firestore via the `destinationName` field.
  String get resolvedDestinationName => destinationName ?? destinationId;

  /// Format view count for display (e.g., 2156 -> "2.1k")
  String get formattedViewCount {
    if (viewCount >= 1000) {
      final value = viewCount / 1000;
      return '${value.toStringAsFixed(1)}k';
    }
    return viewCount.toString();
  }

  /// Format save count for display
  String get formattedSaveCount {
    if (saveCount >= 1000) {
      final value = saveCount / 1000;
      return '${value.toStringAsFixed(1)}k';
    }
    return saveCount.toString();
  }

  /// Get category display text with emoji
  String get categoryDisplay {
    switch (category.toLowerCase()) {
      case 'food':
        return '🍜 Food';
      case 'places':
        return '📸 Places';
      case 'stay':
        return '🏨 Stay';
      default:
        return category;
    }
  }

  /// Get category emoji only
  String get categoryEmoji {
    switch (category.toLowerCase()) {
      case 'food':
        return '🍜';
      case 'places':
        return '📸';
      case 'stay':
        return '🏨';
      default:
        return '📍';
    }
  }

  /// Get formatted tags for display with emojis
  List<String> get formattedTags {
    const tagEmojis = {
      'romantic': '❤️',
      'family-friendly': '👨‍👩‍👧',
      'adventure': '🏔️',
      'instagram-worthy': '📸',
      'hidden-gem': '💎',
      'budget-friendly': '💰',
      'luxury': '✨',
      'local-favorite': '⭐',
    };

    return tags.map((tag) {
      final emoji = tagEmojis[tag.toLowerCase()] ?? '🏷️';
      return '$emoji $tag';
    }).toList();
  }

  /// Check if location matches search query (case-insensitive)
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
        (destinationName?.toLowerCase().contains(lowerQuery) ?? false) ||
        searchKeywords.any((k) => k.toLowerCase().contains(lowerQuery));
  }

  /// Creates a copy with modified fields (immutability pattern)
  Location copyWith({
    String? id,
    String? destinationId,
    String? destinationName,
    String? name,
    String? image,
    String? category,
    int? viewCount,
    int? saveCount,
    String? address,
    String? description,
    String? priceRange,
    double? rating,
    double? latitude,
    double? longitude,
    List<String>? tags,
    List<String>? searchKeywords,
    int? estimatedDurationMin,
    String? status,
  }) {
    return Location(
      id: id ?? this.id,
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
      name: name ?? this.name,
      image: image ?? this.image,
      category: category ?? this.category,
      viewCount: viewCount ?? this.viewCount,
      saveCount: saveCount ?? this.saveCount,
      address: address ?? this.address,
      description: description ?? this.description,
      priceRange: priceRange ?? this.priceRange,
      rating: rating ?? this.rating,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tags: tags ?? this.tags,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      estimatedDurationMin: estimatedDurationMin ?? this.estimatedDurationMin,
      status: status ?? this.status,
    );
  }

  /// Create from JSON (Firestore format)
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as String,
      destinationId: json['destinationId'] as String,
      destinationName: json['destinationName'] as String?,
      name: json['name'] as String,
      image: json['image'] as String,
      category: json['category'] as String,
      viewCount: json['viewCount'] as int? ?? 0,
      saveCount: json['saveCount'] as int? ?? 0,
      address: json['address'] as String?,
      description: json['description'] as String?,
      priceRange: json['priceRange'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      searchKeywords:
          (json['searchKeywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      estimatedDurationMin: json['estimatedDurationMin'] as int?,
      status: json['status'] as String? ?? 'published',
    );
  }

  /// Convert to JSON (Firestore format)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destinationId': destinationId,
      'destinationName': destinationName,
      'name': name,
      'image': image,
      'category': category,
      'viewCount': viewCount,
      'saveCount': saveCount,
      'address': address,
      'description': description,
      'priceRange': priceRange,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
      'tags': tags,
      'searchKeywords': searchKeywords,
      'estimatedDurationMin': estimatedDurationMin,
      'status': status,
    };
  }

  /// Convert to JSON for admin edit operations.
  /// Excludes user-generated stats (viewCount, saveCount)
  /// so admin edits don't accidentally reset counters.
  Map<String, dynamic> toEditableJson() {
    return {
      'id': id,
      'destinationId': destinationId,
      'destinationName': destinationName,
      'name': name,
      'image': image,
      'category': category,
      'address': address,
      'description': description,
      'priceRange': priceRange,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
      'tags': tags,
      'searchKeywords': searchKeywords,
      'estimatedDurationMin': estimatedDurationMin,
      'status': status,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Location(id: $id, name: $name, category: $category)';
}
