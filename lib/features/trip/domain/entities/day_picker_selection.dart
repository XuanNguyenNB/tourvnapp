import 'time_slot.dart';
import '../../presentation/widgets/add_to_trip_gesture_wrapper.dart';

/// Result of day picker selection.
///
/// Used to pass data back to caller for trip integration.
/// Contains the selected day index, time slot, and the item being added.
class DayPickerSelection {
  /// The selected day index (0-based).
  final int dayIndex;

  /// The selected time slot.
  final TimeSlot timeSlot;

  /// Data about the item being added to the trip.
  final TripItemData itemData;

  const DayPickerSelection({
    required this.dayIndex,
    required this.timeSlot,
    required this.itemData,
  });

  /// Human-readable day label (1-based).
  String get dayLabel => 'Ngày ${dayIndex + 1}';

  /// Human-readable time slot label.
  String get timeSlotLabel => timeSlot.label;

  @override
  String toString() =>
      'DayPickerSelection(day: $dayLabel, timeSlot: $timeSlotLabel)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DayPickerSelection &&
        other.dayIndex == dayIndex &&
        other.timeSlot == timeSlot &&
        other.itemData.id == itemData.id;
  }

  @override
  int get hashCode => Object.hash(dayIndex, timeSlot, itemData.id);
}
