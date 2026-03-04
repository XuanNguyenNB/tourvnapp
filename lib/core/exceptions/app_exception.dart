/// Centralized exception class for consistent error handling across TourVN.
///
/// All Firebase calls and async operations should catch platform-specific
/// exceptions and re-throw as AppException with user-friendly Vietnamese messages.
///
/// Example usage:
/// ```dart
/// try {
///   await firestore.collection('trips').doc(id).get();
/// } on FirebaseException catch (e) {
///   throw AppException(
///     code: AppException.FIRESTORE_ERROR,
///     message: AppException.getMessageForCode(AppException.FIRESTORE_ERROR),
///     details: e.toString(),
///   );
/// }
/// ```
class AppException implements Exception {
  /// Error code constant (e.g., FIRESTORE_ERROR, AUTH_ERROR)
  final String code;

  /// User-friendly Vietnamese message to display in UI
  final String message;

  /// Technical details for debugging and logging (optional)
  final String? details;

  const AppException({required this.code, required this.message, this.details});

  // ========================================
  // ERROR CODE CONSTANTS
  // ========================================
  // ignore_for_file: constant_identifier_names

  /// Firestore database operation failed
  static const String FIRESTORE_ERROR = 'FIRESTORE_ERROR';

  /// Firebase Authentication error
  static const String AUTH_ERROR = 'AUTH_ERROR';

  /// Network connection error
  static const String NETWORK_ERROR = 'NETWORK_ERROR';

  /// Unknown or unexpected error
  static const String UNKNOWN_ERROR = 'UNKNOWN_ERROR';

  /// Trip not found in database
  static const String TRIP_NOT_FOUND = 'TRIP_NOT_FOUND';

  /// Destination not found in database
  static const String DESTINATION_NOT_FOUND = 'DESTINATION_NOT_FOUND';

  /// Location not found in database
  static const String LOCATION_NOT_FOUND = 'LOCATION_NOT_FOUND';

  /// Review not found in database
  static const String REVIEW_NOT_FOUND = 'REVIEW_NOT_FOUND';

  /// User input validation failed
  static const String VALIDATION_ERROR = 'VALIDATION_ERROR';

  /// User lacks permission for this operation
  static const String PERMISSION_DENIED = 'PERMISSION_DENIED';

  /// Authentication required for this operation
  static const String AUTH_REQUIRED = 'AUTH_REQUIRED';

  /// User cancelled authentication flow (not an error, just cancelled)
  static const String AUTH_CANCELLED = 'AUTH_CANCELLED';

  // ========================================
  // VIETNAMESE ERROR MESSAGES
  // ========================================

  /// Get user-friendly Vietnamese message for error code
  static String getMessageForCode(String code) {
    switch (code) {
      case FIRESTORE_ERROR:
        return 'Không thể kết nối với cơ sở dữ liệu. Vui lòng thử lại.';

      case AUTH_ERROR:
        return 'Đăng nhập không thành công. Vui lòng thử lại.';

      case NETWORK_ERROR:
        return 'Không có kết nối mạng. Vui lòng kiểm tra internet.';

      case TRIP_NOT_FOUND:
        return 'Không tìm thấy chuyến đi.';

      case DESTINATION_NOT_FOUND:
        return 'Không tìm thấy điểm đến.';

      case LOCATION_NOT_FOUND:
        return 'Không tìm thấy địa điểm.';

      case REVIEW_NOT_FOUND:
        return 'Không tìm thấy bài review.';

      case VALIDATION_ERROR:
        return 'Thông tin không hợp lệ. Vui lòng kiểm tra lại.';

      case PERMISSION_DENIED:
        return 'Bạn không có quyền thực hiện thao tác này.';

      case AUTH_REQUIRED:
        return 'Vui lòng đăng nhập để tiếp tục.';

      case AUTH_CANCELLED:
        return 'Đăng nhập đã bị hủy.';

      case UNKNOWN_ERROR:
      default:
        return 'Đã xảy ra lỗi. Vui lòng thử lại sau.';
    }
  }

  /// Chuyển đổi bất kỳ error nào thành AppException một cách an toàn.
  ///
  /// Nếu error đã là AppException → trả về trực tiếp.
  /// Nếu không → wrap vào AppException với code UNKNOWN_ERROR.
  static AppException normalizeError(Object error) {
    if (error is AppException) return error;
    return AppException(
      code: AppException.UNKNOWN_ERROR,
      message: AppException.getMessageForCode(AppException.UNKNOWN_ERROR),
      details: error.toString(),
    );
  }

  @override
  String toString() {
    if (details != null) {
      return 'AppException($code): $message\nDetails: $details';
    }
    return 'AppException($code): $message';
  }

  /// For debugging with full information
  String toDebugString() {
    return 'AppException(\n'
        '  code: $code,\n'
        '  message: $message,\n'
        '  details: ${details ?? 'none'}\n'
        ')';
  }
}
