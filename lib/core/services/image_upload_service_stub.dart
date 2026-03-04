import 'dart:typed_data';

/// Stub implementation cho non-web platforms.
///
/// Trên mobile (iOS/Android), admin dashboard không available.
/// Class này giữ cùng API static methods như web implementation
/// nhưng throw UnsupportedError cho mọi operation.
class ImageUploadService {
  static Future<PickedImage?> pickImage() {
    throw UnsupportedError(
      'ImageUploadService chưa được implement cho platform này. '
      'Admin dashboard chỉ khả dụng trên web.',
    );
  }

  static Future<String> uploadBytes({
    required Uint8List bytes,
    required String storagePath,
    String contentType = 'image/jpeg',
    void Function(double progress)? onProgress,
  }) {
    throw UnsupportedError(
      'ImageUploadService chưa được implement cho platform này.',
    );
  }

  static Future<String> uploadDestinationHero({
    required PickedImage image,
    required String destinationId,
    void Function(double progress)? onProgress,
  }) {
    throw UnsupportedError(
      'ImageUploadService chưa được implement cho platform này.',
    );
  }

  static Future<void> deleteDestinationHero(String destinationId) {
    throw UnsupportedError(
      'ImageUploadService chưa được implement cho platform này.',
    );
  }

  static Future<String> uploadReviewHero({
    required PickedImage image,
    required String reviewId,
    void Function(double progress)? onProgress,
  }) {
    throw UnsupportedError(
      'ImageUploadService chưa được implement cho platform này.',
    );
  }

  static Future<void> deleteReviewHero(String reviewId) {
    throw UnsupportedError(
      'ImageUploadService chưa được implement cho platform này.',
    );
  }
}

/// Kết quả pick ảnh.
class PickedImage {
  final Uint8List bytes;
  final String filename;

  PickedImage({required this.bytes, required this.filename});

  /// Kích thước file (KB)
  int get sizeKB => bytes.length ~/ 1024;
}
