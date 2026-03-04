import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/utils/destination_emoji_helper.dart';

/// A pill-shaped widget representing a destination filter option.
///
/// Story 8-7: Individual pill for destination filtering on Home Screen.
/// Shows emoji + destination name, with visual states for selection.
class DestinationPill extends StatelessWidget {
  /// The unique destination ID used for emoji lookup.
  final String destinationId;

  /// The display name of the destination (e.g., "Đà Nẵng").
  final String destinationName;

  /// Whether this pill is currently selected.
  final bool isSelected;

  /// Callback fired when the pill is tapped.
  final VoidCallback? onTap;

  /// Creates a DestinationPill widget.
  const DestinationPill({
    super.key,
    required this.destinationId,
    required this.destinationName,
    this.isSelected = false,
    this.onTap,
  });

  /// Color constants matching Figma design specs.
  static const _selectedBackground = Color(0xFF8B5CF6);
  static const _unselectedBackground = Colors.white;
  static const _unselectedBorderColor = Color(0xFFE2E8F0);
  static const _selectedTextColor = Colors.white;
  static const _unselectedTextColor = Color(0xFF64748B);

  /// Get the emoji for this destination.
  String get _displayText =>
      DestinationEmojiHelper.formatPillText(destinationId, destinationName);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _selectedBackground : _unselectedBackground,
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? null
              : Border.all(color: _unselectedBorderColor, width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _selectedBackground.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          _displayText,
          style: TextStyle(
            color: isSelected ? _selectedTextColor : _unselectedTextColor,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    onTap?.call();
  }
}
