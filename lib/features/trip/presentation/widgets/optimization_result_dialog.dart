import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';
import 'package:tour_vn/features/trip/domain/entities/schedule_optimization_result.dart';

class OptimizationResultDialog extends StatelessWidget {
  const OptimizationResultDialog({
    super.key,
    required this.result,
    required this.onApply,
    required this.onCancel,
  });

  final ScheduleOptimizationResult result;
  final VoidCallback onApply;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    if (!result.hasChanges) {
      return const SizedBox.shrink(); // Should not be shown if no changes
    }

    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 40),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tối ưu Lịch trình bằng AI',
            style: AppTypography.headingMD.copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Chúng tôi đã tìm ra cách sắp xếp lịch trình tốt hơn cho bạn!',
              style: AppTypography.bodyMD.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            // Savings Highlights
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildHighlightCard(
                  icon: Icons.directions_car,
                  value: '${result.totalDistanceSavedKm.toInt()} km',
                  label: 'Tiết kiệm',
                  color: Colors.blue,
                ),
                _buildHighlightCard(
                  icon: Icons.access_time,
                  value: '${result.totalTravelTimeSavedMin} phút',
                  label: 'Tiết kiệm',
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tóm tắt thay đổi:',
              style: AppTypography.labelMD.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...result.changes.take(3).map((change) {
              final isSameDay = change.fromDay == change.toDay;
              final text = isSameDay
                  ? 'Sắp xếp lại ${change.activityName} trong Ngày ${change.fromDay}'
                  : 'Chuyển ${change.activityName} từ Ngày ${change.fromDay} sang Ngày ${change.toDay}';

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.swap_horiz,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: Text(text, style: AppTypography.bodySM)),
                  ],
                ),
              );
            }),
            if (result.changes.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Và ${result.changes.length - 3} thay đổi khác...',
                  style: AppTypography.bodySM.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () {
            onCancel();
            Navigator.of(context).pop();
          },
          child: Text(
            'Hủy',
            style: AppTypography.labelMD.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            onApply();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
          ),
          child: Text(
            'Áp dụng',
            style: AppTypography.labelMD.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTypography.headingMD.copyWith(color: color)),
          Text(
            label,
            style: AppTypography.bodySM.copyWith(color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
