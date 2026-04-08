import 'package:cloud_firestore/cloud_firestore.dart';

/// Loại thông báo
enum NotificationType {
  trip,           // Chuyến đi: tạo trip, nhắc lịch trình
  review,         // Đánh giá: bình luận mới, lượt thích
  system,         // Hệ thống: chào mừng, cập nhật app
  recommendation, // Gợi ý: điểm đến mới, địa điểm gần bạn
}

/// Entity thông báo trong app
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? actionRoute; // Deep link, e.g. "/trips/abc123"
  final String? imageUrl;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.actionRoute,
    this.imageUrl,
  });

  /// Factory từ Firestore document
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: _parseType(data['type'] as String?),
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      actionRoute: data['actionRoute'] as String?,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  /// Chuyển sang Map để lưu Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'actionRoute': actionRoute,
      'imageUrl': imageUrl,
    };
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      actionRoute: actionRoute,
      imageUrl: imageUrl,
    );
  }

  static NotificationType _parseType(String? value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.system,
    );
  }

  /// Icon emoji theo loại
  String get typeEmoji {
    switch (type) {
      case NotificationType.trip:
        return '🗺️';
      case NotificationType.review:
        return '⭐';
      case NotificationType.system:
        return '🔔';
      case NotificationType.recommendation:
        return '✨';
    }
  }

  /// Tên loại thông báo
  String get typeName {
    switch (type) {
      case NotificationType.trip:
        return 'Chuyến đi';
      case NotificationType.review:
        return 'Đánh giá';
      case NotificationType.system:
        return 'Hệ thống';
      case NotificationType.recommendation:
        return 'Gợi ý';
    }
  }
}
