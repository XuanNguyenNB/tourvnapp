import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tour_vn/core/theme/app_typography.dart';

/// Google Sign-In button matching UX spec
/// White background, 48px height, 24px radius
///
/// Usage:
/// ```dart
/// GoogleSignInButton(
///   onPressed: () => ref.read(authNotifierProvider.notifier).signInWithGoogle(),
///   isLoading: authState.isLoading,
/// )
/// ```
class GoogleSignInButton extends StatelessWidget {
  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Whether to show loading indicator
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed?.call();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          disabledBackgroundColor: Colors.grey[100],
          disabledForegroundColor: Colors.grey[400],
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.black12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" logo - using custom paint for consistency
                  const _GoogleLogo(size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Đăng nhập với Google',
                    style: AppTypography.labelMD.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Custom Google logo widget using official Google brand colors
/// Uses CustomPainter for crisp rendering at any size
class _GoogleLogo extends StatelessWidget {
  final double size;

  const _GoogleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

/// CustomPainter for Google "G" logo with official brand colors
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double center = s / 2;
    final double radius = s * 0.42;

    // Google brand colors
    const Color blue = Color(0xFF4285F4);
    const Color red = Color(0xFFEA4335);
    const Color yellow = Color(0xFFFBBC05);
    const Color green = Color(0xFF34A853);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.18
      ..strokeCap = StrokeCap.butt;

    // Draw arcs for each color segment
    final Rect rect = Rect.fromCircle(
      center: Offset(center, center),
      radius: radius,
    );

    // Blue (right side, from -45 to 45 degrees)
    paint.color = blue;
    canvas.drawArc(rect, -0.785, 1.57, false, paint);

    // Green (bottom right, from 45 to 135 degrees)
    paint.color = green;
    canvas.drawArc(rect, 0.785, 1.57, false, paint);

    // Yellow (bottom left, from 135 to 180 degrees)
    paint.color = yellow;
    canvas.drawArc(rect, 2.356, 0.785, false, paint);

    // Red (top, from 180 to 315 degrees)
    paint.color = red;
    canvas.drawArc(rect, 3.14159, 2.356, false, paint);

    // Draw the horizontal bar of the G
    final Paint barPaint = Paint()
      ..color = blue
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(center, center - s * 0.06, s * 0.35, s * 0.12),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
