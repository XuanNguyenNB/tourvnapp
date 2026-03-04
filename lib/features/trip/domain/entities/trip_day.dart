import 'activity.dart';

/// TripDay entity representing a single day in a trip.
///
/// Contains a list of activities planned for that day.
/// Day numbers are 1-based for user display.
class TripDay {
  /// Day number (1-based for display).
  final int dayNumber;

  /// List of activities planned for this day.
  final List<Activity> activities;

  const TripDay({required this.dayNumber, this.activities = const []});

  /// Serialize to Firestore-compatible map.
  Map<String, dynamic> toMap() => {
    'dayNumber': dayNumber,
    'activities': activities.map((a) => a.toMap()).toList(),
  };

  /// Deserialize from Firestore map.
  factory TripDay.fromMap(Map<String, dynamic> map) => TripDay(
    dayNumber: map['dayNumber'] as int,
    activities:
        (map['activities'] as List<dynamic>?)
            ?.map((a) => Activity.fromMap(a as Map<String, dynamic>))
            .toList() ??
        const [],
  );

  /// Create a copy with optional field overrides.
  TripDay copyWith({int? dayNumber, List<Activity>? activities}) {
    return TripDay(
      dayNumber: dayNumber ?? this.dayNumber,
      activities: activities ?? this.activities,
    );
  }

  /// Check if this day has any activities.
  bool get isEmpty => activities.isEmpty;

  /// Check if this day has activities.
  bool get isNotEmpty => activities.isNotEmpty;

  /// Number of activities in this day.
  int get activityCount => activities.length;

  /// Get display label (e.g., "Ngày 1").
  String get label => 'Ngày $dayNumber';

  /// Add an activity to this day.
  TripDay addActivity(Activity activity) {
    return copyWith(activities: [...activities, activity]);
  }

  /// Remove an activity by ID.
  TripDay removeActivity(String activityId) {
    return copyWith(
      activities: activities.where((a) => a.id != activityId).toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripDay && other.dayNumber == dayNumber;
  }

  @override
  int get hashCode => dayNumber.hashCode;

  @override
  String toString() =>
      'TripDay(day: $dayNumber, activities: ${activities.length})';

  // ─────────────────────────────────────────────────────────────────────────
  // Multi-Destination Conflict Detection Properties
  // ─────────────────────────────────────────────────────────────────────────

  /// Check if this day has activities from multiple destinations.
  ///
  /// Returns true if activities span more than one unique destination.
  /// Activities with null destinationId are ignored.
  bool get hasMultipleDestinations {
    final destinations = activities
        .where((a) => a.destinationId != null)
        .map((a) => a.destinationId!)
        .toSet();
    return destinations.length > 1;
  }

  /// Get the primary (most frequent) destination ID for this day.
  ///
  /// Returns the destination ID that appears most frequently among activities.
  /// Returns null if no activities have a destination ID set.
  String? get primaryDestinationId {
    final counts = <String, int>{};
    for (final activity in activities) {
      if (activity.destinationId != null) {
        counts[activity.destinationId!] =
            (counts[activity.destinationId!] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Get all unique destination IDs for activities in this day.
  ///
  /// Returns an empty list if no activities have destination IDs.
  List<String> get allDestinations {
    return activities
        .where((a) => a.destinationId != null)
        .map((a) => a.destinationId!)
        .toSet()
        .toList();
  }

  /// Get all unique destination names for activities in this day.
  ///
  /// Returns an empty list if no activities have destination names.
  List<String> get allDestinationNames {
    return activities
        .where((a) => a.destinationName != null)
        .map((a) => a.destinationName!)
        .toSet()
        .toList();
  }
}
