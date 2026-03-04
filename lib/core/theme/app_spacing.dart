/// AppSpacing - Spacing tokens for TourVN
///
/// This class defines consistent spacing values used throughout the app.
/// Using a spacing scale ensures visual rhythm and consistency.
///
/// Usage Guidelines:
/// - `xs` (4px): Icon-text spacing, tiny gaps
/// - `sm` (8px): List item padding, compact spacing
/// - `md` (16px): Card padding, standard gaps (DEFAULT)
/// - `lg` (24px): Screen padding, section spacing
/// - `xl` (32px): Large section gaps, hero spacing
///
/// Example:
/// ```dart
/// Padding(
///   padding: EdgeInsets.all(AppSpacing.md),
///   child: Column(
///     spacing: AppSpacing.lg,
///     children: [...]
///   ),
/// )
/// ```
class AppSpacing {
  // Prevent instantiation
  AppSpacing._();

  /// Extra Small spacing (4px)
  /// Use for: Icon-text gaps, minimal spacing
  static const double xs = 4.0;

  /// Small spacing (8px)
  /// Use for: List item padding, compact layouts
  static const double sm = 8.0;

  /// Medium spacing (16px) - RECOMMENDED DEFAULT
  /// Use for: Card padding, standard gaps between elements
  static const double md = 16.0;

  /// Large spacing (24px)
  /// Use for: Screen edge padding, section headers
  static const double lg = 24.0;

  /// Extra Large spacing (32px)
  /// Use for: Major section spacing, hero content
  static const double xl = 32.0;
}
