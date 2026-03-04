import 'package:flutter/material.dart';
import 'package:tour_vn/core/exceptions/app_exception.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_radius.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';
import 'package:tour_vn/core/widgets/app_error_widget.dart';
import 'package:tour_vn/core/widgets/glass_card.dart';
import 'package:tour_vn/core/widgets/gradient_button.dart';
import 'package:tour_vn/core/widgets/shimmer_placeholder.dart';

/// Demo screen showcasing all core reusable widgets.
///
/// Demonstrates:
/// - GlassCard with different content and configurations
/// - GradientButton in all states (normal, disabled, loading)
/// - ShimmerPlaceholder in different sizes and shapes
/// - AppErrorWidget with sample AppException
class CoreWidgetsDemoScreen extends StatefulWidget {
  const CoreWidgetsDemoScreen({super.key});

  @override
  State<CoreWidgetsDemoScreen> createState() => _CoreWidgetsDemoScreenState();
}

class _CoreWidgetsDemoScreenState extends State<CoreWidgetsDemoScreen> {
  bool _isLoading = false;

  void _simulateLoading() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Core Widgets Demo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          // Section: GlassCard
          _buildSectionTitle('1. GlassCard - Glassmorphism'),
          SizedBox(height: AppSpacing.md),
          _buildGlassCardDemo(),
          SizedBox(height: AppSpacing.xl),

          // Section: GradientButton
          _buildSectionTitle('2. GradientButton - All States'),
          SizedBox(height: AppSpacing.md),
          _buildGradientButtonDemo(),
          SizedBox(height: AppSpacing.xl),

          // Section: ShimmerPlaceholder
          _buildSectionTitle('3. ShimmerPlaceholder - Loading States'),
          SizedBox(height: AppSpacing.md),
          _buildShimmerDemo(),
          SizedBox(height: AppSpacing.xl),

          // Section: AppErrorWidget
          _buildSectionTitle('4. AppErrorWidget - Error Display'),
          SizedBox(height: AppSpacing.md),
          _buildErrorWidgetDemo(),
          SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.headingLG.copyWith(color: AppColors.primary),
    );
  }

  Widget _buildGlassCardDemo() {
    return Stack(
      children: [
        // Background image to show glass effect
        Container(
          height: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        // Glass cards on top
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: GlassCard(
            padding: EdgeInsets.all(AppSpacing.lg),
            borderRadius: AppRadius.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đà Lạt',
                  style: AppTypography.headingLG.copyWith(color: Colors.white),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Thành phố ngàn hoa với khí hậu mát mẻ quanh năm',
                  style: AppTypography.bodySM.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: GlassCard(
            padding: EdgeInsets.all(AppSpacing.md),
            borderRadius: AppRadius.md,
            child: Row(
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 20),
                SizedBox(width: AppSpacing.sm),
                Text(
                  '1,234 lượt thích',
                  style: AppTypography.bodySM.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButtonDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Normal state
        GradientButton(
          text: 'Normal Button',
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Button pressed!')));
          },
        ),
        SizedBox(height: AppSpacing.md),

        // With icon
        GradientButton(
          text: 'Button với Icon',
          icon: const Icon(Icons.explore, color: Colors.white),
          onPressed: () {},
        ),
        SizedBox(height: AppSpacing.md),

        // Disabled state
        const GradientButton(text: 'Disabled Button', onPressed: null),
        SizedBox(height: AppSpacing.md),

        // Loading state
        GradientButton(
          text: 'Loading Button',
          isLoading: _isLoading,
          onPressed: _simulateLoading,
        ),
      ],
    );
  }

  Widget _buildShimmerDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card shimmer
        const ShimmerPlaceholder.card(height: 150),
        SizedBox(height: AppSpacing.md),

        // Row with circle and lines (like user profile)
        Row(
          children: [
            const ShimmerPlaceholder.circle(diameter: 50),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerPlaceholder.line(width: 150, height: 16),
                  SizedBox(height: AppSpacing.sm),
                  const ShimmerPlaceholder.line(width: 100, height: 14),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),

        // Custom shimmer
        const ShimmerPlaceholder(
          width: double.infinity,
          height: 80,
          borderRadius: 16,
        ),
      ],
    );
  }

  Widget _buildErrorWidgetDemo() {
    return Column(
      children: [
        // Error without retry
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: AppErrorWidget(
            error: AppException(
              code: 'DEMO_ERROR',
              message:
                  'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng kiểm tra kết nối mạng.',
            ),
          ),
        ),
        SizedBox(height: AppSpacing.lg),

        // Error with retry
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: AppErrorWidget(
            error: AppException(
              code: 'NETWORK_ERROR',
              message: 'Không thể kết nối đến máy chủ. Vui lòng thử lại.',
            ),
            onRetry: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Đang thử lại...')));
            },
          ),
        ),
      ],
    );
  }
}
