/// Time slot options for trip planning.
///
/// Each time slot represents a period of the day when
/// a location can be visited during a trip.
enum TimeSlot {
  morning('Sáng', '🌅'),
  noon('Trưa', '☀️'),
  afternoon('Chiều', '🌤️'),
  evening('Tối', '🌙');

  /// Display label in Vietnamese.
  final String label;

  /// Emoji representation of the time slot.
  final String emoji;

  const TimeSlot(this.label, this.emoji);

  /// Get display text combining emoji and label.
  String get displayText => '$emoji $label';
}
