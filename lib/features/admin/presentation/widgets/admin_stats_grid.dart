import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/admin_stats_provider.dart';

class AdminStatsGrid extends StatelessWidget {
  const AdminStatsGrid({super.key, required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCardConfig(
        title: 'Người dùng',
        value: stats.totalUsers.toString(),
        icon: Icons.people_outline,
        color: const Color(0xFF4F46E5),
      ),
      _StatCardConfig(
        title: 'Điểm đến đang public',
        value: stats.publishedDestinations.toString(),
        icon: Icons.map_outlined,
        color: const Color(0xFF0F766E),
        onTap: () => context.go('/admin/destinations'),
      ),
      _StatCardConfig(
        title: 'Địa điểm đang public',
        value: stats.publishedLocations.toString(),
        icon: Icons.place_outlined,
        color: const Color(0xFF0EA5E9),
        onTap: () => context.go('/admin/locations'),
      ),
      _StatCardConfig(
        title: 'Bài viết đang public',
        value: stats.publishedReviews.toString(),
        icon: Icons.article_outlined,
        color: const Color(0xFF7C3AED),
        onTap: () => context.go('/admin/reviews'),
      ),
      _StatCardConfig(
        title: 'Bình luận chờ duyệt',
        value: stats.pendingComments.toString(),
        icon: Icons.mark_chat_unread_outlined,
        color: const Color(0xFFDC2626),
        onTap: () => context.go('/admin/comments'),
      ),
      _StatCardConfig(
        title: 'Bình luận bị gắn cờ',
        value: stats.flaggedComments.toString(),
        icon: Icons.flag_outlined,
        color: const Color(0xFFF97316),
        onTap: () => context.go('/admin/comments'),
      ),
      _StatCardConfig(
        title: 'Bản nháp AI chờ duyệt',
        value: stats.pendingAiDrafts.toString(),
        icon: Icons.auto_awesome,
        color: const Color(0xFF9333EA),
        onTap: () => context.go('/admin/ai-content'),
      ),
      _StatCardConfig(
        title: 'Thiếu ảnh / tọa độ',
        value:
            '${stats.contentMissingImage} / ${stats.contentMissingCoordinates}',
        icon: Icons.rule_folder_outlined,
        color: const Color(0xFFB45309),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1240
            ? 4
            : constraints.maxWidth >= 840
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: crossAxisCount == 1 ? 2.7 : 1.65,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return _StatCard(card: card);
          },
        );
      },
    );
  }
}

class _StatCardConfig {
  const _StatCardConfig({
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
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.card});

  final _StatCardConfig card;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: card.onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
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
                    color: card.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(card.icon, color: card.color, size: 22),
                ),
                if (card.onTap != null) ...[
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            Text(
              card.value,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              card.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
