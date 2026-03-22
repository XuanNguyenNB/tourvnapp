import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/admin_stats_provider.dart';
import '../widgets/admin_overview_header.dart';
import '../widgets/admin_recent_activities_card.dart';
import '../widgets/admin_stats_grid.dart';

class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: statsAsync.when(
        data: (stats) => _DashboardBody(
          stats: stats,
          onRefresh: () => ref.invalidate(adminStatsProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminStatsProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.stats, required this.onRefresh});

  final AdminStats stats;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminOverviewHeader(onRefresh: onRefresh),
          const SizedBox(height: 36),
          AdminStatsGrid(stats: stats),
          const SizedBox(height: 36),
          const SizedBox(height: 12),
          AdminRecentActivitiesCard(activities: stats.recentActivities),
        ],
      ),
    );
  }
}
