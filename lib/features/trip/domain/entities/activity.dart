import 'pending_activity.dart';

/// Activity entity for saved trips.
///
/// Represents a single activity (location visit) within a trip day.
/// Contains denormalized data for efficient display without extra reads.
class Activity {
  /// Unique identifier for this activity.
  final String id;

  /// Reference to the location being visited.
  final String locationId;

  /// Display name of the location (denormalized).
  final String locationName;

  /// Optional category emoji (e.g., 🍜 for Food).
  final String? emoji;

  /// Optional image URL for the location.
  final String? imageUrl;

  /// Time slot for this activity (morning, noon, afternoon, evening).
  final String timeSlot;

  /// Sort order within the day for manual reordering.
  final int sortOrder;

  /// Estimated duration for this activity (e.g., "1h", "30m", "1h30m").
  final String? estimatedDuration;

  /// Estimated duration in minutes for algorithmic use (e.g., 90 for "1h30m").
  final int? estimatedDurationMin;

  /// Destination ID for multi-destination scheduling (nullable for backward compat).
  /// Example: "da-nang", "hue", "ha-noi"
  final String? destinationId;

  /// Destination name for display (nullable for backward compat).
  /// Example: "Đà Nẵng", "Huế", "Hà Nội"
  final String? destinationName;

  const Activity({
    required this.id,
    required this.locationId,
    required this.locationName,
    this.emoji,
    this.imageUrl,
    required this.timeSlot,
    required this.sortOrder,
    this.estimatedDuration,
    this.estimatedDurationMin,
    this.destinationId,
    this.destinationName,
  });

  /// Create Activity from a PendingActivity.
  ///
  /// Used when converting pending activities to saved trip activities.
  factory Activity.fromPendingActivity(PendingActivity pending, int order) {
    return Activity(
      id: pending.id,
      locationId: pending.locationId,
      locationName: pending.locationName,
      emoji: pending.emoji,
      imageUrl: pending.imageUrl,
      timeSlot: pending.timeSlot.name,
      sortOrder: order,
      estimatedDurationMin: pending.estimatedDurationMin,
      estimatedDuration: pending.estimatedDuration,
      destinationId: pending.destinationId,
      destinationName: pending.destinationName,
    );
  }

  /// Serialize to Firestore-compatible map.
  Map<String, dynamic> toMap() => {
    'id': id,
    'locationId': locationId,
    'locationName': locationName,
    'emoji': emoji,
    'imageUrl': imageUrl,
    'timeSlot': timeSlot,
    'sortOrder': sortOrder,
    'estimatedDuration': estimatedDuration,
    'estimatedDurationMin': estimatedDurationMin,
    'destinationId': destinationId,
    'destinationName': destinationName,
  };

  /// Deserialize from Firestore map.
  /// Handles missing destination fields gracefully for backward compatibility.
  factory Activity.fromMap(Map<String, dynamic> map) => Activity(
    id: map['id'] as String,
    locationId: map['locationId'] as String,
    locationName: map['locationName'] as String,
    emoji: map['emoji'] as String?,
    imageUrl: map['imageUrl'] as String?,
    timeSlot: map['timeSlot'] as String,
    sortOrder: map['sortOrder'] as int,
    estimatedDuration: map['estimatedDuration'] as String?,
    estimatedDurationMin: map['estimatedDurationMin'] as int?,
    destinationId: map['destinationId'] as String?,
    destinationName: map['destinationName'] as String?,
  );

  /// Create a copy with optional field overrides.
  Activity copyWith({
    String? id,
    String? locationId,
    String? locationName,
    String? emoji,
    String? imageUrl,
    String? timeSlot,
    int? sortOrder,
    String? estimatedDuration,
    int? estimatedDurationMin,
    String? destinationId,
    String? destinationName,
  }) {
    return Activity(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      emoji: emoji ?? this.emoji,
      imageUrl: imageUrl ?? this.imageUrl,
      timeSlot: timeSlot ?? this.timeSlot,
      sortOrder: sortOrder ?? this.sortOrder,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      estimatedDurationMin: estimatedDurationMin ?? this.estimatedDurationMin,
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Activity &&
        other.id == id &&
        other.locationId == locationId &&
        other.timeSlot == timeSlot;
  }

  @override
  int get hashCode => Object.hash(id, locationId, timeSlot);

  @override
  String toString() =>
      'Activity(id: $id, location: $locationName, timeSlot: $timeSlot)';
}
