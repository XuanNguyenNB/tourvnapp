import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_stats_provider.dart';
import '../widgets/admin_custom_sidebar.dart';

class AdminLayoutScreen extends ConsumerWidget {
  const AdminLayoutScreen({
    super.key,
    required this.currentPath,
    required this.child,
  });

  final String currentPath;
  final Widget child;

  int get _selectedIndex {
    if (currentPath.startsWith('/admin/categories')) return 1;
    if (currentPath.startsWith('/admin/destinations')) return 2;
    if (currentPath.startsWith('/admin/locations')) return 3;
    if (currentPath.startsWith('/admin/reviews')) return 4;
    if (currentPath.startsWith('/admin/comments')) return 5;
    if (currentPath.startsWith('/admin/import')) return 6;
    if (currentPath.startsWith('/admin/ai-content')) return 7;
    return 0;
  }

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

  String _pageTitle() {
    switch (_selectedIndex) {
      case 1:
        return 'Danh mục';
      case 2:
        return 'Điểm đến';
      case 3:
        return 'Địa điểm';
      case 4:
        return 'Bài viết';
      case 5:
        return 'Bình luận';
      case 6:
        return 'Nhập JSON';
      case 7:
        return 'Nội dung AI';
      default:
        return 'Tổng quan';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final session = ref.watch(appSessionProvider).asData?.value;
    final pendingComments = statsAsync.value?.pendingComments ?? 0;
    final pendingDrafts = statsAsync.value?.pendingAiDrafts ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Row(
          children: [
            AdminCustomSidebar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  _onDestinationSelected(context, index),
              userName: session?.user?.displayName,
              userEmail: session?.user?.email,
              userAvatarUrl: session?.user?.photoUrl,
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
                  selectedIcon: Icons.article_rounded,
                  label: 'Bài viết',
                ),
                AdminSidebarItem(
                  icon: Icons.comment_outlined,
                  selectedIcon: Icons.comment_rounded,
                  label: 'Bình luận',
                  badgeCount: pendingComments,
                ),
                AdminSidebarItem(
                  icon: Icons.upload_file_outlined,
                  selectedIcon: Icons.upload_file_rounded,
                  label: 'Nhập JSON',
                ),
                AdminSidebarItem(
                  icon: Icons.auto_awesome_outlined,
                  selectedIcon: Icons.auto_awesome,
                  label: 'Nội dung AI',
                  badgeCount: pendingDrafts,
                ),
              ],
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 76,
                    margin: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pageTitle(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bảng điều hành quản trị TourVN',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            session?.user?.email?.trim().isNotEmpty == true
                                ? session!.user!.email!
                                : 'Quản trị viên nội bộ',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4338CA),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1440),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Container(
                              color: const Color(0xFFF8FAFC),
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
