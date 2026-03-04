/// Entity representing a full review for the Review Detail screen.
///
/// This is an immutable value object containing complete review information.
/// Used for displaying the Review Detail screen with all content.
///
/// See Story 3.8 for acceptance criteria.
class Review {
  /// Unique identifier for the review
  final String id;

  /// Hero image URL for the review
  final String heroImage;

  /// Title of the review
  final String title;

  /// ID of the review author
  final String authorId;

  /// Display name of the review author
  final String authorName;

  /// URL to the author's avatar image
  final String authorAvatar;

  /// Full review text content
  final String fullText;

  /// When the review was created
  final DateTime createdAt;

  /// Number of likes on this review
  final int likeCount;

  /// Number of comments on this review
  final int commentCount;

  /// Number of saves on this review
  final int saveCount;

  /// IDs of locations related to this review
  final List<String> relatedLocationIds;

  /// Optional destination ID for multi-destination scheduling
  final String? destinationId;

  /// Optional destination name for display
  final String? destinationName;

  /// Category for feed filtering (Story 8-2)
  /// Values: "food", "places", "stay" (matches Location.category)
  final String? category;

  /// URL-friendly slug derived from title (for SEO/URL purposes)
  final String? slug;

  /// Content status: 'published' (visible to users) or 'draft_ai' (pending review)
  final String status;

  const Review({
    required this.id,
    required this.heroImage,
    required this.title,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.fullText,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.saveCount,
    this.relatedLocationIds = const [],
    this.destinationId,
    this.destinationName,
    this.category,
    this.slug,
    this.status = 'published',
  });

  /// Creates a copy with modified fields (immutability pattern)
  Review copyWith({
    String? id,
    String? heroImage,
    String? title,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? fullText,
    DateTime? createdAt,
    int? likeCount,
    int? commentCount,
    int? saveCount,
    List<String>? relatedLocationIds,
    String? destinationId,
    String? destinationName,
    String? category,
    String? slug,
    String? status,
  }) {
    return Review(
      id: id ?? this.id,
      heroImage: heroImage ?? this.heroImage,
      title: title ?? this.title,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      fullText: fullText ?? this.fullText,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      saveCount: saveCount ?? this.saveCount,
      relatedLocationIds: relatedLocationIds ?? this.relatedLocationIds,
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
      category: category ?? this.category,
      slug: slug ?? this.slug,
      status: status ?? this.status,
    );
  }

  /// Formats the date for display (e.g., "2 ngày trước")
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} ngày trước';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  /// Formats like count for display (e.g., 1234 -> "1.2k")
  String get formattedLikes => _formatCount(likeCount);

  /// Formats comment count for display
  String get formattedComments => _formatCount(commentCount);

  /// Formats save count for display
  String get formattedSaves => _formatCount(saveCount);

  /// Get formatted category for display with emoji (Story 8-2)
  /// Returns null if category is null
  String? get categoryDisplay {
    if (category == null) return null;
    switch (category!.toLowerCase()) {
      case 'food':
        return '🍜 Ăn uống';
      case 'places':
        return '📸 Điểm đến';
      case 'stay':
        return '🏨 Lưu trú';
      default:
        return category;
    }
  }

  /// Create from JSON (Firestore format)
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      heroImage: json['heroImage'] as String,
      title: json['title'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorAvatar: json['authorAvatar'] as String,
      fullText: json['fullText'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      saveCount: json['saveCount'] as int? ?? 0,
      relatedLocationIds:
          (json['relatedLocationIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      destinationId: json['destinationId'] as String?,
      destinationName: json['destinationName'] as String?,
      category: json['category'] as String?,
      slug: json['slug'] as String?,
      status: json['status'] as String? ?? 'published',
    );
  }

  /// Convert to JSON (Firestore format)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'heroImage': heroImage,
      'title': title,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'fullText': fullText,
      'createdAt': createdAt.toIso8601String(),
      'likeCount': likeCount,
      'commentCount': commentCount,
      'saveCount': saveCount,
      'relatedLocationIds': relatedLocationIds,
      'destinationId': destinationId,
      'destinationName': destinationName,
      'category': category,
      'slug': slug,
      'status': status,
    };
  }

  /// Convert to JSON for admin edit operations.
  /// Excludes stats fields (likeCount, commentCount, saveCount)
  /// so admin edits don't accidentally reset engagement counters.
  Map<String, dynamic> toEditableJson() {
    return {
      'id': id,
      'heroImage': heroImage,
      'title': title,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'fullText': fullText,
      'createdAt': createdAt.toIso8601String(),
      'relatedLocationIds': relatedLocationIds,
      'destinationId': destinationId,
      'destinationName': destinationName,
      'category': category,
      'slug': slug,
      'status': status,
    };
  }

  /// Internal helper to format large numbers
  String _formatCount(int count) {
    if (count >= 1000) {
      final value = count / 1000;
      return '${value.toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Review && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Review(id: $id, title: $title, likeCount: $likeCount)';
  }
}
