class AdminRecentActivity {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final DateTime? createdAt;
  final String route;
  final String status;

  const AdminRecentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.route,
    this.createdAt,
    this.status = '',
  });
}

class AdminDestinationContentStats {
  final int locationCount;
  final int reviewCount;

  const AdminDestinationContentStats({
    this.locationCount = 0,
    this.reviewCount = 0,
  });
}

class AdminStats {
  final int totalUsers;
  final int publishedDestinations;
  final int publishedLocations;
  final int publishedReviews;
  final int pendingComments;
  final int flaggedComments;
  final int pendingAiDrafts;
  final int contentMissingImage;
  final int contentMissingCoordinates;
  final List<AdminRecentActivity> recentActivities;

  const AdminStats({
    required this.totalUsers,
    required this.publishedDestinations,
    required this.publishedLocations,
    required this.publishedReviews,
    required this.pendingComments,
    required this.flaggedComments,
    required this.pendingAiDrafts,
    required this.contentMissingImage,
    required this.contentMissingCoordinates,
    required this.recentActivities,
  });

  int get totalDestinations => publishedDestinations;
  int get totalLocations => publishedLocations;
  int get totalReviews => publishedReviews;
}

typedef AdminMetrics = AdminStats;
