import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Widget hiển thị badge cảnh báo xung đột đích đến cho một ngày.
///
/// Hiển thị icon ⚠️ và text "Đa điểm đến" với màu amber khi ngày
/// có hoạt động từ nhiều điểm đến khác nhau.
class MultiDestinationBadge extends StatelessWidget {
  /// Creates a multi-destination warning badge.
  const MultiDestinationBadge({super.key, this.compact = false});

  /// If true, shows only the emoji without text.
  /// Used in DayPillsSelector for space efficiency.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text('⚠️', style: TextStyle(fontSize: 10)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            'Đa điểm đến',
            style: TextStyle(
              fontSize: 12,
              color: Colors.amber.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị cảnh báo thời gian di chuyển giữa các điểm đến.
///
/// Được hiển thị dưới ActivityCard khi hoạt động đó từ một điểm đến
/// khác với điểm đến trước đó trong cùng ngày.
class TravelTimeWarning extends StatelessWidget {
  /// Creates a travel time warning.
  const TravelTimeWarning({
    super.key,
    required this.fromDestination,
    required this.travelTimeMinutes,
  });

  /// The destination user is coming from.
  final String fromDestination;

  /// Estimated travel time in minutes.
  final int travelTimeMinutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.amber.shade200, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            'Cần di chuyển ~${_formatTime(travelTimeMinutes)} từ $fromDestination',
            style: AppTypography.bodySM.copyWith(
              color: Colors.amber.shade800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Format minutes to readable time string.
  String _formatTime(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins > 0) {
        return '${hours}h${mins}p';
      }
      return '${hours}h';
    }
    return '${minutes}p';
  }
}

/// Banner gợi ý tối ưu hóa lịch trình.
///
/// Hiển thị khi một ngày có nhiều điểm đến, gợi ý người dùng
/// có thể di chuyển hoạt động sang ngày khác phù hợp hơn.
class OptimizationSuggestionBanner extends StatefulWidget {
  /// Creates an optimization suggestion banner.
  const OptimizationSuggestionBanner({
    super.key,
    required this.activityName,
    this.suggestedDayNumber,
    this.onOptimize,
    this.onDismiss,
  });

  /// Name of the activity that could be moved.
  final String activityName;

  /// Suggested day number to move the activity to.
  /// If null, shows generic suggestion.
  final int? suggestedDayNumber;

  /// Callback when user taps "Tối ưu lịch trình" button.
  final VoidCallback? onOptimize;

  /// Callback when user dismisses the banner.
  final VoidCallback? onDismiss;

  @override
  State<OptimizationSuggestionBanner> createState() =>
      _OptimizationSuggestionBannerState();
}

class _OptimizationSuggestionBannerState
    extends State<OptimizationSuggestionBanner> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    final suggestionText = widget.suggestedDayNumber != null
        ? 'Gợi ý: Chuyển "${widget.activityName}" sang Ngày ${widget.suggestedDayNumber}'
        : 'Gợi ý: Có thể điều chỉnh lịch trình để tối ưu di chuyển';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  suggestionText,
                  style: AppTypography.bodySM.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _isDismissed = true);
                  widget.onDismiss?.call();
                },
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() => _isDismissed = true);
                  widget.onDismiss?.call();
                },
                child: Text(
                  'Để nguyên',
                  style: AppTypography.bodySM.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.onOptimize != null)
                TextButton(
                  onPressed: widget.onOptimize,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  child: Text(
                    'Tối ưu lịch trình',
                    style: AppTypography.bodySM.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
