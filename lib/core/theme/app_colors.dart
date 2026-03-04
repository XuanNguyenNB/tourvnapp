import 'package:flutter/material.dart';

/// AppColors - Centralized color tokens for TourVN
///
/// This class defines all color tokens used throughout the application.
/// DO NOT hardcode colors in widgets - always reference these tokens.
///
/// Color Philosophy (from UX Design Spec):
/// - Gen Z aesthetic with vibrant, modern colors
/// - Electric Purple (#8B5CF6) as primary brand color
/// - Clean, minimal backgrounds for content focus
/// - High contrast for accessibility
class AppColors {
  // Prevent instantiation
  AppColors._();

  // Primary Brand Colors
  /// Electric Purple - Primary brand color for CTAs, links, accents
  static const Color primary = Color(0xFF8B5CF6);

  /// Cyan Blue - Secondary accents
  static const Color secondary = Color(0xFF00B8DB);

  // Background Colors
  /// Light gray background for screens
  static const Color background = Color(0xFFFAFBFC);

  // Surface Colors
  /// White surface for cards and elevated elements
  static const Color surface = Color(0xFFFFFFFF);

  /// Dark surface for AI screen and dark mode elements
  static const Color surfaceDark = Color(0xFF0F172A);

  // Text Colors
  /// Primary text color - dark slate
  static const Color textPrimary = Color(0xFF1E293B);

  /// Secondary text color - medium slate
  static const Color textSecondary = Color(0xFF64748B);

  // Border & Dividers
  /// Subtle border color for dividers and outlines
  static const Color border = Color(0xFFE2E8F0);

  // Status Colors
  /// Error/destructive actions
  static const Color error = Color(0xFFEF4444);

  /// Success/confirmation states
  static const Color success = Color(0xFF10B981);

  // Special Effects
  /// Glass overlay for glassmorphism effects (~10% white opacity)
  /// Usage: Container(color: AppColors.glass) with backdrop filter
  static const Color glass = Color(0x1AFFFFFF);

  // Navigation Bar Colors (Gen Z Floating Nav)
  /// Accent pink for gradient active indicator
  static const Color accentPink = Color(0xFFF6339A);

  /// Nav bar glass background (85% white)
  static const Color navGlass = Color(0xD9FFFFFF);

  /// Nav bar shadow (10% purple)
  static const Color navShadow = Color(0x1A8B5CF6);
}
