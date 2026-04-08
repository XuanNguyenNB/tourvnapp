import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/core/providers/firebase_providers.dart';
import '../../domain/entities/comment.dart';

/// Repository for managing review comments via Firestore.
///
/// Comments are stored as a subcollection under each review:
/// `reviews/{reviewId}/comments/{commentId}`
///
/// Moderation flow:
/// - `getComments()` returns only approved comments for regular users
/// - `getFlaggedComments()` returns flagged comments for admin dashboard
/// - `updateCommentStatus()` allows admin to approve/reject comments
class CommentRepository {
  final FirebaseFirestore _firestore;

  CommentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get comments collection reference for a review.
  CollectionReference<Map<String, dynamic>> _commentsRef(String reviewId) {
    return _firestore
        .collection('reviews')
        .doc(reviewId)
        .collection('comments');
  }

  Query<Map<String, dynamic>> _commentCollectionGroupQuery({
    String? status,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collectionGroup('comments');

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query;
  }

  bool _isMissingIndexError(Object error) {
    return error is FirebaseException && error.code == 'failed-precondition';
  }

  Comment _commentFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    data['id'] = doc.id;
    data['reviewId'] =
        data['reviewId'] ?? doc.reference.parent.parent?.id ?? '';
    return Comment.fromJson(data);
  }

  List<Comment> _applyAdminCursorFallback(
    List<Comment> comments, {
    DocumentSnapshot? startAfter,
  }) {
    if (startAfter == null) return comments;

    final raw = startAfter.data();
    if (raw is! Map<String, dynamic>) {
      return comments;
    }

    final cursorId = startAfter.id;
    final cursorReviewId =
        raw['reviewId'] as String? ??
        startAfter.reference.parent.parent?.id ??
        '';

    final cursorIndex = comments.indexWhere(
      (comment) => comment.id == cursorId && comment.reviewId == cursorReviewId,
    );

    if (cursorIndex == -1 || cursorIndex + 1 >= comments.length) {
      return const [];
    }

    return comments.sublist(cursorIndex + 1);
  }

  Future<List<Comment>> _scanCommentsForReview(
    String reviewId, {
    String? status,
  }) async {
    final snapshot = await _commentsRef(reviewId).get();
    final items =
        snapshot.docs.map(_commentFromDoc).where((comment) {
          return status == null || comment.status == status;
        }).toList()..sort((a, b) {
          final byDate = b.createdAt.compareTo(a.createdAt);
          if (byDate != 0) return byDate;
          return b.id.compareTo(a.id);
        });
    return items;
  }

  Future<List<Comment>> _scanAllComments({String? status}) async {
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
        final comment = _commentFromDoc(doc);
        if (status == null || comment.status == status) {
          comments.add(comment);
        }
      }
    }

    comments.sort((a, b) {
      final byDate = b.createdAt.compareTo(a.createdAt);
      if (byDate != 0) return byDate;
      final byReview = b.reviewId.compareTo(a.reviewId);
      if (byReview != 0) return byReview;
      return b.id.compareTo(a.id);
    });

    return comments;
  }

  /// Fetch **approved** comments for a review, ordered by newest first.
  ///
  /// Only returns comments with `status == 'approved'` so flagged/rejected
  /// comments are hidden from regular users.
  ///
  /// [limit] - Maximum number of comments to return.
  /// [startAfter] - Document snapshot for cursor-based pagination.
  Future<List<Comment>> getComments(
    String reviewId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _commentsRef(reviewId)
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map(_commentFromDoc).toList();
    } catch (error) {
      if (!_isMissingIndexError(error)) rethrow;

      final fallback = await _scanCommentsForReview(
        reviewId,
        status: 'approved',
      );
      final sliced = _applyAdminCursorFallback(
        fallback,
        startAfter: startAfter,
      );
      return sliced.take(limit).toList();
    }
  }

  /// Add a new comment to a review.
  ///
  /// Uses a batch write to:
  /// 1. Create the comment document (with moderation status)
  /// 2. Increment commentCount on the review document
  ///    (only if comment is approved; flagged comments don't count)
  Future<Comment> addComment(String reviewId, Comment comment) async {
    final batch = _firestore.batch();

    // 1. Create comment document
    final commentRef = _commentsRef(reviewId).doc();
    final commentWithId = comment.copyWith(id: commentRef.id);
    batch.set(commentRef, commentWithId.toJson());

    // 2. Only increment commentCount for approved comments
    if (comment.status == 'approved') {
      final reviewRef = _firestore.collection('reviews').doc(reviewId);
      batch.update(reviewRef, {'commentCount': FieldValue.increment(1)});
    }

    await batch.commit();
    return commentWithId;
  }

  /// Delete a comment from a review.
  ///
  /// Uses a batch write to:
  /// 1. Delete the comment document
  /// 2. Decrement commentCount on the review document
  ///    (only if the comment was approved)
  Future<void> deleteComment(
    String reviewId,
    String commentId, {
    bool wasApproved = true,
  }) async {
    final batch = _firestore.batch();

    // 1. Delete comment
    final commentRef = _commentsRef(reviewId).doc(commentId);
    batch.delete(commentRef);

    // 2. Decrement commentCount only for approved comments
    if (wasApproved) {
      final reviewRef = _firestore.collection('reviews').doc(reviewId);
      batch.update(reviewRef, {'commentCount': FieldValue.increment(-1)});
    }

    await batch.commit();
  }

  /// Get total comment count for a review (from review document).
  Future<int> getCommentCount(String reviewId) async {
    final doc = await _firestore.collection('reviews').doc(reviewId).get();
    return doc.data()?['commentCount'] as int? ?? 0;
  }

  // ══════════════════════════════════════════════════════════
  // MODERATION METHODS — Used by Admin Dashboard
  // ══════════════════════════════════════════════════════════

  /// Update the moderation status of a comment.
  ///
  /// [status] can be 'approved', 'flagged', or 'rejected'.
  /// When approving a previously flagged comment, also increments commentCount.
  Future<void> updateCommentStatus({
    required String reviewId,
    required String commentId,
    required String status,
    required String moderatedBy,
  }) async {
    final batch = _firestore.batch();
    final commentRef = _commentsRef(reviewId).doc(commentId);

    // 1. Update comment status
    batch.update(commentRef, {
      'status': status,
      'moderatedBy': moderatedBy,
      'moderatedAt': FieldValue.serverTimestamp(),
    });

    // 2. If approving a flagged comment, increment commentCount
    if (status == 'approved') {
      final reviewRef = _firestore.collection('reviews').doc(reviewId);
      batch.update(reviewRef, {'commentCount': FieldValue.increment(1)});
    }

    await batch.commit();
  }

  /// Fetch all flagged comments across all reviews.
  ///
  /// Uses a collectionGroup query with indexes instead of review-by-review scans.
  Future<List<Comment>> getFlaggedComments({int limit = 50}) async {
    return getAllComments(status: 'flagged', limit: limit);
  }

  /// Fetch all comments (any status) across all reviews for admin.
  ///
  /// Optionally filter by [status].
  Future<List<Comment>> getAllComments({String? status, int limit = 50}) async {
    final result = await getCommentsForAdmin(status: status, limit: limit);
    return result.items;
  }

  Future<({List<Comment> items, DocumentSnapshot? lastDoc})>
  getCommentsForAdmin({
    String? status,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      final snapshot = await _commentCollectionGroupQuery(
        status: status,
        limit: limit,
        startAfter: startAfter,
      ).get();

      final items = snapshot.docs.map(_commentFromDoc).toList();

      return (
        items: items,
        lastDoc: snapshot.docs.length == limit ? snapshot.docs.last : null,
      );
    } catch (error) {
      if (!_isMissingIndexError(error)) rethrow;

      final fallback = await _scanAllComments(status: status);
      final sliced = _applyAdminCursorFallback(
        fallback,
        startAfter: startAfter,
      );
      final items = startAfter == null ? fallback : sliced;

      return (items: items.take(limit).toList(), lastDoc: null);
    }
  }

  Future<({List<Comment> items, DocumentSnapshot? lastDoc})>
  fetchAdminComments({
    String? status,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) {
    return getCommentsForAdmin(
      status: status,
      limit: limit,
      startAfter: startAfter,
    );
  }
}

/// Provider for CommentRepository
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(firestore: ref.watch(firestoreProvider));
});
