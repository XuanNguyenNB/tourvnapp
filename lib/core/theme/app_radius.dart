/// AppRadius - Border radius tokens for TourVN
///
/// This class defines border radius values for soft, friendly UI elements.
/// Rounded corners are essential to Gen Z aesthetic - minimum 8px everywhere.
///
/// Usage Guidelines:
/// - `sm` (8px): Subtle rounding, small chips
/// - `md` (12px): Standard cards, images (MOST COMMON)
/// - `lg` (24px): Buttons, modals, bottom sheets
/// - `full` (9999px): Pill shapes, avatars, badges
///
/// Example:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     borderRadius: BorderRadius.circular(AppRadius.md),
///   ),
/// )
/// ```
///
/// Design Rules:
/// - All images: Use `md` (12px)
/// - All cards: Use `md` (12px)
/// - All buttons: Use `lg` (24px)
/// - Avatars/Pills: Use `full` (9999px)
class AppRadius {
  // Prevent instantiation
  AppRadius._();

  /// Small radius (8px)
  /// Use for: Subtle rounding, small chips, badges
  static const double sm = 8.0;

  /// Medium radius (12px) - RECOMMENDED DEFAULT
  /// Use for: Cards, images, containers
  static const double md = 12.0;

  /// Large radius (24px)
  /// Use for: Buttons, modals, bottom sheets
  static const double lg = 24.0;

  /// Full radius (9999px)
  /// Use for: Pill shapes, avatars, circular elements
  static const double full = 9999.0;
}
