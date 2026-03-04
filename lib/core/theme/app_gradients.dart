import 'package:flutter/material.dart';

/// AppGradients - Gradient definitions for TourVN
///
/// This class defines gradient tokens for modern, vibrant UI elements.
/// Gradients are key to Gen Z aesthetic and should be used for:
/// - Primary CTAs (buttons, FABs)
/// - Hero sections
/// - AI feature highlights
/// - Dark mode backgrounds
///
/// All gradients use topLeft to bottomRight direction for consistency.
class AppGradients {
  // Prevent instantiation
  AppGradients._();

  /// Primary gradient: Electric Purple → Hot Pink
  /// Usage: Primary CTAs, featured content
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFF6339A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Secondary gradient: Cyan → Purple
  /// Usage: AI features, secondary actions
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF00B8DB), Color(0xFFAD46FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dark gradient: Navy → Slate
  /// Usage: Dark backgrounds, AI assistant screen
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Login screen background gradient
  /// Dark to purple gradient for premium feel
  /// Usage: Login screen, onboarding screens
  static const LinearGradient loginBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F172A), // Dark navy
      Color(0xFF1E1B4B), // Dark purple
      Color(0xFF312E81), // Indigo
    ],
    stops: [0.0, 0.5, 1.0],
  );
}
