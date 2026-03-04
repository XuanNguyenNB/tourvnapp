import 'package:flutter/material.dart';

/// AppShadows - Shadow tokens for TourVN
///
/// This class defines elevation shadow styles for depth and hierarchy.
/// Shadows add subtle depth without heavy Material elevation.
///
/// Usage Guidelines:
/// - `shadowSm`: Subtle hover states, small cards
/// - `shadowMd`: Standard cards, dropdowns (MOST COMMON)
/// - `shadowLg`: Modals, important CTAs
/// - `shadowXl`: Hero sections, floating panels
///
/// Example:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     color: Colors.white,
///     boxShadow: [AppShadows.shadowMd],
///     borderRadius: BorderRadius.circular(AppRadius.md),
///   ),
/// )
/// ```
class AppShadows {
  // Prevent instantiation
  AppShadows._();

  /// Small shadow (subtle)
  /// Offset: (0, 1px), Blur: 2px, Opacity: 5%
  /// Use for: Hover states, small cards
  static const BoxShadow shadowSm = BoxShadow(
    color: Color(0x0D000000), // rgba(0,0,0,0.05)
    offset: Offset(0, 1),
    blurRadius: 2,
    spreadRadius: 0,
  );

  /// Medium shadow (standard)
  /// Offset: (0, 4px), Blur: 6px, Opacity: 10%
  /// Use for: Cards, dropdowns, standard elevation
  static const BoxShadow shadowMd = BoxShadow(
    color: Color(0x1A000000), // rgba(0,0,0,0.1)
    offset: Offset(0, 4),
    blurRadius: 6,
    spreadRadius: 0,
  );

  /// Large shadow (prominent)
  /// Offset: (0, 10px), Blur: 15px, Opacity: 10%
  /// Use for: Modals, important CTAs
  static const BoxShadow shadowLg = BoxShadow(
    color: Color(0x1A000000), // rgba(0,0,0,0.1)
    offset: Offset(0, 10),
    blurRadius: 15,
    spreadRadius: 0,
  );

  /// Extra Large shadow (dramatic)
  /// Offset: (0, 20px), Blur: 25px, Opacity: 10%
  /// Use for: Hero sections, floating panels
  static const BoxShadow shadowXl = BoxShadow(
    color: Color(0x1A000000), // rgba(0,0,0,0.1)
    offset: Offset(0, 20),
    blurRadius: 25,
    spreadRadius: 0,
  );
}
