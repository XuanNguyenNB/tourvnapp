import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_radius.dart';

/// A shimmer loading placeholder with smooth animation.
///
/// Creates a skeleton loader with shimmer effect for loading states.
/// Uses optimized shimmer package from pub.dev.
///
/// **Animation:** 1000ms cycle, left-to-right direction
///
/// Example:
/// ```dart
/// // Loading destination cards
/// ListView.builder(
///   itemCount: 5,
///   itemBuilder: (context, index) => Padding(
///     padding: EdgeInsets.all(AppSpacing.md),
///     child: ShimmerPlaceholder(
///       width: double.infinity,
///       height: 200,
///       borderRadius: AppRadius.md,
///     ),
///   ),
/// )
/// ```
class ShimmerPlaceholder extends StatelessWidget {
  /// Creates a shimmer placeholder.
  ///
  /// The [width] and [height] parameters are required.
  /// The [borderRadius] defaults to [AppRadius.sm].
  /// The [baseColor] defaults to [AppColors.border].
  /// The [highlightColor] defaults to [AppColors.surface].
  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  /// The width of the placeholder.
  final double width;

  /// The height of the placeholder.
  final double height;

  /// The border radius. Defaults to [AppRadius.sm].
  final double? borderRadius;

  /// The base color. Defaults to [AppColors.border].
  final Color? baseColor;

  /// The highlight color. Defaults to [AppColors.surface].
  final Color? highlightColor;

  /// Creates a card-shaped shimmer placeholder.
  ///
  /// Convenient factory for loading card content.
  const ShimmerPlaceholder.card({
    super.key,
    this.width = double.infinity,
    this.height = 200,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  /// Creates a circle shimmer placeholder for avatars.
  ///
  /// The [diameter] parameter is required.
  const ShimmerPlaceholder.circle({
    super.key,
    required double diameter,
    this.baseColor,
    this.highlightColor,
  }) : width = diameter,
       height = diameter,
       borderRadius = 9999.0; // Full circle

  /// Creates a line shimmer placeholder for text.
  ///
  /// Convenient factory for loading text lines.
  const ShimmerPlaceholder.line({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? AppRadius.sm;
    final effectiveBaseColor = baseColor ?? AppColors.border;
    final effectiveHighlightColor = highlightColor ?? AppColors.surface;

    return Shimmer.fromColors(
      baseColor: effectiveBaseColor,
      highlightColor: effectiveHighlightColor,
      period: const Duration(milliseconds: 1000),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: effectiveBaseColor,
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
        ),
      ),
    );
  }
}
