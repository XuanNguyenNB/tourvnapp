import 'package:flutter/material.dart';
import 'package:tour_vn/core/theme/app_gradients.dart';
import 'package:tour_vn/core/theme/app_radius.dart';
import 'package:tour_vn/core/theme/app_typography.dart';

/// A gradient button widget for primary CTAs.
///
/// Features vibrant gradient background, rounded corners, and supports
/// disabled and loading states with proper accessibility.
///
/// **States:**
/// - Normal: Full gradient, white text
/// - Disabled (onPressed = null): 50% opacity, no tap
/// - Loading (isLoading = true): Show CircularProgress Indicator, disable tap
/// - Pressed: Subtle white overlay (InkWell ripple)
///
/// **Touch Target:** Min height 48px (WCAG compliance)
///
/// Example:
/// ```dart
/// GradientButton(
///   text: 'Lấy gợi ý cho bạn',
///   onPressed: () => context.push('/mood-selection'),
///   icon: Icon(Icons.explore, color: Colors.white),
/// )
/// ```
class GradientButton extends StatelessWidget {
  /// Creates a gradient button.
  ///
  /// The [text] parameter is required and represents the button label.
  /// The [onPressed] parameter is required. When null, button is disabled.
  /// The [icon] parameter is optional and adds a leading icon.
  /// The [isLoading] parameter shows a loading spinner when true.
  /// The [gradient] defaults to [AppGradients.primaryGradient].
  /// The [height] defaults to 48.0 (WCAG touch target).
  /// The [width] defaults to double.infinity (full width).
  /// The [borderRadius] defaults to [AppRadius.lg].
  /// The [textStyle] defaults to [AppTypography.labelMD] in white.
  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.gradient,
    this.height,
    this.width,
    this.borderRadius,
    this.textStyle,
  });

  /// The button label text.
  final String text;

  /// The callback when button is pressed. Null = disabled state.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final Widget? icon;

  /// Shows loading spinner when true. Defaults to false.
  final bool isLoading;

  /// The gradient background. Defaults to [AppGradients.primaryGradient].
  final Gradient? gradient;

  /// The button height. Defaults to 48.0.
  final double? height;

  /// The button width. Defaults to double.infinity (full width).
  final double? width;

  /// The border radius. Defaults to [AppRadius.lg].
  final double? borderRadius;

  /// The text style. Defaults to [AppTypography.labelMD] in white.
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? AppGradients.primaryGradient;
    final effectiveHeight = height ?? 48.0;
    final effectiveWidth = width ?? double.infinity;
    final effectiveBorderRadius = borderRadius ?? AppRadius.lg;
    final effectiveTextStyle =
        textStyle ?? AppTypography.labelMD.copyWith(color: Colors.white);

    final isDisabled = onPressed == null || isLoading;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        height: effectiveHeight,
        width: effectiveWidth,
        decoration: BoxDecoration(
          gradient: effectiveGradient,
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            splashColor: Colors.white.withValues(alpha: 0.1),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[icon!, const SizedBox(width: 8)],
                        Text(text, style: effectiveTextStyle),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
