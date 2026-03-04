import 'package:uuid/uuid.dart';

import 'time_slot.dart';
import 'day_picker_selection.dart';

/// Activity pending to be added to a trip.
///
/// Created when user confirms day selection in the Day Picker.
/// Stores all necessary data until trip is created/updated.
class PendingActivity {
  /// Unique identifier for this pending activity.
  final String id;

  /// The selected day index (0-based).
  final int dayIndex;

  /// The selected time slot.
  final TimeSlot timeSlot;

  /// ID of the location being added.
  final String locationId;

  /// Display name of the location.
  final String locationName;

  /// Optional emoji for the location.
  final String? emoji;

  /// Optional image URL for the location.
  final String? imageUrl;

  /// Estimated duration for this activity (e.g., "1h", "30m").
  final String? estimatedDuration;

  /// Estimated duration in minutes for algorithmic use.
  final int? estimatedDurationMin;

  /// Destination ID for multi-destination scheduling (required for new activities).
  /// Example: "da-nang", "hue", "ha-noi"
  final String destinationId;

  /// Destination name for display (required for new activities).
  /// Example: "Đà Nẵng", "Huế", "Hà Nội"
  final String destinationName;

  /// Timestamp when this activity was added.
  final DateTime addedAt;

  const PendingActivity({
    required this.id,
    required this.dayIndex,
    required this.timeSlot,
    required this.locationId,
    required this.locationName,
    this.emoji,
    this.imageUrl,
    this.estimatedDuration,
    this.estimatedDurationMin,
    required this.destinationId,
    required this.destinationName,
    required this.addedAt,
  });

  /// Create from [DayPickerSelection].
  ///
  /// Generates a unique ID and captures the current timestamp.
  /// Destination info is extracted from itemData for multi-destination scheduling.
  factory PendingActivity.fromSelection(DayPickerSelection selection) {
    return PendingActivity(
      id: const Uuid().v4(),
      dayIndex: selection.dayIndex,
      timeSlot: selection.timeSlot,
      locationId: selection.itemData.id,
      locationName: selection.itemData.name,
      emoji: selection.itemData.emoji,
      imageUrl: selection.itemData.imageUrl,
      estimatedDuration: selection.itemData.estimatedDuration,
      estimatedDurationMin: selection.itemData.estimatedDurationMin,
      destinationId: selection.itemData.destinationId,
      destinationName: selection.itemData.destinationName,
      addedAt: DateTime.now(),
    );
  }

  /// Human-readable day label (1-based).
  String get dayLabel => 'Ngày ${dayIndex + 1}';

  /// Human-readable time slot label.
  String get timeSlotLabel => timeSlot.label;

  /// Create a copy with optional field overrides.
  PendingActivity copyWith({
    String? id,
    int? dayIndex,
    TimeSlot? timeSlot,
    String? locationId,
    String? locationName,
    String? emoji,
    String? imageUrl,
    String? estimatedDuration,
    int? estimatedDurationMin,
    String? destinationId,
    String? destinationName,
    DateTime? addedAt,
  }) {
    return PendingActivity(
      id: id ?? this.id,
      dayIndex: dayIndex ?? this.dayIndex,
      timeSlot: timeSlot ?? this.timeSlot,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      emoji: emoji ?? this.emoji,
      imageUrl: imageUrl ?? this.imageUrl,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      estimatedDurationMin: estimatedDurationMin ?? this.estimatedDurationMin,
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PendingActivity &&
        other.id == id &&
        other.dayIndex == dayIndex &&
        other.timeSlot == timeSlot &&
        other.locationId == locationId;
  }

  @override
  int get hashCode => Object.hash(id, dayIndex, timeSlot, locationId);

  @override
  String toString() =>
      'PendingActivity(id: $id, day: $dayLabel, timeSlot: $timeSlotLabel, '
      'location: $locationName)';
}
