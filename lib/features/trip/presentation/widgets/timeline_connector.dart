import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Timeline connector with emoji marker and dotted lines.
///
/// Displays:
/// - Dotted line above (unless first item)
/// - Emoji circle in the center
/// - Dotted line below (unless last item)
class TimelineConnector extends StatelessWidget {
  /// Creates a timeline connector.
  const TimelineConnector({
    super.key,
    required this.emoji,
    this.isFirst = false,
    this.isLast = false,
    this.lineColor,
    this.circleSize = 36,
  });

  /// Emoji to display in the circle.
  final String emoji;

  /// Whether this is the first item (no top line).
  final bool isFirst;

  /// Whether this is the last item (no bottom line).
  final bool isLast;

  /// Color of the connecting lines.
  final Color? lineColor;

  /// Size of the emoji circle.
  final double circleSize;

  @override
  Widget build(BuildContext context) {
    final effectiveLineColor = lineColor ?? AppColors.border;

    return SizedBox(
      width: circleSize + 12, // Circle + padding
      child: Column(
        children: [
          // Top connector line
          if (!isFirst) Expanded(child: _DottedLine(color: effectiveLineColor)),
          // Emoji circle
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          // Bottom connector line
          if (!isLast) Expanded(child: _DottedLine(color: effectiveLineColor)),
        ],
      ),
    );
  }
}

/// Dotted vertical line widget.
class _DottedLine extends StatelessWidget {
  const _DottedLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(2, double.infinity),
      painter: _DottedLinePainter(color: color),
    );
  }
}

/// Custom painter for dotted line.
class _DottedLinePainter extends CustomPainter {
  _DottedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}
