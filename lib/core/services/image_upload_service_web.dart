import 'dart:async';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:firebase_storage/firebase_storage.dart';

/// Web implementation of ImageUploadService.
///
/// Dùng dart:html để pick ảnh qua FileUploadInputElement,
/// Canvas API để resize, và Firebase Storage để upload.
class ImageUploadService {
  static final _storage = FirebaseStorage.instance;

  /// Max width cho ảnh bìa (Full HD)
  static const int maxWidth = 1920;

  /// Pick ảnh từ thiết bị (web), tự resize nếu lớn hơn Full HD.
  /// Returns null nếu user hủy.
  static Future<PickedImage?> pickImage() async {
    final completer = Completer<PickedImage?>();
    var completed = false;

    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    input.onChange.listen((event) {
      if (completed) return;
      final files = input.files;
      if (files == null || files.isEmpty) {
        completed = true;
        completer.complete(null);
        return;
      }

      final file = files.first;
      final fileName = file.name;

      // Đọc file dạng data URL (base64) — cách đáng tin cậy nhất trên web
      final reader = html.FileReader();
      reader.readAsDataUrl(file);

      reader.onLoadEnd.listen((_) async {
        if (completed) return;
        try {
          final dataUrl = reader.result as String;

          // Resize qua Canvas
          final resizedBytes = await _resizeFromDataUrl(dataUrl);

          completed = true;
          completer.complete(
            PickedImage(bytes: resizedBytes, filename: fileName),
          );
        } catch (e) {
          completed = true;
          completer.complete(null);
        }
      });

      reader.onError.listen((_) {
        if (!completed) {
          completed = true;
          completer.complete(null);
        }
      });
    });

    return completer.future;
  }

  /// Resize ảnh từ data URL dùng Canvas API.
  /// Output: JPEG bytes, max width = maxWidth, quality 85%.
  static Future<Uint8List> _resizeFromDataUrl(String dataUrl) async {
    final completer = Completer<Uint8List>();

    final img = html.ImageElement();
    img.src = dataUrl;

    img.onLoad.listen((_) {
      var w = img.naturalWidth;
      var h = img.naturalHeight;

      // Resize nếu lớn hơn maxWidth
      if (w > maxWidth) {
        final ratio = maxWidth / w;
        w = maxWidth;
        h = (h * ratio).round();
      }

      final canvas = html.CanvasElement(width: w, height: h);
      canvas.context2D.drawImageScaled(img, 0, 0, w, h);

      // Xuất ra JPEG data URL
      final jpegDataUrl = canvas.toDataUrl('image/jpeg', 0.85);

      // Decode base64 → bytes
      final uriData = UriData.parse(jpegDataUrl);
      final bytes = uriData.contentAsBytes();

      if (!completer.isCompleted) {
        completer.complete(bytes);
      }
    });

    img.onError.listen((_) {
      if (!completer.isCompleted) {
        completer.completeError('Không thể đọc ảnh');
      }
    });

    return completer.future;
  }

  /// Upload bytes lên Firebase Storage.
  static Future<String> uploadBytes({
    required Uint8List bytes,
    required String storagePath,
    String contentType = 'image/jpeg',
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref().child(storagePath);

    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });
    }

    await uploadTask;
    return ref.getDownloadURL();
  }

  /// Upload ảnh bìa cho destination.
  static Future<String> uploadDestinationHero({
    required PickedImage image,
    required String destinationId,
    void Function(double progress)? onProgress,
  }) async {
    final path = 'destinations/$destinationId/hero.jpg';
    return uploadBytes(
      bytes: image.bytes,
      storagePath: path,
      contentType: 'image/jpeg',
      onProgress: onProgress,
    );
  }

  /// Xóa ảnh bìa của destination.
  static Future<void> deleteDestinationHero(String destinationId) async {
    try {
      final path = 'destinations/$destinationId/hero.jpg';
      await _storage.ref().child(path).delete();
    } catch (e) {
      // Ignored if object does not exist (e.g., they used external URL)
    }
  }

  /// Upload ảnh bìa cho bài viết (review).
  static Future<String> uploadReviewHero({
    required PickedImage image,
    required String reviewId,
    void Function(double progress)? onProgress,
  }) async {
    final path = 'reviews/$reviewId/hero.jpg';
    return uploadBytes(
      bytes: image.bytes,
      storagePath: path,
      contentType: 'image/jpeg',
      onProgress: onProgress,
    );
  }

  /// Xóa ảnh bìa của bài viết (review).
  static Future<void> deleteReviewHero(String reviewId) async {
    try {
      final path = 'reviews/$reviewId/hero.jpg';
      await _storage.ref().child(path).delete();
    } catch (e) {
      // Ignored if object does not exist
    }
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
