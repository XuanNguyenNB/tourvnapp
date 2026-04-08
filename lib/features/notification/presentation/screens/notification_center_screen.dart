import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';
import 'package:tour_vn/features/notification/domain/entities/notification_model.dart';
import 'package:tour_vn/features/notification/presentation/providers/notification_provider.dart';

/// Trung tâm Thông báo — hiển thị danh sách thông báo của user
class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Thông báo', style: AppTypography.headingLG),
        centerTitle: true,
        actions: [
          notificationsAsync.when(
            data: (notifications) {
              final hasUnread = notifications.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.done_all, color: AppColors.primary),
                tooltip: 'Đánh dấu tất cả đã đọc',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(notificationActionsProvider.notifier).markAllAsRead();
                },
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }
          return _buildNotificationList(context, ref, notifications);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text('🔔', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Chưa có thông báo mới',
              style: AppTypography.headingMD.copyWith(
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Khi có thông báo mới, chúng sẽ xuất hiện ở đây',
              textAlign: TextAlign.center,
              style: AppTypography.bodySM.copyWith(
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(
    BuildContext context,
    WidgetRef ref,
    List<AppNotification> notifications,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _NotificationCard(
          notification: notification,
          onTap: () {
            HapticFeedback.lightImpact();
            // Mark as read
            if (!notification.isRead) {
              ref
                  .read(notificationActionsProvider.notifier)
                  .markAsRead(notification.id);
            }
            // Navigate to action route if available
            if (notification.actionRoute != null &&
                notification.actionRoute!.isNotEmpty) {
              context.push(notification.actionRoute!);
            }
          },
          onDismissed: () {
            HapticFeedback.mediumImpact();
            ref
                .read(notificationActionsProvider.notifier)
                .deleteNotification(notification.id);
          },
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Có lỗi xảy ra',
              style: AppTypography.headingMD.copyWith(
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySM.copyWith(
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card hiển thị 1 thông báo
class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => onDismissed(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white
                : AppColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? const Color(0xFFE2E8F0)
                  : AppColors.primary.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon theo type
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    notification.typeEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTypography.labelMD.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Unread dot
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: AppTypography.bodySM.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatRelativeTime(notification.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron nếu có actionRoute
              if (notification.actionRoute != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 12),
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: const Color(0xFFCBD5E1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _typeColor {
    switch (notification.type) {
      case NotificationType.trip:
        return const Color(0xFF3B82F6);
      case NotificationType.review:
        return const Color(0xFFF59E0B);
      case NotificationType.system:
        return AppColors.primary;
      case NotificationType.recommendation:
        return const Color(0xFF10B981);
    }
  }

  /// Format thời gian relative: "Vừa xong", "5 phút trước", "Hôm qua"
  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
