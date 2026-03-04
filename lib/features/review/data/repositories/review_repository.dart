import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/review.dart';

/// Repository for accessing review data from Firestore.
class ReviewRepository {
  final FirebaseFirestore _firestore;

  ReviewRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetches a review by its ID
  ///
  /// Returns the [Review] if found, throws an exception if not found.
  Future<Review> getReviewById(String id) async {
    final doc = await _firestore.collection('reviews').doc(id).get();
    if (!doc.exists) throw Exception('Review not found: $id');
    return Review.fromJson(doc.data()!);
  }

  /// Fetches all reviews
  Future<List<Review>> getAllReviews() async {
    final snapshot = await _firestore.collection('reviews').get();
    return snapshot.docs.map((d) => Review.fromJson(d.data())).toList();
  }

  /// Create new review
  Future<void> createReview(Review review) async {
    await _firestore.collection('reviews').doc(review.id).set(review.toJson());
  }

  /// Update existing review (excludes engagement stats fields)
  Future<void> updateReview(Review review) async {
    await _firestore
        .collection('reviews')
        .doc(review.id)
        .update(review.toEditableJson());
  }

  /// Delete review
  Future<void> deleteReview(String id) async {
    await _firestore.collection('reviews').doc(id).delete();
  }

  // ── Pagination Methods ─────────────────────────────────────

  /// Get reviews with cursor-based pagination.
  /// Optionally filter by destinationId.
  Future<({List<Review> items, DocumentSnapshot? lastDoc})>
  getReviewsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? destinationId,
  }) async {
    Query query = _firestore
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (destinationId != null && destinationId.isNotEmpty) {
      query = query.where('destinationId', isEqualTo: destinationId);
    }
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snapshot = await query.get();
    final items = snapshot.docs
        .map((d) => Review.fromJson(d.data() as Map<String, dynamic>))
        .toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    return (items: items, lastDoc: lastDoc);
  }

  // ── Batch Operations ───────────────────────────────────────

  /// Delete multiple reviews atomically using WriteBatch.
  Future<void> deleteReviewBatch(List<String> ids) async {
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.delete(_firestore.collection('reviews').doc(id));
    }
    await batch.commit();
  }

  // ── Server-Side Search ─────────────────────────────────────

  /// Search reviews by title prefix using Firestore range query.
  /// Supports prefix matching which is the native Firestore approach.
  Future<List<Review>> searchReviewsByTitle(
    String prefix, {
    int limit = 20,
  }) async {
    if (prefix.isEmpty) return [];
    final end =
        '${prefix.substring(0, prefix.length - 1)}${String.fromCharCode(prefix.codeUnitAt(prefix.length - 1) + 1)}';
    final snapshot = await _firestore
        .collection('reviews')
        .where('title', isGreaterThanOrEqualTo: prefix)
        .where('title', isLessThan: end)
        .limit(limit)
        .get();
    return snapshot.docs.map((d) => Review.fromJson(d.data())).toList();
  }
}

/// Provider for Firestore
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for ReviewRepository
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(firestore: ref.watch(firestoreProvider));
});
