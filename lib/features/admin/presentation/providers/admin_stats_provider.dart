import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminStats {
  final int totalUsers;
  final int totalDestinations;
  final int totalLocations;
  final int totalReviews;
  final List<Map<String, dynamic>> recentActivities;

  const AdminStats({
    required this.totalUsers,
    required this.totalDestinations,
    required this.totalLocations,
    required this.totalReviews,
    required this.recentActivities,
  });
}

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final firestore = FirebaseFirestore.instance;

  // Use count() aggregation instead of fetching full documents
  // This reduces bandwidth significantly for large collections.
  final usersCount = await firestore.collection('users').count().get();
  final destinationsCount = await firestore
      .collection('destinations')
      .count()
      .get();
  final locationsCount = await firestore.collection('locations').count().get();
  final reviewsCount = await firestore.collection('reviews').count().get();

  // Get recent reviews (latest 5) — still need full docs for title
  final recentReviewsSnapshot = await firestore
      .collection('reviews')
      .orderBy('createdAt', descending: true)
      .limit(5)
      .get();

  final recentActivities = recentReviewsSnapshot.docs.map((doc) {
    final data = doc.data();
    return {
      'id': doc.id,
      'title': data['title'] ?? 'Untitled Review',
      'type': 'review',
      'createdAt': data['createdAt'],
    };
  }).toList();

  return AdminStats(
    totalUsers: usersCount.count ?? 0,
    totalDestinations: destinationsCount.count ?? 0,
    totalLocations: locationsCount.count ?? 0,
    totalReviews: reviewsCount.count ?? 0,
    recentActivities: recentActivities,
  );
});
