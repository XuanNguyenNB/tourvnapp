import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_stats_provider.dart';
import '../widgets/admin_error_state.dart';
import '../widgets/admin_overview_header.dart';
import '../widgets/admin_recent_activities_card.dart';
import '../widgets/admin_stats_grid.dart';

class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final session = ref.watch(appSessionProvider).asData?.value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: statsAsync.when(
        data: (stats) => _DashboardBody(
          stats: stats,
          adminName: session?.user?.displayName,
          onRefresh: () => ref.invalidate(adminStatsProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AdminErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminStatsProvider),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.stats,
    required this.onRefresh,
    this.adminName,
  });

  final AdminStats stats;
  final String? adminName;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminOverviewHeader(onRefresh: onRefresh, adminName: adminName),
          const SizedBox(height: 24),
          _QuickActionsRow(),
          const SizedBox(height: 24),
          AdminStatsGrid(stats: stats),
          const SizedBox(height: 24),
          AdminRecentActivitiesCard(activities: stats.recentActivities),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        label: 'Tạo điểm đến',
        icon: Icons.add_location_alt_outlined,
        route: '/admin/destinations',
      ),
      _QuickAction(
        label: 'Nhập JSON',
        icon: Icons.upload_file_outlined,
        route: '/admin/import',
      ),
      _QuickAction(
        label: 'Xử lý bình luận',
        icon: Icons.mark_chat_unread_outlined,
        route: '/admin/comments',
      ),
      _QuickAction(
        label: 'Xem AI draft',
        icon: Icons.auto_awesome_outlined,
        route: '/admin/ai-content',
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions.map((action) {
        return OutlinedButton.icon(
          onPressed: () => context.go(action.route),
          icon: Icon(action.icon, size: 18),
          label: Text(action.label),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF111827),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}
