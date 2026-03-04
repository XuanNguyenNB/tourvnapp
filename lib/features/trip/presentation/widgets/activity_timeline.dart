import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/activity.dart';
import 'activity_card.dart';
import 'timeline_connector.dart';

/// Vertical timeline displaying activities for a day with drag-to-reorder.
///
/// Shows activity cards connected by dotted lines.
/// Each activity has an emoji marker on the left side.
/// Activities can be reordered via long-press and drag.
/// Activities can be deleted via swipe-to-delete.
class ActivityTimeline extends StatelessWidget {
  /// Creates an activity timeline.
  const ActivityTimeline({
    super.key,
    required this.activities,
    this.onActivityTap,
    this.onActivityLongPress,
    this.onActivityDelete,
    this.onReorder,
  });

  /// List of activities to display (pre-sorted by time slot).
  final List<Activity> activities;

  /// Callback when an activity card is tapped.
  final ValueChanged<Activity>? onActivityTap;

  /// Callback when an activity card is long-pressed.
  final ValueChanged<Activity>? onActivityLongPress;

  /// Callback when an activity is dismissed (swipe-to-delete).
  /// Returns Future<bool> - true if delete succeeded, false to cancel dismiss.
  /// This allows saved trips to cancel the dismiss animation.
  final Future<bool> Function(Activity)? onActivityDelete;

  /// Callback when activities are reordered.
  /// Called with (oldIndex, newIndex) after index adjustment.
  final void Function(int oldIndex, int newIndex)? onReorder;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: activities.length,
      onReorder: _handleReorder,
      onReorderStart: (_) => HapticFeedback.selectionClick(),
      onReorderEnd: (_) => HapticFeedback.lightImpact(),
      proxyDecorator: _buildProxyDecorator,
      itemBuilder: (context, index) {
        final activity = activities[index];
        final isFirst = index == 0;
        final isLast = index == activities.length - 1;

        return _TimelineItem(
          key: ValueKey(activity.id),
          activity: activity,
          isFirst: isFirst,
          isLast: isLast,
          onTap: onActivityTap != null ? () => onActivityTap!(activity) : null,
          onLongPress: onActivityLongPress != null
              ? () => onActivityLongPress!(activity)
              : null,
          onDelete: onActivityDelete != null
              ? () => onActivityDelete!(activity)
              : null,
        );
      },
    );
  }

  /// Handle reorder with index adjustment for Flutter behavior.
  void _handleReorder(int oldIndex, int newIndex) {
    // Flutter's ReorderableListView adjusts newIndex when moving down
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    // Skip if no actual position change
    if (oldIndex == newIndex) return;

    onReorder?.call(oldIndex, newIndex);
  }

  /// Build proxy decorator for lifted card appearance during drag.
  Widget _buildProxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Scale from 1.0 to 1.02 during drag
        final scale = lerpDouble(1.0, 1.02, animation.value)!;
        // Elevation from 2 to 8 during drag
        final elevation = lerpDouble(2.0, 8.0, animation.value)!;

        return Transform.scale(
          scale: scale,
          child: Material(
            elevation: elevation,
            borderRadius: BorderRadius.circular(12),
            shadowColor: AppColors.primary.withOpacity(0.3),
            color: Colors.transparent,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Individual timeline item with connector and card.
class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    super.key,
    required this.activity,
    required this.isFirst,
    required this.isLast,
    this.onTap,
    this.onLongPress,
    this.onDelete,
  });

  final Activity activity;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Returns true if delete succeeded, false to cancel dismiss animation.
  final Future<bool> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    // Use Material with constrained height for ReorderableListView compatibility
    // Height 120 accommodates card content without overflow
    return Material(
      color: Colors.transparent,
      child: Container(
        height:
            145, // Fixed height for timeline items (accommodates chip + name + destination + duration)
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline connector with emoji
            TimelineConnector(
              emoji: activity.emoji ?? '📍',
              isFirst: isFirst,
              isLast: isLast,
            ),
            const SizedBox(width: AppSpacing.sm),
            // Activity card with swipe-to-delete
            Expanded(child: _buildDismissibleCard()),
          ],
        ),
      ),
    );
  }

  /// Build dismissible wrapper for activity card.
  Widget _buildDismissibleCard() {
    if (onDelete == null) {
      // No delete handler, just return the card
      return ActivityCard(
        activity: activity,
        onTap: onTap,
        onLongPress: onLongPress,
      );
    }

    return Dismissible(
      key: Key('dismiss_${activity.id}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.4},
      movementDuration: const Duration(milliseconds: 250),
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        // Call the delete handler and await the result
        // If it returns false, the dismiss is cancelled
        return await onDelete?.call() ?? false;
      },
      background: _buildDeleteBackground(),
      child: ActivityCard(
        activity: activity,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  /// Build red delete background for swipe action.
  Widget _buildDeleteBackground() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete, color: Colors.white, size: 24),
          SizedBox(width: 8),
          Text(
            'Xóa',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
