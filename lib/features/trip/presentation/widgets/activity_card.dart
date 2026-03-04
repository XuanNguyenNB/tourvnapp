import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/time_slot.dart';

/// Activity card for the Visual Planner timeline.
///
/// Displays:
/// - Time slot chip (Sáng, Trưa, Chiều, Tối)
/// - Activity/Location name
/// - Optional estimated duration
///
/// Uses a simple elevated card design instead of GlassCard
/// for better performance in lists. GlassCard causes
/// performance issues when used in scrolling lists due to
/// the BackdropFilter.
class ActivityCard extends StatelessWidget {
  /// Creates an activity card.
  const ActivityCard({
    super.key,
    required this.activity,
    this.onTap,
    this.onLongPress,
  });

  /// The activity to display.
  final Activity activity;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when the card is long-pressed.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        onLongPress: _handleLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Time slot chip
              _TimeSlotChip(timeSlot: activity.timeSlot),
              const SizedBox(height: AppSpacing.xs),
              // Activity name - constrain to 1 line to prevent overflow
              Text(
                activity.locationName,
                style: AppTypography.headingMD,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Destination tag (only if destination info exists)
              if (activity.destinationName != null) ...[
                const SizedBox(height: 2),
                _DestinationTag(destinationName: activity.destinationName!),
              ],
              // Duration row (conditional)
              if (activity.estimatedDuration != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _DurationRow(duration: activity.estimatedDuration!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Handle long-press with haptic feedback.
  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    onLongPress?.call();
  }
}

/// Time slot indicator chip.
class _TimeSlotChip extends StatelessWidget {
  const _TimeSlotChip({required this.timeSlot});

  final String timeSlot;

  @override
  Widget build(BuildContext context) {
    final slot = _parseTimeSlot(timeSlot);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(slot.emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            slot.label,
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Parse time slot string to TimeSlot enum.
  TimeSlot _parseTimeSlot(String value) {
    switch (value.toLowerCase()) {
      case 'morning':
        return TimeSlot.morning;
      case 'noon':
        return TimeSlot.noon;
      case 'afternoon':
        return TimeSlot.afternoon;
      case 'evening':
        return TimeSlot.evening;
      default:
        return TimeSlot.morning;
    }
  }
}

/// Duration indicator row with clock icon.
///
/// Formats duration string to Vietnamese display format:
/// - "30m" → "~30 phút"
/// - "1h" → "~1 giờ"
/// - "1h30m" → "~1 giờ 30 phút"
class _DurationRow extends StatelessWidget {
  const _DurationRow({required this.duration});

  final String duration;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          _formatDuration(duration),
          style: AppTypography.bodySM.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  /// Format duration string to Vietnamese display format.
  ///
  /// Input examples: "30m", "1h", "1h30m", "2h"
  /// Output examples: "~30 phút", "~1 giờ", "~1 giờ 30 phút", "~2 giờ"
  String _formatDuration(String duration) {
    // Already formatted (contains Vietnamese)
    if (duration.contains('giờ') || duration.contains('phút')) {
      return duration.startsWith('~') ? duration : '~$duration';
    }

    // Parse compact format
    final hourMatch = RegExp(r'(\d+)h').firstMatch(duration);
    final minuteMatch = RegExp(r'(\d+)m').firstMatch(duration);

    final hours = hourMatch != null ? int.parse(hourMatch.group(1)!) : 0;
    final minutes = minuteMatch != null ? int.parse(minuteMatch.group(1)!) : 0;

    if (hours > 0 && minutes > 0) {
      return '~$hours giờ $minutes phút';
    } else if (hours > 0) {
      return '~$hours giờ';
    } else if (minutes > 0) {
      return '~$minutes phút';
    }

    // Fallback: return as-is with prefix
    return '~$duration';
  }
}

/// Destination tag showing which destination an activity belongs to.
///
/// Displays the destination name with a location pin emoji.
/// Uses muted styling to not compete with main activity info.
class _DestinationTag extends StatelessWidget {
  const _DestinationTag({required this.destinationName});

  final String destinationName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('📍', style: TextStyle(fontSize: 11)),
        const SizedBox(width: 3),
        Text(
          destinationName,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
