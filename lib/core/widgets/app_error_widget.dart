import 'package:flutter/material.dart';
import 'package:tour_vn/core/exceptions/app_exception.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';
import 'package:tour_vn/core/widgets/gradient_button.dart';

/// A user-friendly error display widget.
///
/// Shows error icon, Vietnamese message from AppException, and optional retry button.
/// Designed to display errors in a non-technical, user-friendly way.
///
/// Example:
/// ```dart
/// AsyncValue<List<Trip>> tripsAsync = ref.watch(tripsProvider);
///
/// tripsAsync.when(
///   data: (trips) => TripList(trips: trips),
///   loading: () => ShimmerPlaceholder(...),
///   error: (error, stack) {
///     final appError = error as AppException;
///     return AppErrorWidget(
///       exception: appError,
///       onRetry: () => ref.refresh(tripsProvider),
///     );
///   },
/// )
/// ```
class AppErrorWidget extends StatelessWidget {
  /// Creates an error display widget.
  ///
  /// [error] chấp nhận bất kỳ Object nào (AppException, FirebaseException, etc.)
  /// và tự động normalize thành AppException.
  /// [onRetry] hiển thị nút thử lại khi được cung cấp.
  /// [customMessage] ghi đè message từ exception nếu có.
  const AppErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.customMessage,
  });

  /// Error object — sẽ được normalize thành AppException.
  final Object error;

  /// Optional retry callback. Shows retry button when provided.
  final VoidCallback? onRetry;

  /// Optional custom message to override exception.message.
  final String? customMessage;

  @override
  Widget build(BuildContext context) {
    final exception = AppException.normalizeError(error);
    final displayMessage = customMessage ?? exception.message;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error Icon
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            SizedBox(height: AppSpacing.lg),

            // Error Message
            Text(
              displayMessage,
              style: AppTypography.bodyMD.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            // Retry Button (if onRetry provided)
            if (onRetry != null) ...[
              SizedBox(height: AppSpacing.xl),
              GradientButton(text: 'Thử lại', onPressed: onRetry, width: 200),
            ],
          ],
        ),
      ),
    );
  }
}
