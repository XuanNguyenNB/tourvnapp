/// Full destination entity for Destination Hub screen.
///
/// Simplified entity containing only core destination information:
/// - Basic info: id (auto-parsed from name), name, hero image
/// - Description text
/// - Country code (default VN)
/// - Stats: postCount, engagementCount (read-only, computed from reviews)
class Destination {
  /// Unique identifier, auto-parsed from name (e.g., 'da-lat')
  final String id;

  /// Display name (e.g., 'Đà Lạt', 'Đà Nẵng')
  final String name;

  /// Hero image URL for hero header
  final String heroImage;

  /// Full description text
  final String description;

  /// Number of engagements (likes) — computed from reviews, read-only
  final int engagementCount;

  /// Post count — computed from reviews, read-only
  final int postCount;

  /// Location count - computed from locations, read-only
  final int locationCount;

  /// Country code (e.g., 'VN')
  final String countryCode;

  /// Content status: 'published' (visible to users) or 'draft_ai' (pending review)
  final String status;

  /// Timestamp when destination was created
  final DateTime? createdAt;

  const Destination({
    required this.id,
    required this.name,
    required this.heroImage,
    required this.description,
    this.engagementCount = 0,
    this.postCount = 0,
    this.locationCount = 0,
    this.countryCode = 'VN',
    this.status = 'published',
    this.createdAt,
  });

  /// Creates a copy with modified fields (immutability pattern)
  Destination copyWith({
    String? id,
    String? name,
    String? heroImage,
    String? description,
    int? engagementCount,
    int? postCount,
    int? locationCount,
    String? countryCode,
    String? status,
    DateTime? createdAt,
  }) {
    return Destination(
      id: id ?? this.id,
      name: name ?? this.name,
      heroImage: heroImage ?? this.heroImage,
      description: description ?? this.description,
      engagementCount: engagementCount ?? this.engagementCount,
      postCount: postCount ?? this.postCount,
      locationCount: locationCount ?? this.locationCount,
      countryCode: countryCode ?? this.countryCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Format engagement count for display (e.g., 2341 -> "2.3k")
  String get formattedEngagement {
    if (engagementCount >= 1000) {
      final value = engagementCount / 1000;
      return '${value.toStringAsFixed(1)}k';
    }
    return engagementCount.toString();
  }

  /// Format post count for display (e.g., 2300 -> "2.3k")
  String get formattedPostCount {
    if (postCount >= 1000) {
      final value = postCount / 1000;
      return '${value.toStringAsFixed(1)}k';
    }
    return postCount.toString();
  }

  /// Get country flag emoji from country code
  String get countryFlag {
    if (countryCode.length != 2) return '🌍';
    final firstLetter = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final secondLetter = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([firstLetter, secondLetter]);
  }

  /// Get subtitle text (e.g., "2.3k bài viết")
  String get subtitle {
    return '$formattedPostCount bài viết';
  }

  /// Generate slug ID from Vietnamese name
  /// "Đà Lạt" → "da-lat", "Hồ Chí Minh" → "ho-chi-minh"
  static String generateId(String name) {
    const diacritics =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễđìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹ';
    const replacements =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeediiiiiooooooooooooooooouuuuuuuuuuuyyyyy';

    var result = name.toLowerCase().trim();
    for (var i = 0; i < diacritics.length; i++) {
      result = result.replaceAll(diacritics[i], replacements[i]);
    }
    result = result.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    result = result.replaceAll(RegExp(r'\s+'), '-');
    result = result.replaceAll(RegExp(r'-+'), '-');
    result = result.replaceAll(RegExp(r'^-|-$'), '');
    return result;
  }

  /// Create from JSON (Firestore format)
  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] as String,
      name: json['name'] as String,
      heroImage: json['heroImage'] as String,
      description: json['description'] as String? ?? '',
      engagementCount: json['engagementCount'] as int? ?? 0,
      postCount: json['postCount'] as int? ?? 0,
      locationCount: json['locationCount'] as int? ?? 0,
      countryCode: json['countryCode'] as String? ?? 'VN',
      status: json['status'] as String? ?? 'published',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Convert to JSON (Firestore format)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'heroImage': heroImage,
      'description': description,
      'engagementCount': engagementCount,
      'postCount': postCount,
      'locationCount': locationCount,
      'countryCode': countryCode,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Convert to JSON for admin edit operations.
  /// Excludes computed stats fields (engagementCount, postCount, locationCount)
  /// so admin edits don't accidentally reset counters.
  Map<String, dynamic> toEditableJson() {
    return {
      'id': id,
      'name': name,
      'heroImage': heroImage,
      'description': description,
      'countryCode': countryCode,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Destination && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Destination(id: $id, name: $name)';
}
