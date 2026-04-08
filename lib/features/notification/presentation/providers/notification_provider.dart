import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/features/auth/presentation/providers/auth_provider.dart';
import 'package:tour_vn/features/notification/data/repositories/notification_repository.dart';
import 'package:tour_vn/features/notification/domain/entities/notification_model.dart';

/// Stream danh sách thông báo của user hiện tại
final notificationListProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.isAnonymous) {
    return Stream.value([]);
  }
  final repo = ref.read(notificationRepositoryProvider);
  // Seed demo data nếu chưa có (fire-and-forget)
  repo.seedDemoNotifications(user.uid);
  return repo.getNotifications(user.uid);
});

/// Stream đếm số thông báo chưa đọc (dùng cho badge trên nút chuông)
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.isAnonymous) {
    return Stream.value(0);
  }
  final repo = ref.read(notificationRepositoryProvider);
  return repo.getUnreadCount(user.uid);
});

/// Notifier cho các actions: mark read, delete
class NotificationActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Đánh dấu 1 thông báo đã đọc
  Future<void> markAsRead(String notificationId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAsRead(user.uid, notificationId);
  }

  /// Đánh dấu tất cả đã đọc
  Future<void> markAllAsRead() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAllAsRead(user.uid);
  }

  /// Xóa 1 thông báo
  Future<void> deleteNotification(String notificationId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final repo = ref.read(notificationRepositoryProvider);
    await repo.deleteNotification(user.uid, notificationId);
  }
}

/// Provider cho notification actions
final notificationActionsProvider =
    NotifierProvider<NotificationActionsNotifier, void>(
  NotificationActionsNotifier.new,
);
