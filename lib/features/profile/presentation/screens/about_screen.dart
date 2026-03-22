import 'package:flutter/material.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_radius.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';

/// About Screen - Shows app information
///
/// Features:
/// - App logo and name
/// - Version info
/// - Brief app description
/// - Developer credits
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Về TourVN'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),

            // App icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.explore,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // App name
            Text('TourVN', style: AppTypography.headingXL),
            const SizedBox(height: AppSpacing.xs),

            // Version
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                'Phiên bản 1.0.0',
                style: AppTypography.bodySM.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Giới thiệu', style: AppTypography.headingMD),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'TourVN là ứng dụng hỗ trợ khám phá du lịch Việt Nam, '
                    'giúp bạn tìm kiếm địa điểm, lập kế hoạch chuyến đi, '
                    'và nhận gợi ý cá nhân hoá dựa trên sở thích và vị trí.',
                    style: AppTypography.bodyMD.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Features
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tính năng chính', style: AppTypography.headingMD),
                  const SizedBox(height: AppSpacing.sm),
                  _FeatureItem(
                    icon: Icons.explore,
                    text: 'Khám phá địa điểm du lịch',
                  ),
                  _FeatureItem(
                    icon: Icons.auto_awesome,
                    text: 'Gợi ý AI cá nhân hoá',
                  ),
                  _FeatureItem(
                    icon: Icons.map_outlined,
                    text: 'Lập kế hoạch chuyến đi',
                  ),
                  _FeatureItem(
                    icon: Icons.near_me,
                    text: 'Tìm kiếm theo vị trí',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Credits
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thông tin', style: AppTypography.headingMD),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(label: 'Phát triển bởi', value: 'Tạ Xuân Nguyên'),
                  _InfoRow(label: 'Đồ án tốt nghiệp', value: 'K15 CNTT1'),
                  _InfoRow(label: 'Framework', value: 'Flutter'),
                  _InfoRow(label: 'Backend', value: 'Firebase'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Footer
            Text(
              '© 2026 TourVN. All rights reserved.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: AppTypography.bodySM),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySM.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(value, style: AppTypography.bodySM),
        ],
      ),
    );
  }
}
