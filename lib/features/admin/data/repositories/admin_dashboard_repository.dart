import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../review/domain/entities/comment.dart';
import '../../presentation/models/admin_metrics.dart';

class AdminDashboardRepository {
  AdminDashboardRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<AdminStats> fetchAdminMetrics() async {
    List<Comment>? cachedComments;
    Future<List<Comment>> loadAllComments() async {
      return cachedComments ??= await _scanAllComments();
    }

    final usersCount = await _safeCount(_firestore.collection('users'));
    final publishedDestinations = await _safeCount(
      _firestore.collection('destinations').where('status', isEqualTo: 'published'),
    );
    final publishedLocations = await _safeCount(
      _firestore.collection('locations').where('status', isEqualTo: 'published'),
    );
    final publishedReviews = await _safeCount(
      _firestore.collection('reviews').where('status', isEqualTo: 'published'),
    );
    final pendingCommentsCount = await _countCommentsByStatus(
      'flagged',
      fallbackLoader: loadAllComments,
    );

    final flaggedCommentsCount = await _countCommentsWithFlagReason(
      fallbackLoader: loadAllComments,
      fallbackValue: pendingCommentsCount,
    );

    final draftDestinations = await _safeCount(
      _firestore.collection('destinations').where('status', isEqualTo: 'draft_ai'),
    );
    final draftLocations = await _safeCount(
      _firestore.collection('locations').where('status', isEqualTo: 'draft_ai'),
    );
    final draftReviews = await _safeCount(
      _firestore.collection('reviews').where('status', isEqualTo: 'draft_ai'),
    );

    final destinationsMissingImage = await _safeCount(
      _firestore.collection('destinations').where('heroImage', isEqualTo: ''),
    );
    final locationsMissingImage = await _safeCount(
      _firestore.collection('locations').where('image', isEqualTo: ''),
    );
    final reviewsMissingImage = await _safeCount(
      _firestore.collection('reviews').where('heroImage', isEqualTo: ''),
    );
    final locationsMissingCoordinates = await _safeCount(
      _firestore.collection('locations').where('latitude', isNull: true),
    );

    final recentActivities = await _fetchRecentActivities();

    return AdminStats(
      totalUsers: usersCount,
      publishedDestinations: publishedDestinations,
      publishedLocations: publishedLocations,
      publishedReviews: publishedReviews,
      pendingComments: pendingCommentsCount,
      flaggedComments: flaggedCommentsCount,
      pendingAiDrafts: draftDestinations + draftLocations + draftReviews,
      contentMissingImage:
          destinationsMissingImage + locationsMissingImage + reviewsMissingImage,
      contentMissingCoordinates: locationsMissingCoordinates,
      recentActivities: recentActivities,
    );
  }

  /// Safely count documents, returning 0 on permission-denied or other errors.
  Future<int> _safeCount(Query<Map<String, dynamic>> query) async {
    try {
      final result = await query.count().get();
      return result.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, AdminDestinationContentStats>>
  fetchDestinationContentStats(List<String> destinationIds) async {
    if (destinationIds.isEmpty) return const {};

    final entries = await Future.wait(
      destinationIds.map((destinationId) async {
        final locationCount = await _firestore
            .collection('locations')
            .where('destinationId', isEqualTo: destinationId)
            .count()
            .get();
        final reviewCount = await _firestore
            .collection('reviews')
            .where('destinationId', isEqualTo: destinationId)
            .count()
            .get();

        return MapEntry(
          destinationId,
          AdminDestinationContentStats(
            locationCount: locationCount.count ?? 0,
            reviewCount: reviewCount.count ?? 0,
          ),
        );
      }),
    );

    return Map<String, AdminDestinationContentStats>.fromEntries(entries);
  }

  Future<void> logImportResult({
    required int imported,
    required int skipped,
    required int failed,
    required int total,
    required List<String> collections,
    required List<String> errors,
    String? createdByUid,
    String? createdByName,
    String? createdByEmail,
  }) async {
    await _firestore.collection('admin_import_logs').add({
      'imported': imported,
      'skipped': skipped,
      'failed': failed,
      'total': total,
      'collections': collections,
      'errorCount': errors.length,
      'errors': errors.take(10).toList(),
      'createdByUid': createdByUid,
      'createdByName': createdByName,
      'createdByEmail': createdByEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<AdminRecentActivity>> _fetchRecentActivities() async {
    try {
      final futures = await Future.wait<List<AdminRecentActivity>>([
        _fetchRecentDestinationActivities(),
        _fetchRecentLocationActivities(),
        _fetchRecentReviewActivities(),
        _fetchRecentCommentActivities(),
        _fetchRecentImportActivities(),
      ]);

      final activities = futures.expand((items) => items).toList()
        ..sort((a, b) {
          final aDate = a.createdAt;
          final bDate = b.createdAt;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

      return activities.take(8).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<AdminRecentActivity>> _fetchRecentDestinationActivities() async {
    try {
      final snapshot = await _firestore
          .collection('destinations')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AdminRecentActivity(
          id: doc.id,
          type: 'destination',
          title: data['name'] as String? ?? 'Điểm đến chưa có tên',
          subtitle:
              'Điểm đến ${data['status'] == 'draft_ai' ? 'AI draft' : 'đã cập nhật'}',
          route: '/admin/destinations',
          status: data['status'] as String? ?? '',
          createdAt: _readDate(data['createdAt']),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<AdminRecentActivity>> _fetchRecentLocationActivities() async {
    try {
      final snapshot = await _firestore
          .collection('locations')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AdminRecentActivity(
          id: doc.id,
          type: 'location',
          title: data['name'] as String? ?? 'Địa điểm chưa có tên',
          subtitle: data['destinationName'] as String? ?? 'Địa điểm',
          route: '/admin/locations',
          status: data['status'] as String? ?? '',
          createdAt: _readDate(data['createdAt']),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<AdminRecentActivity>> _fetchRecentReviewActivities() async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AdminRecentActivity(
          id: doc.id,
          type: 'review',
          title: data['title'] as String? ?? 'Bài viết chưa có tiêu đề',
          subtitle: data['authorName'] as String? ?? 'Bài viết',
          route: '/admin/reviews',
          status: data['status'] as String? ?? '',
          createdAt: _readDate(data['createdAt']),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<AdminRecentActivity>> _fetchRecentCommentActivities() async {
    try {
      final snapshot = await _firestore
          .collectionGroup('comments')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final text = (data['text'] as String? ?? '').trim();
        return AdminRecentActivity(
          id: doc.id,
          type: 'comment',
          title: data['userName'] as String? ?? 'Người dùng',
          subtitle: text.isEmpty ? 'Bình luận mới' : text,
          route: '/admin/comments',
          status: data['status'] as String? ?? '',
          createdAt: _readDate(data['createdAt']),
        );
      }).toList();
    } catch (_) {
      // collectionGroup queries may fail with missing index or permission errors.
      // Fallback: scan individual review subcollections.
      try {
        final comments = await _scanAllComments();
        return comments.take(3).map((comment) {
          final text = comment.text.trim();
          return AdminRecentActivity(
            id: comment.id,
            type: 'comment',
            title: comment.userName,
            subtitle: text.isEmpty ? 'Bình luận mới' : text,
            route: '/admin/comments',
            status: comment.status,
            createdAt: comment.createdAt,
          );
        }).toList();
      } catch (_) {
        return const [];
      }
    }
  }

  Future<List<AdminRecentActivity>> _fetchRecentImportActivities() async {
    try {
      final snapshot = await _firestore
          .collection('admin_import_logs')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final imported = data['imported'] as int? ?? 0;
        final failed = data['failed'] as int? ?? 0;
        return AdminRecentActivity(
          id: doc.id,
          type: 'import',
          title: 'Nhập JSON',
          subtitle: failed > 0
              ? '$imported mục thành công, $failed mục lỗi'
              : '$imported mục được nhập thành công',
          route: '/admin/import',
          status: failed > 0 ? 'warning' : 'success',
          createdAt: _readDate(data['createdAt']),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<int> _countCommentsByStatus(
    String status, {
    required Future<List<Comment>> Function() fallbackLoader,
  }) async {
    try {
      final aggregate = await _firestore
          .collectionGroup('comments')
          .where('status', isEqualTo: status)
          .count()
          .get();
      return aggregate.count ?? 0;
    } catch (_) {
      // collectionGroup count may fail (missing index, permission, web interop).
      try {
        final comments = await fallbackLoader();
        return comments.where((comment) => comment.status == status).length;
      } catch (_) {
        return 0;
      }
    }
  }

  Future<int> _countCommentsWithFlagReason({
    required Future<List<Comment>> Function() fallbackLoader,
    required int fallbackValue,
  }) async {
    try {
      final aggregate = await _firestore
          .collectionGroup('comments')
          .where('flagReason', isGreaterThan: '')
          .count()
          .get();
      return aggregate.count ?? fallbackValue;
    } catch (_) {
      try {
        final comments = await fallbackLoader();
        return comments
            .where((comment) => (comment.flagReason ?? '').trim().isNotEmpty)
            .length;
      } catch (_) {
        return fallbackValue;
      }
    }
  }

  Future<List<Comment>> _scanAllComments() async {
    try {
      final reviewsSnapshot = await _firestore.collection('reviews').get();
      if (reviewsSnapshot.docs.isEmpty) return const [];

      final commentSnapshots = await Future.wait(
        reviewsSnapshot.docs.map((reviewDoc) {
          return reviewDoc.reference.collection('comments').get();
        }),
      );

      final comments = <Comment>[];
      for (final snapshot in commentSnapshots) {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          data['reviewId'] =
              data['reviewId'] ?? doc.reference.parent.parent?.id ?? '';
          comments.add(Comment.fromJson(data));
        }
      }

      comments.sort((a, b) {
        final byDate = b.createdAt.compareTo(a.createdAt);
        if (byDate != 0) return byDate;
        return b.id.compareTo(a.id);
      });
      return comments;
    } catch (_) {
      return const [];
    }
  }
}

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>((
  ref,
) {
  return AdminDashboardRepository(firestore: ref.watch(firestoreProvider));
});
