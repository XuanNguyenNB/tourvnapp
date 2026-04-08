import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/admin_dashboard_repository.dart';
import '../models/admin_metrics.dart';
import 'admin_destination_provider.dart';

export '../models/admin_metrics.dart';

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final repository = ref.watch(adminDashboardRepositoryProvider);
  return repository.fetchAdminMetrics();
});

final adminDestinationContentStatsProvider =
    FutureProvider<Map<String, AdminDestinationContentStats>>((ref) async {
      final repository = ref.watch(adminDashboardRepositoryProvider);
      final destinationIds = ref.watch(
        adminDestinationProvider.select(
          (state) => state.items.map((item) => item.id).toList(growable: false),
        ),
      );
      return repository.fetchDestinationContentStats(destinationIds);
    });
