import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_radius.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';

/// A glassmorphism card widget with blur effect.
///
/// Creates a glass-like container with backdrop blur effect,
/// semi-transparent white overlay, and subtle border.
///
/// **Performance Warning:** BackdropFilter is expensive!
/// Use sparingly for modals, overlays, special cards only.
/// NOT for list items (performance killer on scroll).
///
/// Example:
/// ```dart
/// GlassCard(
///   padding: EdgeInsets.all(AppSpacing.lg),
///   borderRadius: AppRadius.lg,
///   child: Column(
///     children: [
///       Text('Đà Lạt', style: AppTypography.headingLG),
///       Text('Thành phố ngàn hoa', style: AppTypography.bodySM),
///     ],
///   ),
/// )
/// ```
class GlassCard extends StatelessWidget {
  /// Creates a glassmorphism card.
  ///
  /// The [child] parameter is required and represents the content inside the card.
  /// The [padding] defaults to [AppSpacing.md] on all sides.
  /// The [borderRadius] defaults to [AppRadius.md].
  /// The [glassColor] defaults to [AppColors.glass].
  /// The [blurStrength] defaults to 10.0 (sigma for blur).
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.glassColor,
    this.blurStrength,
  });

  /// The widget to display inside the glass card.
  final Widget child;

  /// The internal padding of the card. Defaults to [AppSpacing.md] all sides.
  final EdgeInsetsGeometry? padding;

  /// The external margin of the card. Optional.
  final EdgeInsetsGeometry? margin;

  /// The border radius of the card. Defaults to [AppRadius.md].
  final double? borderRadius;

  /// The glass overlay color. Defaults to [AppColors.glass].
  final Color? glassColor;

  /// The blur strength (sigma value). Defaults to 10.0.
  final double? blurStrength;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? AppRadius.md;
    final effectivePadding = padding ?? EdgeInsets.all(AppSpacing.md);
    final effectiveGlassColor = glassColor ?? AppColors.glass;
    final effectiveBlurStrength = blurStrength ?? 10.0;

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: effectiveBlurStrength,
            sigmaY: effectiveBlurStrength,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: effectiveGlassColor,
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            padding: effectivePadding,
            child: child,
          ),
        ),
      ),
    );
  }
}
