import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminStats {
  final int totalUsers;
  final int totalDestinations;
  final int totalLocations;
  final int totalReviews;
  final int pendingComments;
  final int pendingAiDrafts;
  final List<Map<String, dynamic>> recentActivities;

  const AdminStats({
    required this.totalUsers,
    required this.totalDestinations,
    required this.totalLocations,
    required this.totalReviews,
    required this.pendingComments,
    required this.pendingAiDrafts,
    required this.recentActivities,
  });
}

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final firestore = FirebaseFirestore.instance;

  // Use count() aggregation instead of fetching full documents
  final usersCount = await firestore.collection('users').count().get();
  final destinationsCount = await firestore
      .collection('destinations')
      .count()
      .get();
  final locationsCount = await firestore.collection('locations').count().get();
  final reviewsCount = await firestore.collection('reviews').count().get();

  // Count flagged (pending) comments
  final reviewsForComments = await firestore.collection('reviews').get();
  int pendingCount = 0;
  final commentFutures = reviewsForComments.docs.map((reviewDoc) async {
    final flaggedSnapshot = await firestore
        .collection('reviews')
        .doc(reviewDoc.id)
        .collection('comments')
        .where('status', isEqualTo: 'flagged')
        .get();
    pendingCount += flaggedSnapshot.docs.length;
  });
  await Future.wait(commentFutures);

  // Count AI drafts across all content types
  final draftDestinations = await firestore
      .collection('destinations')
      .where('status', isEqualTo: 'draft_ai')
      .count()
      .get();
  final draftLocations = await firestore
      .collection('locations')
      .where('status', isEqualTo: 'draft_ai')
      .count()
      .get();
  final draftReviews = await firestore
      .collection('reviews')
      .where('status', isEqualTo: 'draft_ai')
      .count()
      .get();
  final totalDrafts = (draftDestinations.count ?? 0) +
      (draftLocations.count ?? 0) +
      (draftReviews.count ?? 0);

  // Get recent reviews (latest 5)
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
    pendingComments: pendingCount,
    pendingAiDrafts: totalDrafts,
    recentActivities: recentActivities,
  );
});

