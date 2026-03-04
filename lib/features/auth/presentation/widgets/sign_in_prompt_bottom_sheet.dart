import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/core/exceptions/app_exception.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_gradients.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';
import 'package:tour_vn/features/auth/presentation/providers/auth_provider.dart';
import 'package:tour_vn/features/auth/presentation/widgets/google_sign_in_button.dart';

/// Bottom sheet that prompts anonymous users to sign in when saving a trip
///
/// Implements FR29: Sign-in prompt for trip save
///
/// Features:
/// - Gradient header with bookmark icon
/// - Value proposition text in Vietnamese
/// - Google sign-in button (reused from Story 2.2)
/// - "Để sau" dismiss option
/// - Loading states during sign-in
/// - Error handling with Vietnamese messages
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (context) => SignInPromptBottomSheet(
///     onSignInSuccess: () => savePendingTrip(),
///     onDismiss: () => showNotSavedMessage(),
///   ),
/// );
/// ```
class SignInPromptBottomSheet extends ConsumerStatefulWidget {
  const SignInPromptBottomSheet({
    super.key,
    required this.onSignInSuccess,
    required this.onDismiss,
  });

  /// Called after successful sign-in (Google)
  /// Account linking from anonymous is handled automatically by AuthRepository
  final VoidCallback onSignInSuccess;

  /// Called when user dismisses without signing in
  final VoidCallback onDismiss;

  @override
  ConsumerState<SignInPromptBottomSheet> createState() =>
      _SignInPromptBottomSheetState();
}

class _SignInPromptBottomSheetState
    extends ConsumerState<SignInPromptBottomSheet> {
  bool _isLoading = false;

  /// Handle Google sign-in with loading state and error handling
  Future<void> _handleGoogleSignIn() async {
    debugPrint('🔵 [SignInPrompt] Starting Google sign-in');
    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      debugPrint(
        '🔵 [SignInPrompt] Google sign-in completed, mounted: $mounted',
      );

      if (mounted) {
        // Haptic feedback on success
        HapticFeedback.mediumImpact();
        debugPrint('🔵 [SignInPrompt] Calling onSignInSuccess callback');
        Navigator.of(context).pop();
        widget.onSignInSuccess();
        debugPrint('🔵 [SignInPrompt] onSignInSuccess callback executed');
      }
    } catch (e) {
      debugPrint('🔴 [SignInPrompt] Google sign-in error: $e');
      if (mounted) {
        _showErrorSnackBar(e);
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handle dismiss - close sheet and call onDismiss callback
  void _handleDismiss() {
    Navigator.of(context).pop();
    widget.onDismiss();
  }

  /// Show error SnackBar with Vietnamese message
  void _showErrorSnackBar(Object error) {
    String message = 'Đăng nhập thất bại. Vui lòng thử lại.';
    if (error is AppException) {
      message = error.message;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              _buildDragHandle(),
              const SizedBox(height: AppSpacing.lg),

              // Icon with gradient background
              _buildIcon(),
              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                'Đăng nhập để lưu chuyến đi',
                style: AppTypography.headingLG,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Subtitle - value proposition
              Text(
                'Chuyến đi sẽ được đồng bộ trên mọi thiết bị của bạn',
                style: AppTypography.bodyMD.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Sign-in buttons
              GoogleSignInButton(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                isLoading: _isLoading,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Dismiss option
              TextButton(
                onPressed: _isLoading ? null : _handleDismiss,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                child: Text(
                  'Để sau',
                  style: AppTypography.bodyMD.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Drag handle indicator for bottom sheet
  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Icon container with gradient background
  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: AppGradients.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.bookmark_add_rounded,
        color: Colors.white,
        size: 40,
      ),
    );
  }
}
