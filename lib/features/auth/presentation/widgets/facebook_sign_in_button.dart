import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tour_vn/core/theme/app_typography.dart';

/// Facebook Sign-In button matching UX spec
/// Facebook blue #1877F2, 48px height, 24px radius
///
/// Usage:
/// ```dart
/// FacebookSignInButton(
///   onPressed: () => ref.read(authNotifierProvider.notifier).signInWithFacebook(),
///   isLoading: authState.isLoading,
/// )
/// ```
class FacebookSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const FacebookSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  // Official Facebook brand color
  static const Color facebookBlue = Color(0xFF1877F2);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed?.call();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: facebookBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: facebookBlue.withValues(alpha: 0.6),
          elevation: 2,
          shadowColor: facebookBlue.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Facebook "f" logo
                  const _FacebookLogo(size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Đăng nhập với Facebook',
                    style: AppTypography.labelMD.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Custom Facebook "f" logo widget
/// White circle with Facebook "f" character
class _FacebookLogo extends StatelessWidget {
  final double size;

  const _FacebookLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'f',
          style: TextStyle(
            color: FacebookSignInButton.facebookBlue,
            fontSize: size * 0.7,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
