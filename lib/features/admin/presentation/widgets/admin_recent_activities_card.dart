import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/admin_metrics.dart';

class AdminRecentActivitiesCard extends StatelessWidget {
  const AdminRecentActivitiesCard({super.key, required this.activities});

  final List<AdminRecentActivity> activities;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoạt động gần đây',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tổng hợp từ nội dung, kiểm duyệt và lịch sử import.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/admin/comments'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Mở moderation'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.12)),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Chưa có hoạt động vận hành gần đây',
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return ListTile(
                  onTap: () => context.go(activity.route),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  tileColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: _activityColor(
                      activity.type,
                    ).withValues(alpha: 0.12),
                    child: Icon(
                      _activityIcon(activity.type),
                      size: 20,
                      color: _activityColor(activity.type),
                    ),
                  ),
                  title: Text(
                    activity.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _subtitle(activity),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      _activityLabel(activity.type),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _activityColor(activity.type),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _subtitle(AdminRecentActivity activity) {
    final createdAt = activity.createdAt;
    final dateText = createdAt == null
        ? 'Không rõ thời điểm'
        : DateFormat('dd/MM/yyyy • HH:mm').format(createdAt);
    final subtitle = activity.subtitle.trim();
    return subtitle.isEmpty ? dateText : '$subtitle • $dateText';
  }

  String _activityLabel(String type) {
    switch (type) {
      case 'destination':
        return 'Điểm đến';
      case 'location':
        return 'Địa điểm';
      case 'review':
        return 'Bài viết';
      case 'comment':
        return 'Bình luận';
      case 'import':
        return 'Import';
      default:
        return type;
    }
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'destination':
        return Icons.map_outlined;
      case 'location':
        return Icons.place_outlined;
      case 'review':
        return Icons.article_outlined;
      case 'comment':
        return Icons.comment_outlined;
      case 'import':
        return Icons.upload_file_outlined;
      default:
        return Icons.bolt_outlined;
    }
  }

  Color _activityColor(String type) {
    switch (type) {
      case 'destination':
        return const Color(0xFF0F766E);
      case 'location':
        return const Color(0xFF0284C7);
      case 'review':
        return const Color(0xFF7C3AED);
      case 'comment':
        return const Color(0xFFDC2626);
      case 'import':
        return const Color(0xFFB45309);
      default:
        return const Color(0xFF4B5563);
    }
  }
}
