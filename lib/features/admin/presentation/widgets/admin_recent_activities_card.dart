import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminRecentActivitiesCard extends StatelessWidget {
  const AdminRecentActivitiesCard({super.key, required this.activities});

  final List<Map<String, dynamic>> activities;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hoạt động gần đây',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.go('/admin/reviews'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                child: Text(
                  'Không có hoạt động nào gần đây',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: activities.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final activity = activities[index];
                final createdAt = activity['createdAt'];

                var dateText = '';
                if (createdAt is Timestamp) {
                  final dateTime = createdAt.toDate();
                  dateText =
                      '${dateTime.day}/${dateTime.month}/${dateTime.year} '
                      '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  hoverColor: Colors.grey.withValues(alpha: 0.05),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(
                      0xFF8B5CF6,
                    ).withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.article,
                      color: Color(0xFF8B5CF6),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    activity['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: dateText.isEmpty
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            dateText,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      activity['type'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
