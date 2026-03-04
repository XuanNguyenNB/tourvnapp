import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Horizontal day selector pills for Visual Planner.
///
/// Displays pills for each day of the trip. The selected day
/// is highlighted with primary color. Pills are horizontally
/// scrollable for trips with many days.
///
/// Features:
/// - Horizontal scroll when days exceed screen width
/// - Animated selection transition
/// - Scroll-to-selected when day changes externally
/// - Warning badge for days with multi-destination conflicts
class DayPillsSelector extends StatefulWidget {
  /// Creates a day pills selector.
  const DayPillsSelector({
    super.key,
    required this.totalDays,
    required this.selectedDay,
    required this.onDaySelected,
    this.conflictDays = const {},
  });

  /// Total number of days in the trip.
  final int totalDays;

  /// Currently selected day number (1-based).
  final int selectedDay;

  /// Callback when a day is tapped.
  final ValueChanged<int> onDaySelected;

  /// Set of day numbers (1-based) that have multi-destination conflicts.
  /// Pills for these days will show a warning badge.
  final Set<int> conflictDays;

  @override
  State<DayPillsSelector> createState() => _DayPillsSelectorState();
}

class _DayPillsSelectorState extends State<DayPillsSelector> {
  late ScrollController _scrollController;

  // Pill dimensions for scroll calculation
  static const double _pillWidth = 80.0;
  static const double _pillGap = AppSpacing.sm;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected(animate: false);
    });
  }

  @override
  void didUpdateWidget(DayPillsSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDay != widget.selectedDay) {
      _scrollToSelected(animate: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll to make selected pill visible (centered if possible).
  void _scrollToSelected({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    final selectedIndex = widget.selectedDay - 1;
    final itemOffset = selectedIndex * (_pillWidth + _pillGap);
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset = itemOffset - (screenWidth / 2) + (_pillWidth / 2);

    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if (animate) {
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(clampedOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: widget.totalDays,
        separatorBuilder: (_, __) => const SizedBox(width: _pillGap),
        itemBuilder: (context, index) {
          final dayNumber = index + 1;
          final isSelected = dayNumber == widget.selectedDay;

          final hasConflict = widget.conflictDays.contains(dayNumber);

          return _DayPill(
            dayNumber: dayNumber,
            isSelected: isSelected,
            hasConflict: hasConflict,
            onTap: () => widget.onDaySelected(dayNumber),
          );
        },
      ),
    );
  }
}

/// Individual day pill widget.
///
/// Shows a warning badge when the day has activities from multiple destinations.
class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.dayNumber,
    required this.isSelected,
    required this.onTap,
    this.hasConflict = false,
  });

  final int dayNumber;
  final bool isSelected;
  final VoidCallback onTap;

  /// Whether this day has activities from multiple destinations.
  final bool hasConflict;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: isSelected
                  ? null
                  : Border.all(
                      color: hasConflict
                          ? Colors.amber.shade400
                          : AppColors.border,
                      width: hasConflict ? 2 : 1,
                    ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              'Ngày $dayNumber',
              style: AppTypography.labelMD.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          // Warning badge for multi-destination conflicts
          if (hasConflict)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                alignment: Alignment.center,
                child: const Text('⚠️', style: TextStyle(fontSize: 9)),
              ),
            ),
        ],
      ),
    );
  }
}
