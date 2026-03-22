import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/admin_stats_provider.dart';

class AdminStatsGrid extends StatelessWidget {
  const AdminStatsGrid({super.key, required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1000
            ? 3
            : constraints.maxWidth > 650
            ? 2
            : 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: crossAxisCount == 1 ? 2.8 : 1.8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              title: 'Người dùng',
              value: stats.totalUsers.toString(),
              icon: Icons.people_outline,
              color: const Color(0xFF6366F1),
            ),
            _StatCard(
              title: 'Điểm đến',
              value: stats.totalDestinations.toString(),
              icon: Icons.location_city_outlined,
              color: const Color(0xFF10B981),
            ),
            _StatCard(
              title: 'Địa điểm',
              value: stats.totalLocations.toString(),
              icon: Icons.place_outlined,
              color: const Color(0xFFF59E0B),
            ),
            _StatCard(
              title: 'Bài viết',
              value: stats.totalReviews.toString(),
              icon: Icons.article_outlined,
              color: const Color(0xFF8B5CF6),
            ),
            _StatCard(
              title: 'Bình luận chờ duyệt',
              value: stats.pendingComments.toString(),
              icon: Icons.comment_outlined,
              color: const Color(0xFFEF4444),
            ),
            _StatCard(
              title: 'AI Drafts chờ duyệt',
              value: stats.pendingAiDrafts.toString(),
              icon: Icons.auto_awesome,
              color: const Color(0xFFF97316),
              onTap: () => context.go('/admin/ai-content'),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
