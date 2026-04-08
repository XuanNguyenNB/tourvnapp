import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
class ActivityCard extends StatefulWidget {
  /// Creates an activity card.
  const ActivityCard({
    super.key,
    required this.activity,
    this.onTap,
    this.onLongPress,
    this.onCompletionToggle,
    this.showMapButton = false,
  });

  /// The activity to display.
  final Activity activity;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when the card is long-pressed.
  final VoidCallback? onLongPress;

  /// Callback when the completion checkbox is toggled.
  /// Receives the new completion status.
  final ValueChanged<bool>? onCompletionToggle;

  /// Whether to show the "Open in Maps" button.
  final bool showMapButton;

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  bool _notesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final hasNotes = activity.notes != null && activity.notes!.trim().isNotEmpty;
    final cleanedNotes = hasNotes
        ? activity.notes!.replaceAll(RegExp(r'\[\d+\]'), '').trim()
        : '';
    final isCompleted = activity.isCompleted;
    final showCheckbox = widget.onCompletionToggle != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isCompleted ? 0.65 : 1.0,
      child: Material(
        color: isCompleted ? Colors.green.shade50 : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: widget.onTap,
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
                // Top row: Time slot chip + checkbox
                Row(
                  children: [
                    _TimeSlotChip(timeSlot: activity.timeSlot),
                    const Spacer(),
                    if (showCheckbox)
                      _CompletionCheckbox(
                        isCompleted: isCompleted,
                        onToggle: widget.onCompletionToggle!,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                // Activity name
                Text(
                  activity.locationName,
                  style: isCompleted
                      ? AppTypography.headingMD.copyWith(
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.grey.shade400,
                          color: Colors.grey.shade500,
                        )
                      : AppTypography.headingMD,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Destination tag
                if (activity.destinationName != null) ...[
                  const SizedBox(height: 2),
                  _DestinationTag(destinationName: activity.destinationName!),
                ],
                // Duration row
                if (activity.estimatedDuration != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _DurationRow(duration: activity.estimatedDuration!),
                ],
                // Open in Maps button
                if (widget.showMapButton) ...[
                  const SizedBox(height: 6),
                  _MapButton(
                    locationName: activity.locationName,
                    destinationName: activity.destinationName,
                  ),
                ],
                // AI notes with expand/collapse
                if (hasNotes) ...[
                  const SizedBox(height: 6),
                  AnimatedCrossFade(
                    firstChild: Text(
                      cleanedNotes,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondChild: Text(
                      cleanedNotes,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    crossFadeState: _notesExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _notesExpanded = !_notesExpanded),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _notesExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _notesExpanded ? 'Thu gọn' : 'Xem thêm',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handle long-press with haptic feedback.
  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    widget.onLongPress?.call();
  }
}

/// Completion checkbox widget with animated checkmark.
class _CompletionCheckbox extends StatelessWidget {
  const _CompletionCheckbox({
    required this.isCompleted,
    required this.onToggle,
  });

  final bool isCompleted;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onToggle(!isCompleted);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isCompleted ? Colors.green : Colors.transparent,
          border: Border.all(
            color: isCompleted ? Colors.green : Colors.grey.shade400,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: isCompleted
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
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

/// Compact button to open the activity location in Google Maps.
///
/// Uses Google Maps search URL with location name + destination name
/// for accurate results without requiring stored coordinates.
class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.locationName,
    this.destinationName,
  });

  final String locationName;
  final String? destinationName;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openInMaps(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFBFDBFE), width: 0.5),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 14, color: Color(0xFF2563EB)),
            SizedBox(width: 4),
            Text(
              'Mở bản đồ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2563EB),
              ),
            ),
            SizedBox(width: 2),
            Icon(Icons.open_in_new, size: 10, color: Color(0xFF2563EB)),
          ],
        ),
      ),
    );
  }

  Future<void> _openInMaps() async {
    HapticFeedback.lightImpact();

    // Build search query: "locationName, destinationName"
    final query = destinationName != null
        ? '$locationName, $destinationName'
        : locationName;
    final encodedQuery = Uri.encodeComponent(query);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedQuery',
    );

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Fallback: try platform default mode
      try {
        await launchUrl(uri);
      } catch (_) {
        // Silently fail — user will see nothing happen
      }
    }
  }
}
