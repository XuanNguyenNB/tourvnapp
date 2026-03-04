/// Barrel export cho ImageUploadService với conditional import.
///
/// - Trên web: dùng implementation với dart:html (Canvas resize, FileUploadInputElement)
/// - Trên mobile/IO: dùng stub (throw UnsupportedError, admin chỉ trên web)
///
/// Consumer tiếp tục import file này như trước — API không thay đổi.
library image_upload_service;

export 'image_upload_service_stub.dart'
    if (dart.library.html) 'image_upload_service_web.dart';
