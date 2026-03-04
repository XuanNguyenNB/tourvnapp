/// Entity representing a destination preview for the home screen Bento Grid.
///
/// This is an immutable value object used for displaying destination cards.
/// See Story 3.1 for acceptance criteria.
/// Story 6.5: Added moods field for personalized feed filtering.
class DestinationPreview {
  /// Unique identifier for the destination
  final String id;

  /// Display name of the destination (e.g., "Đà Lạt", "Hội An")
  final String name;

  /// URL to the hero image for the destination card
  final String heroImage;

  /// Number of likes/engagements for this destination
  final int engagementCount;

  /// Size hint for Bento Grid layout (1 = small, 2 = large)
  final int sizeHint;

  /// Mood tags for personalized feed filtering
  /// Values should match Mood.id (e.g., 'healing', 'adventure', 'foodie')
  final List<String>? moods;

  const DestinationPreview({
    required this.id,
    required this.name,
    required this.heroImage,
    required this.engagementCount,
    this.sizeHint = 1,
    this.moods,
  });

  /// Creates a copy with modified fields (immutability pattern)
  DestinationPreview copyWith({
    String? id,
    String? name,
    String? heroImage,
    int? engagementCount,
    int? sizeHint,
    List<String>? moods,
  }) {
    return DestinationPreview(
      id: id ?? this.id,
      name: name ?? this.name,
      heroImage: heroImage ?? this.heroImage,
      engagementCount: engagementCount ?? this.engagementCount,
      sizeHint: sizeHint ?? this.sizeHint,
      moods: moods ?? this.moods,
    );
  }

  /// Formats engagement count for display (e.g., 2341 -> "2.3k")
  String get formattedEngagement {
    if (engagementCount >= 1000) {
      final value = engagementCount / 1000;
      return '${value.toStringAsFixed(1)}k';
    }
    return engagementCount.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DestinationPreview && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
