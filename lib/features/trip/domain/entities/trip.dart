import 'trip_day.dart';
import 'activity.dart';
import '../../presentation/providers/pending_trip_provider.dart';

/// Trip entity representing a user's travel plan.
///
/// Contains trip metadata and embedded days with activities.
/// Uses denormalized data for efficient reads.
class Trip {
  /// Unique identifier for this trip.
  final String id;

  /// User ID who owns this trip.
  final String userId;

  /// Display name for the trip (e.g., "Đà Lạt Trip").
  final String name;

  /// ID of the primary destination (for duplicate detection).
  final String destinationId;

  /// Display name of the destination (denormalized).
  final String destinationName;

  /// List of days in this trip with activities.
  final List<TripDay> days;

  /// Timestamp when the trip was created.
  final DateTime createdAt;

  /// Timestamp when the trip was last updated.
  final DateTime updatedAt;

  const Trip({
    required this.id,
    required this.userId,
    required this.name,
    required this.destinationId,
    required this.destinationName,
    required this.days,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a new Trip from PendingTripState.
  ///
  /// Used when auto-creating a trip from pending activities.
  factory Trip.fromPendingState({
    required String id,
    required String userId,
    required PendingTripState pendingState,
    required String destinationId,
    required String destinationName,
  }) {
    final now = DateTime.now();

    // Group pending activities by day
    final activitiesByDay = pendingState.activitiesByDay;

    // Create days based on totalDays (includes manually added days)
    final days = <TripDay>[];
    for (int i = 0; i < pendingState.totalDays; i++) {
      final dayActivities = activitiesByDay[i] ?? [];
      final activities = dayActivities
          .asMap()
          .entries
          .map((e) => Activity.fromPendingActivity(e.value, e.key))
          .toList();

      days.add(
        TripDay(
          dayNumber: i + 1, // 1-based display
          activities: activities,
        ),
      );
    }

    final tripName = pendingState.tripName?.isNotEmpty == true
        ? pendingState.tripName!
        : 'Khám phá $destinationName';

    return Trip(
      id: id,
      userId: userId,
      name: tripName,
      destinationId: destinationId,
      destinationName: destinationName,
      days: days,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Serialize to Firestore-compatible map.
  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'destinationId': destinationId,
    'destinationName': destinationName,
    'days': days.map((d) => d.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Deserialize from Firestore map.
  factory Trip.fromMap(Map<String, dynamic> map) => Trip(
    id: map['id'] as String,
    userId: map['userId'] as String,
    name: map['name'] as String,
    destinationId: map['destinationId'] as String,
    destinationName: map['destinationName'] as String,
    days:
        (map['days'] as List<dynamic>?)
            ?.map((d) => TripDay.fromMap(d as Map<String, dynamic>))
            .toList() ??
        const [],
    createdAt: _parseDateTime(map['createdAt']),
    updatedAt: _parseDateTime(map['updatedAt']),
  );

  /// Parse DateTime from various formats (ISO string, DateTime, or fallback).
  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Create a copy with optional field overrides.
  Trip copyWith({
    String? id,
    String? userId,
    String? name,
    String? destinationId,
    String? destinationName,
    List<TripDay>? days,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
      days: days ?? this.days,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Total number of days in this trip.
  int get totalDays => days.length;

  /// Total number of activities across all days.
  int get totalActivities =>
      days.fold(0, (total, day) => total + day.activityCount);

  /// Cover image URL from the first activity that has an image.
  ///
  /// Scans all activities across all days and returns the first imageUrl found.
  /// Returns null if no activity has an image.
  String? get coverImageUrl {
    for (final day in days) {
      for (final activity in day.activities) {
        if (activity.imageUrl != null && activity.imageUrl!.isNotEmpty) {
          return activity.imageUrl;
        }
      }
    }
    return null;
  }

  /// Get a specific day by number (1-based).
  TripDay? getDay(int dayNumber) {
    try {
      return days.firstWhere((d) => d.dayNumber == dayNumber);
    } catch (_) {
      return null;
    }
  }

  /// Find an existing activity by locationId.
  /// Returns a record with (dayNumber, activity) if found, null otherwise.
  /// Used to detect duplicate locations in trip.
  ({int dayNumber, Activity activity})? findActivityByLocationId(
    String locationId,
  ) {
    for (final day in days) {
      for (final activity in day.activities) {
        if (activity.locationId == locationId) {
          return (dayNumber: day.dayNumber, activity: activity);
        }
      }
    }
    return null;
  }

  /// Add activity to a specific day.
  Trip addActivityToDay(int dayNumber, Activity activity) {
    final updatedDays = days.map((day) {
      if (day.dayNumber == dayNumber) {
        return day.addActivity(activity);
      }
      return day;
    }).toList();

    return copyWith(days: updatedDays, updatedAt: DateTime.now());
  }

  /// Add a new day to the trip.
  Trip addDay() {
    final newDayNumber = (days.isEmpty ? 0 : days.last.dayNumber) + 1;
    return copyWith(
      days: [
        ...days,
        TripDay(dayNumber: newDayNumber),
      ],
      updatedAt: DateTime.now(),
    );
  }

  /// Add activities from PendingTripState to existing trip.
  Trip addFromPendingState(PendingTripState pendingState) {
    final updatedDays = List<TripDay>.from(days);
    final activitiesByDay = pendingState.activitiesByDay;

    // Ensure we have enough days
    while (updatedDays.length < pendingState.totalDays) {
      updatedDays.add(TripDay(dayNumber: updatedDays.length + 1));
    }

    // Add activities to each day
    for (final entry in activitiesByDay.entries) {
      final dayIndex = entry.key;
      final pendingActivities = entry.value;

      if (dayIndex < updatedDays.length) {
        final existingDay = updatedDays[dayIndex];
        final startOrder = existingDay.activityCount;

        final newActivities = pendingActivities
            .asMap()
            .entries
            .map(
              (e) => Activity.fromPendingActivity(e.value, startOrder + e.key),
            )
            .toList();

        updatedDays[dayIndex] = existingDay.copyWith(
          activities: [...existingDay.activities, ...newActivities],
        );
      }
    }

    return copyWith(days: updatedDays, updatedAt: DateTime.now());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Trip && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Trip(id: $id, name: $name, days: $totalDays, activities: $totalActivities)';
}
