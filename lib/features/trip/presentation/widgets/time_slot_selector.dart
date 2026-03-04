import 'package:flutter/material.dart';
import '../../domain/entities/time_slot.dart';

/// Time slot selector for trip planning.
///
/// Displays 4 time slots: Sáng, Trưa, Chiều, Tối
/// with corresponding emojis.
class TimeSlotSelector extends StatelessWidget {
  /// Currently selected time slot (nullable).
  final TimeSlot? selectedTimeSlot;

  /// Callback when a time slot is selected.
  final ValueChanged<TimeSlot> onTimeSlotSelected;

  const TimeSlotSelector({
    super.key,
    required this.selectedTimeSlot,
    required this.onTimeSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn thời gian',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TimeSlot.values.map((slot) {
            return _TimeSlotChip(
              slot: slot,
              isSelected: selectedTimeSlot == slot,
              onTap: () => onTimeSlotSelected(slot),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Individual time slot chip widget.
class _TimeSlotChip extends StatelessWidget {
  final TimeSlot slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeSlotChip({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(slot.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              slot.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
