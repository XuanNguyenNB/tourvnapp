import 'package:flutter/material.dart';

/// Horizontal scrollable list of day pills for trip planning.
///
/// Displays Day 1, Day 2, Day 3... with "+ Thêm ngày" button at the end.
/// Use [GlobalKey<DayPillsListState>] to access [scrollToLast] method.
class DayPillsList extends StatefulWidget {
  /// List of day indices to display.
  final List<int> days;

  /// Currently selected day index.
  final int selectedDay;

  /// Callback when a day is selected.
  final ValueChanged<int> onDaySelected;

  /// Callback when "Add new day" is tapped.
  final VoidCallback onAddNewDay;

  const DayPillsList({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onAddNewDay,
  });

  @override
  State<DayPillsList> createState() => DayPillsListState();
}

/// State for [DayPillsList] with scroll control.
class DayPillsListState extends State<DayPillsList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll to the last day pill (for auto-scroll after adding new day).
  void scrollToLast() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn ngày',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.days.length + 1, // +1 for "Add new day" button
            itemBuilder: (context, index) {
              if (index == widget.days.length) {
                return _AddNewDayButton(onTap: widget.onAddNewDay);
              }
              return Padding(
                padding: EdgeInsets.only(
                  right: index < widget.days.length ? 8 : 0,
                ),
                child: _DayPill(
                  dayIndex: index,
                  isSelected: widget.selectedDay == index,
                  onTap: () => widget.onDaySelected(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Individual day pill widget.
class _DayPill extends StatelessWidget {
  final int dayIndex;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayPill({
    required this.dayIndex,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          'Ngày ${dayIndex + 1}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

/// Button to add a new day to the list.
class _AddNewDayButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddNewDayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: Color(0xFF8B5CF6)),
            SizedBox(width: 4),
            Text(
              'Thêm ngày',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
