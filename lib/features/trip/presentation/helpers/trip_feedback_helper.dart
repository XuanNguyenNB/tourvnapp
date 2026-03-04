import 'package:flutter/material.dart';

/// Helper functions for showing snackbar feedback in trip operations.
///
/// Extracted from DayPickerBottomSheet to keep file under 300 lines.
class TripFeedbackHelper {
  /// Show success feedback after trip save.
  static void showSuccess(
    BuildContext context, {
    required String itemName,
    required bool isNewTrip,
  }) {
    final message = isNewTrip
        ? '✓ Đã tạo chuyến đi và thêm $itemName'
        : '✓ Đã thêm $itemName vào chuyến đi';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF10B981), // Green success
      ),
    );
  }

  /// Show pending feedback when user dismisses sign-in.
  static void showPending(
    BuildContext context, {
    required String itemName,
    required int dayNumber,
    VoidCallback? onSignInPressed,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm $itemName vào Ngày $dayNumber'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: onSignInPressed != null
            ? SnackBarAction(label: 'Đăng nhập', onPressed: onSignInPressed)
            : null,
      ),
    );
  }

  /// Show error feedback when trip save fails.
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFFEF4444), // Red error
      ),
    );
  }

  /// Show duplicate warning when location already exists in trip.
  static void showDuplicate(
    BuildContext context, {
    required String locationName,
    required int dayNumber,
    required String timeSlotLabel,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '⚠️ $locationName đã có trong Ngày $dayNumber - $timeSlotLabel',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFFF59E0B), // Amber warning
      ),
    );
  }
}
