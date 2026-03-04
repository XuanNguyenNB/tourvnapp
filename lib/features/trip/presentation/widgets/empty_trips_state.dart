import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_radius.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';
import 'package:tour_vn/core/widgets/gradient_button.dart';

/// EmptyTripsState - Empty state display for Trips screen.
///
/// Shows different content based on user authentication status:
/// - Signed-in users: "Chưa có chuyến đi nào" with explore CTA
/// - Anonymous users: Sign-in prompt to save trips
///
/// Design specs:
/// - Centered content with illustration
/// - Clear messaging and CTA button
/// - Haptic feedback on interactions
class EmptyTripsState extends StatelessWidget {
  /// Whether the user is currently signed in.
  final bool isSignedIn;

  /// Callback when "Khám phá ngay" button is tapped.
  final VoidCallback? onExplore;

  /// Callback when "Lên lịch trình với AI" button is tapped.
  final VoidCallback? onAutoPlan;

  /// Callback when "Đăng nhập" button is tapped.
  final VoidCallback? onSignIn;

  const EmptyTripsState({
    super.key,
    required this.isSignedIn,
    this.onExplore,
    this.onAutoPlan,
    this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Illustration
              _buildIllustration(),
              const SizedBox(height: AppSpacing.lg),
              // Title
              Text(
                isSignedIn
                    ? 'Lên kế hoạch thông minh trong vài giây!'
                    : 'Đăng nhập để lưu chuyến đi',
                style: AppTypography.headingLG.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              // Subtitle
              Text(
                isSignedIn
                    ? 'Hãy để AI tối ưu lịch trình để bạn thả ga khám phá!'
                    : 'Đăng nhập để lưu và quản lý các chuyến đi của bạn!',
                style: AppTypography.bodyMD.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              // Buttons
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          isSignedIn ? Icons.auto_awesome : Icons.lock_outline,
          size: 56,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildButtons() {
    if (!isSignedIn) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: GradientButton(
          text: 'Đăng nhập',
          onPressed: () {
            HapticFeedback.lightImpact();
            onSignIn?.call();
          },
          icon: const Icon(Icons.login_outlined, color: Colors.white, size: 20),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48, // Explicit height to avoid test constraint issues
          child: GradientButton(
            text: '✨ Lên lịch trình với AI',
            onPressed: () {
              HapticFeedback.lightImpact();
              onAutoPlan?.call();
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onExplore?.call();
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            child: Text(
              'Tự tạo thủ công',
              style: AppTypography.labelMD.copyWith(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
