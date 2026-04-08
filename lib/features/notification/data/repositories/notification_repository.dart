import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_model.dart';

/// Repository cho thông báo in-app, lưu trữ trên Firestore
/// Collection path: users/{uid}/notifications
class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Lấy collection ref cho user
  CollectionReference<Map<String, dynamic>> _notificationsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  /// Stream danh sách thông báo (mới nhất trước, giới hạn 50)
  Stream<List<AppNotification>> getNotifications(String userId) {
    return _notificationsRef(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  /// Stream đếm số thông báo chưa đọc
  Stream<int> getUnreadCount(String userId) {
    return _notificationsRef(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Đánh dấu 1 thông báo đã đọc
  Future<void> markAsRead(String userId, String notificationId) async {
    await _notificationsRef(userId).doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Đánh dấu tất cả thông báo đã đọc
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final unread = await _notificationsRef(userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  /// Xóa 1 thông báo
  Future<void> deleteNotification(String userId, String notificationId) async {
    await _notificationsRef(userId).doc(notificationId).delete();
  }

  /// Tạo thông báo (dùng cho seeding/testing)
  Future<void> createNotification(
    String userId,
    AppNotification notification,
  ) async {
    await _notificationsRef(userId).add(notification.toFirestore());
  }

  /// Seed thông báo mẫu cho demo ĐATN
  /// Chỉ seed khi collection chưa có document nào
  Future<void> seedDemoNotifications(String userId) async {
    final existing = await _notificationsRef(userId).limit(1).get();
    if (existing.docs.isNotEmpty) return; // Đã có data, không seed

    final now = DateTime.now();
    final demoNotifications = [
      AppNotification(
        id: '',
        userId: userId,
        title: 'Chào mừng đến TourVN! 🎉',
        body: 'Cảm ơn bạn đã sử dụng ứng dụng. Khám phá những điểm đến tuyệt vời ngay!',
        type: NotificationType.system,
        createdAt: now.subtract(const Duration(minutes: 5)),
        actionRoute: '/explore',
      ),
      AppNotification(
        id: '',
        userId: userId,
        title: 'Gợi ý cho bạn ✨',
        body: 'Đà Lạt — thành phố ngàn hoa đang vào mùa đẹp nhất. Lên kế hoạch ngay!',
        type: NotificationType.recommendation,
        createdAt: now.subtract(const Duration(hours: 2)),
        actionRoute: '/explore',
      ),
      AppNotification(
        id: '',
        userId: userId,
        title: 'Mẹo du lịch',
        body: 'Bạn có thể vuốt sang trái để xóa thông báo, hoặc chạm để xem chi tiết.',
        type: NotificationType.system,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      AppNotification(
        id: '',
        userId: userId,
        title: 'Khám phá gần bạn 📍',
        body: 'Có 3 điểm đến phổ biến trong bán kính 50km. Xem ngay!',
        type: NotificationType.recommendation,
        createdAt: now.subtract(const Duration(days: 1)),
        actionRoute: '/explore',
      ),
    ];

    final batch = _firestore.batch();
    for (final notification in demoNotifications) {
      final docRef = _notificationsRef(userId).doc();
      batch.set(docRef, notification.toFirestore());
    }
    await batch.commit();
  }
}

/// Provider cho NotificationRepository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});
