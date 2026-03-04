import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 404 Error screen displayed when navigating to an invalid route.
///
/// Dùng theme tokens thay vì hardcoded colors để hỗ trợ dark mode.
class NotFoundScreen extends StatelessWidget {
  /// Optional error message to display
  final String? errorMessage;

  const NotFoundScreen({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Không tìm thấy trang')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: AppColors.error),
              SizedBox(height: AppSpacing.lg),
              Text(
                '404',
                style: AppTypography.headingXL.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Không tìm thấy trang',
                style: AppTypography.headingMD.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Trang bạn đang tìm kiếm không tồn tại',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMD.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (errorMessage != null) ...[
                SizedBox(height: AppSpacing.md),
                Text(
                  'Chi tiết: $errorMessage',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySM.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Về trang chủ'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
