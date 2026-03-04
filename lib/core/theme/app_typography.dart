import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTypography - Typography system for TourVN
///
/// This class defines all text styles using Be Vietnam Pro font family.
/// Be Vietnam Pro is specifically designed for Vietnamese text with
/// optimized diacritics positioning and modern, premium aesthetics.
///
/// Usage Example:
/// ```dart
/// Text('Đà Lạt', style: AppTypography.headingXL)
/// ```
///
/// Font Weights:
/// - 400: Regular (body text)
/// - 500: Medium (labels)
/// - 600: SemiBold (headings)
/// - 700: Bold (emphasis)
class AppTypography {
  // Prevent instantiation
  AppTypography._();

  // Heading Styles

  /// Extra Large Heading (24px, Bold)
  /// Usage: Page titles, hero sections
  static final TextStyle headingXL = GoogleFonts.beVietnamPro(
    fontSize: 24,
    fontWeight: FontWeight.w700, // Bold
    height: 32 / 24, // Line height 32px
    letterSpacing: -0.5,
  );

  /// Large Heading (20px, SemiBold)
  /// Usage: Section headers, card titles
  static final TextStyle headingLG = GoogleFonts.beVietnamPro(
    fontSize: 20,
    fontWeight: FontWeight.w600, // SemiBold
    height: 28 / 20, // Line height 28px
    letterSpacing: -0.3,
  );

  /// Medium Heading (18px, SemiBold)
  /// Usage: Card titles, subsection headers
  static final TextStyle headingMD = GoogleFonts.beVietnamPro(
    fontSize: 18,
    fontWeight: FontWeight.w600, // SemiBold
    height: 24 / 18, // Line height 24px
    letterSpacing: -0.2,
  );

  // Body Styles

  /// Medium Body Text (16px, Regular)
  /// Usage: Primary body text, descriptions
  static final TextStyle bodyMD = GoogleFonts.beVietnamPro(
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    height: 24 / 16, // Line height 24px
    letterSpacing: 0,
  );

  /// Small Body Text (14px, Regular)
  /// Usage: Secondary text, metadata
  static final TextStyle bodySM = GoogleFonts.beVietnamPro(
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    height: 20 / 14, // Line height 20px
    letterSpacing: 0,
  );

  // Label & UI Text

  /// Medium Label (14px, Medium)
  /// Usage: Buttons, form labels, tabs
  static final TextStyle labelMD = GoogleFonts.beVietnamPro(
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    height: 20 / 14, // Line height 20px
    letterSpacing: 0.1,
  );

  /// Caption Text (12px, Regular)
  /// Usage: Captions, timestamps, helper text
  static final TextStyle caption = GoogleFonts.beVietnamPro(
    fontSize: 12,
    fontWeight: FontWeight.w400, // Regular
    height: 16 / 12, // Line height 16px
    letterSpacing: 0,
  );

  // Vietnamese Text Test Sample
  /// Test string for Vietnamese diacritics validation
  /// Use this to verify proper rendering of Vietnamese characters
  static const String vietnameseTestText =
      'Đi du lịch Đà Lạt - Trải nghiệm tuyệt vời';
}
