import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tour_vn/features/trip/domain/entities/schedule_validation_result.dart';

/// Action buttons for the DayPickerBottomSheet.
///
/// Shows different button configurations based on validation result:
/// - No warning: Single confirm button
/// - With suggestion: Primary "Accept Suggestion" + Secondary "Keep Original"
/// - Warning but no suggestion: Single confirm button with warning indicator
class DayPickerActionButtons extends StatelessWidget {
  /// Whether the confirm button is enabled.
  final bool canConfirm;

  /// Current selected day index (0-indexed).
  final int selectedDayIndex;

  /// The validation result, if any.
  final ScheduleValidationResult? validationResult;

  /// Callback when user confirms with the selected day.
  final VoidCallback? onConfirm;

  /// Callback when user accepts the suggested day.
  final VoidCallback? onAcceptSuggestion;

  const DayPickerActionButtons({
    super.key,
    required this.canConfirm,
    required this.selectedDayIndex,
    this.validationResult,
    this.onConfirm,
    this.onAcceptSuggestion,
  });

  bool get _hasSuggestion =>
      validationResult?.hasWarning == true &&
      validationResult?.suggestedDayIndex != null;

  bool get _hasWarning => validationResult?.hasWarning == true;

  @override
  Widget build(BuildContext context) {
    if (_hasSuggestion) {
      return _buildDualButtons();
    }
    return _buildSingleButton();
  }

  Widget _buildDualButtons() {
    final suggestedDay = validationResult!.suggestedDayIndex! + 1;
    final selectedDay = selectedDayIndex + 1;

    return Column(
      children: [
        // Primary: Accept suggestion
        _ActionButton(
          label: '✓ Thêm vào Ngày $suggestedDay (gợi ý)',
          enabled: canConfirm,
          isPrimary: true,
          onTap: () {
            HapticFeedback.lightImpact();
            onAcceptSuggestion?.call();
          },
        ),
        const SizedBox(height: 8),
        // Secondary: Keep original selection
        _ActionButton(
          label: 'Giữ nguyên Ngày $selectedDay ⚠️',
          enabled: canConfirm,
          isPrimary: false,
          onTap: () {
            HapticFeedback.lightImpact();
            onConfirm?.call();
          },
        ),
      ],
    );
  }

  Widget _buildSingleButton() {
    final selectedDay = selectedDayIndex + 1;
    final label = _hasWarning
        ? 'Thêm vào Ngày $selectedDay ⚠️'
        : 'Thêm vào lịch trình';

    return _ActionButton(
      label: label,
      enabled: canConfirm,
      isPrimary: true,
      onTap: () {
        HapticFeedback.lightImpact();
        onConfirm?.call();
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.enabled,
    required this.isPrimary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: _gradient,
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: _border,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
      ),
    );
  }

  LinearGradient? get _gradient {
    if (!enabled) return null;
    if (!isPrimary) return null;
    return const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)]);
  }

  Color? get _backgroundColor {
    if (!enabled) return const Color(0xFFE2E8F0);
    if (isPrimary) return null; // Use gradient
    return Colors.white;
  }

  Border? get _border {
    if (isPrimary) return null;
    return Border.all(
      color: enabled ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0),
      width: 1.5,
    );
  }

  Color get _textColor {
    if (!enabled) return const Color(0xFF94A3B8);
    if (isPrimary) return Colors.white;
    return const Color(0xFF8B5CF6);
  }
}
