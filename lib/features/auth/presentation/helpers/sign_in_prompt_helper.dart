import 'package:flutter/material.dart';
import 'package:tour_vn/features/auth/presentation/widgets/sign_in_prompt_bottom_sheet.dart';

/// Shows the sign-in prompt bottom sheet for anonymous users
///
/// This helper function provides a convenient way to display the sign-in
/// prompt when users attempt to save trips while browsing anonymously.
///
/// Implements FR29: Sign-in prompt for trip save
///
/// Parameters:
/// - [context]: Build context for showing the bottom sheet
/// - [onSignInSuccess]: Called after successful sign-in (for saving the trip)
/// - [onDismiss]: Called when user dismisses without signing in
///
/// Returns a Future that completes when the bottom sheet is dismissed.
///
/// Usage:
/// ```dart
/// await showSignInPrompt(
///   context: context,
///   onSignInSuccess: () {
///     // Save the pending trip after successful sign-in
///     savePendingTrip();
///   },
///   onDismiss: () {
///     // Show "trip not saved" message
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text('Chuyến đi chưa được lưu')),
///     );
///   },
/// );
/// ```
Future<void> showSignInPrompt({
  required BuildContext context,
  required VoidCallback onSignInSuccess,
  required VoidCallback onDismiss,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SignInPromptBottomSheet(
      onSignInSuccess: onSignInSuccess,
      onDismiss: onDismiss,
    ),
  );
}
