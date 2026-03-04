/// Entity representing a review preview for the home screen Bento Grid.
///
/// This is an immutable value object used for displaying review cards.
/// See Story 3.1 for acceptance criteria.
/// Story 6.5: Added moods field for personalized feed filtering.
class ReviewPreview {
  /// Unique identifier for the review
  final String id;

  /// Title of the review
  final String title;

  /// Display name of the review author
  final String authorName;

  /// URL to the author's avatar image
  final String authorAvatar;

  /// Short snippet of the review text (max ~80 chars for display)
  final String shortText;

  /// Optional hero image for the review content
  final String? heroImage;

  /// Number of likes on this review
  final int likeCount;

  /// Number of comments on this review
  final int commentCount;

  /// Mood tags for personalized feed filtering
  /// Values should match Mood.id (e.g., 'healing', 'adventure', 'foodie')
  final List<String>? moods;

  /// Optional destination ID for multi-destination scheduling
  final String? destinationId;

  /// Optional destination name for display
  final String? destinationName;

  /// Category for feed filtering (Story 8-2)
  /// Values: "food", "places", "stay" (matches Location.category)
  final String? category;

  /// Category name for display (e.g., "Ăn uống", "Địa danh")
  final String? categoryName;

  /// Emoji for category display (e.g., "🍜", "📍")
  final String? categoryEmoji;

  /// Rating of the review
  final double rating;

  /// When the review was created (for time-ago display)
  final DateTime? createdAt;

  /// GPS latitude (from first related Location)
  final double? latitude;

  /// GPS longitude (from first related Location)
  final double? longitude;

  /// Computed distance from user in km (set at runtime)
  final double? distanceKm;

  /// Whether this review has GPS coordinates
  bool get hasCoordinates => latitude != null && longitude != null;

  const ReviewPreview({
    required this.id,
    required this.title,
    required this.authorName,
    required this.authorAvatar,
    required this.shortText,
    this.heroImage,
    required this.likeCount,
    required this.commentCount,
    this.moods,
    this.destinationId,
    this.destinationName,
    this.category,
    this.categoryName,
    this.categoryEmoji,
    this.rating = 0.0,
    this.createdAt,
    this.latitude,
    this.longitude,
    this.distanceKm,
  });

  /// Creates a copy with modified fields (immutability pattern)
  ReviewPreview copyWith({
    String? id,
    String? title,
    String? authorName,
    String? authorAvatar,
    String? shortText,
    String? heroImage,
    int? likeCount,
    int? commentCount,
    List<String>? moods,
    String? destinationId,
    String? destinationName,
    String? category,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
    double? distanceKm,
  }) {
    return ReviewPreview(
      id: id ?? this.id,
      title: title ?? this.title,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      shortText: shortText ?? this.shortText,
      heroImage: heroImage ?? this.heroImage,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      moods: moods ?? this.moods,
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  /// Formats like count for display (e.g., 1234 -> "1.2k")
  String get formattedLikes {
    if (likeCount >= 1000) {
      final value = likeCount / 1000;
      return '${value.toStringAsFixed(1)}k';
    }
    return likeCount.toString();
  }

  /// Formats comment count for display
  String get formattedComments {
    if (commentCount >= 1000) {
      final value = commentCount / 1000;
      return '${value.toStringAsFixed(1)}k';
    }
    return commentCount.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewPreview && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
