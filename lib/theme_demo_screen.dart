import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_gradients.dart';
import 'core/theme/app_typography.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_radius.dart';
import 'core/theme/app_shadows.dart';

/// ThemeDemoScreen - Visual showcase of all design tokens
///
/// This screen demonstrates every token in the design system:
/// - Colors (solid + gradients)
/// - Typography styles
/// - Spacing scale
/// - Border radius scale
/// - Shadow levels
/// - Vietnamese text rendering
///
/// Use this screen to verify theme implementation before proceeding.
class ThemeDemoScreen extends StatelessWidget {
  const ThemeDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TourVN Theme System', style: AppTypography.headingLG),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colors Section
            _buildSectionHeader('Colors'),
            SizedBox(height: AppSpacing.md),
            _buildColorGrid(),
            SizedBox(height: AppSpacing.xl),

            // Gradients Section
            _buildSectionHeader('Gradients'),
            SizedBox(height: AppSpacing.md),
            _buildGradientsGrid(),
            SizedBox(height: AppSpacing.xl),

            // Typography Section
            _buildSectionHeader('Typography'),
            SizedBox(height: AppSpacing.md),
            _buildTypographyExamples(),
            SizedBox(height: AppSpacing.xl),

            // Spacing Section
            _buildSectionHeader('Spacing'),
            SizedBox(height: AppSpacing.md),
            _buildSpacingExamples(),
            SizedBox(height: AppSpacing.xl),

            // Radius Section
            _buildSectionHeader('Border Radius'),
            SizedBox(height: AppSpacing.md),
            _buildRadiusExamples(),
            SizedBox(height: AppSpacing.xl),

            // Shadows Section
            _buildSectionHeader('Shadows'),
            SizedBox(height: AppSpacing.md),
            _buildShadowExamples(),
            SizedBox(height: AppSpacing.xl),

            // Buttons Section
            _buildSectionHeader('Buttons'),
            SizedBox(height: AppSpacing.md),
            _buildButtonExamples(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AppTypography.headingXL);
  }

  Widget _buildColorGrid() {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _buildColorSwatch('Primary', AppColors.primary),
        _buildColorSwatch('Secondary', AppColors.secondary),
        _buildColorSwatch('Background', AppColors.background),
        _buildColorSwatch('Surface', AppColors.surface),
        _buildColorSwatch('Surface Dark', AppColors.surfaceDark),
        _buildColorSwatch('Text Primary', AppColors.textPrimary),
        _buildColorSwatch('Text Secondary', AppColors.textSecondary),
        _buildColorSwatch('Border', AppColors.border),
        _buildColorSwatch('Error', AppColors.error),
        _buildColorSwatch('Success', AppColors.success),
      ],
    );
  }

  Widget _buildColorSwatch(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  Widget _buildGradientsGrid() {
    return Column(
      children: [
        _buildGradientSwatch('Primary Gradient', AppGradients.primaryGradient),
        SizedBox(height: AppSpacing.md),
        _buildGradientSwatch(
          'Secondary Gradient',
          AppGradients.secondaryGradient,
        ),
        SizedBox(height: AppSpacing.md),
        _buildGradientSwatch('Dark Gradient', AppGradients.darkGradient),
      ],
    );
  }

  Widget _buildGradientSwatch(String label, LinearGradient gradient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySM),
        SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ],
    );
  }

  Widget _buildTypographyExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Heading XL - 24px Bold', style: AppTypography.headingXL),
        SizedBox(height: AppSpacing.sm),
        Text('Heading LG - 20px SemiBold', style: AppTypography.headingLG),
        SizedBox(height: AppSpacing.sm),
        Text('Heading MD - 18px SemiBold', style: AppTypography.headingMD),
        SizedBox(height: AppSpacing.sm),
        Text('Body MD - 16px Regular', style: AppTypography.bodyMD),
        SizedBox(height: AppSpacing.sm),
        Text('Body SM - 14px Regular', style: AppTypography.bodySM),
        SizedBox(height: AppSpacing.sm),
        Text('Label MD - 14px Medium', style: AppTypography.labelMD),
        SizedBox(height: AppSpacing.sm),
        Text('Caption - 12px Regular', style: AppTypography.caption),
        SizedBox(height: AppSpacing.md),
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vietnamese Text Test:', style: AppTypography.labelMD),
              SizedBox(height: AppSpacing.xs),
              Text(
                AppTypography.vietnameseTestText,
                style: AppTypography.bodyMD,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpacingExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSpacingBar('XS - 4px', AppSpacing.xs),
        _buildSpacingBar('SM - 8px', AppSpacing.sm),
        _buildSpacingBar('MD - 16px', AppSpacing.md),
        _buildSpacingBar('LG - 24px', AppSpacing.lg),
        _buildSpacingBar('XL - 32px', AppSpacing.xl),
      ],
    );
  }

  Widget _buildSpacingBar(String label, double spacing) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: AppTypography.bodySM)),
          Container(
            width: spacing,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusExamples() {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _buildRadiusBox('SM - 8px', AppRadius.sm),
        _buildRadiusBox('MD - 12px', AppRadius.md),
        _buildRadiusBox('LG - 24px', AppRadius.lg),
        _buildRadiusBox('Full - Pill', AppRadius.full),
      ],
    );
  }

  Widget _buildRadiusBox(String label, double radius) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  Widget _buildShadowExamples() {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _buildShadowBox('SM', [AppShadows.shadowSm]),
        _buildShadowBox('MD', [AppShadows.shadowMd]),
        _buildShadowBox('LG', [AppShadows.shadowLg]),
        _buildShadowBox('XL', [AppShadows.shadowXl]),
      ],
    );
  }

  Widget _buildShadowBox(String label, List<BoxShadow> shadows) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: shadows,
          ),
          child: Center(child: Text(label, style: AppTypography.labelMD)),
        ),
        SizedBox(height: AppSpacing.xs),
        Text('Shadow $label', style: AppTypography.caption),
      ],
    );
  }

  Widget _buildButtonExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(onPressed: () {}, child: const Text('Elevated Button')),
        SizedBox(height: AppSpacing.sm),
        OutlinedButton(onPressed: () {}, child: const Text('Outlined Button')),
        SizedBox(height: AppSpacing.sm),
        TextButton(onPressed: () {}, child: const Text('Text Button')),
      ],
    );
  }
}
