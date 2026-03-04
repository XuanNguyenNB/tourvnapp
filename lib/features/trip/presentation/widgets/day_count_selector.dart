import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/trip_creation_provider.dart';

/// A widget for selecting trip dates using a date range picker.
///
/// Shows quick-select chips for common durations and a calendar picker.
class DayCountSelector extends ConsumerWidget {
  const DayCountSelector({super.key});

  static const _presetDays = [2, 3, 5, 7];

  /// Format day count as Vietnamese travel format.
  static String formatDays(int days) {
    if (days <= 1) return '1 ngày (đi về trong ngày)';
    return '$days ngày ${days - 1} đêm';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripCreationProvider);
    final notifier = ref.read(tripCreationProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date display / picker trigger
          _DateRangeDisplay(
            startDate: state.startDate,
            endDate: state.endDate,
            dayCount: state.dayCount,
            onTap: () => _pickDateRange(context, ref, state),
          ),

          const SizedBox(height: 12),

          // Quick-select chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._presetDays.map((days) {
                final isSelected = state.dayCount == days && !state.hasDates;
                return _QuickChip(
                  label: '$days ngày',
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    notifier.clearDates();
                    notifier.setDayCount(days);
                  },
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(
    BuildContext context,
    WidgetRef ref,
    TripCreationState state,
  ) async {
    final now = DateTime.now();
    final initialStart = state.startDate ?? now;
    final initialEnd =
        state.endDate ?? now.add(Duration(days: state.dayCount - 1));

    final result = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      locale: const Locale('vi', 'VN'),
      helpText: 'Chọn ngày đi & ngày về',
      cancelText: 'Huỷ',
      confirmText: 'Xong',
      saveText: 'Xong',
      fieldStartHintText: 'Ngày đi',
      fieldEndHintText: 'Ngày về',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      ref
          .read(tripCreationProvider.notifier)
          .setDateRange(result.start, result.end);
    }
  }
}

/// Displays the selected date range or a prompt to pick dates.
class _DateRangeDisplay extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final int dayCount;
  final VoidCallback onTap;

  const _DateRangeDisplay({
    required this.startDate,
    required this.endDate,
    required this.dayCount,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasDates = startDate != null && endDate != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: hasDates
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDates ? AppColors.primary : Colors.grey.shade300,
            width: hasDates ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: hasDates ? AppColors.primary : Colors.grey.shade500,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: hasDates
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_formatDate(startDate!)} → ${_formatDate(endDate!)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DayCountSelector.formatDays(dayCount),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Chọn ngày đi cụ thể (tuỳ chọn)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: hasDates ? AppColors.primary : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small quick-select chip for preset day counts.
class _QuickChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
