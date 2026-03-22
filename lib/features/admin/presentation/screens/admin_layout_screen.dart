import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_stats_provider.dart';
import '../widgets/admin_custom_sidebar.dart';

/// Admin layout screen that wraps admin pages with a sidebar.
///
/// Uses ConsumerWidget to watch pending counts and show badges.
class AdminLayoutScreen extends ConsumerWidget {
  final String currentPath;
  final Widget child;

  const AdminLayoutScreen({
    super.key,
    required this.currentPath,
    required this.child,
  });

  /// Map route paths to sidebar indices
  int get _selectedIndex {
    if (currentPath.startsWith('/admin/categories')) return 1;
    if (currentPath.startsWith('/admin/destinations')) return 2;
    if (currentPath.startsWith('/admin/locations')) return 3;
    if (currentPath.startsWith('/admin/reviews')) return 4;
    if (currentPath.startsWith('/admin/comments')) return 5;
    if (currentPath.startsWith('/admin/import')) return 6;
    if (currentPath.startsWith('/admin/ai-content')) return 7;
    return 0; // /admin (overview)
  }

  /// Admin route paths corresponding to sidebar indices
  static const _adminPaths = [
    '/admin',
    '/admin/categories',
    '/admin/destinations',
    '/admin/locations',
    '/admin/reviews',
    '/admin/comments',
    '/admin/import',
    '/admin/ai-content',
  ];

  void _onDestinationSelected(BuildContext context, int index) {
    context.go(_adminPaths[index]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch stats for badge counts
    final statsAsync = ref.watch(adminStatsProvider);
    final pendingComments = statsAsync.value?.pendingComments ?? 0;
    final pendingDrafts = statsAsync.value?.pendingAiDrafts ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Row(
        children: [
          AdminCustomSidebar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                _onDestinationSelected(context, index),
            destinations: [
              AdminSidebarItem(
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard_rounded,
                label: 'Tổng quan',
              ),
              AdminSidebarItem(
                icon: Icons.category_outlined,
                selectedIcon: Icons.category_rounded,
                label: 'Danh mục',
              ),
              AdminSidebarItem(
                icon: Icons.map_outlined,
                selectedIcon: Icons.map_rounded,
                label: 'Điểm đến',
              ),
              AdminSidebarItem(
                icon: Icons.place_outlined,
                selectedIcon: Icons.place_rounded,
                label: 'Địa điểm',
              ),
              AdminSidebarItem(
                icon: Icons.article_outlined,
                selectedIcon: Icons.article,
                label: 'Bài viết',
              ),
              AdminSidebarItem(
                icon: Icons.comment_outlined,
                selectedIcon: Icons.comment,
                label: 'Bình luận',
                badgeCount: pendingComments,
              ),
              AdminSidebarItem(
                icon: Icons.upload_file_outlined,
                selectedIcon: Icons.upload_file_rounded,
                label: 'Import JSON',
              ),
              AdminSidebarItem(
                icon: Icons.auto_awesome_outlined,
                selectedIcon: Icons.auto_awesome,
                label: 'AI Content',
                badgeCount: pendingDrafts,
              ),
            ],
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
