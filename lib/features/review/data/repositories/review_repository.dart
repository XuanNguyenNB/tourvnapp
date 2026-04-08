import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/core/providers/firebase_providers.dart';
import '../../domain/entities/review.dart';

/// Repository for accessing review data from Firestore.
class ReviewRepository {
  final FirebaseFirestore _firestore;

  ReviewRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  bool _isMissingIndexError(Object error) {
    return error is FirebaseException && error.code == 'failed-precondition';
  }

  /// Fetches a review by its ID
  ///
  /// Returns the [Review] if found, throws an exception if not found.
  Future<Review> getReviewById(String id) async {
    final doc = await _firestore.collection('reviews').doc(id).get();
    if (!doc.exists) throw Exception('Review not found: $id');
    return Review.fromJson(doc.data()!);
  }

  /// Fetches a published review by ID for public routes/screens.
  Future<Review> getPublishedReviewById(String id) async {
    final review = await getReviewById(id);
    if (!review.isPublished) {
      throw Exception('Published review not found: $id');
    }
    return review;
  }

  /// Fetches all reviews
  Future<List<Review>> getAllReviews() async {
    final snapshot = await _firestore.collection('reviews').get();
    return snapshot.docs.map((d) => Review.fromJson(d.data())).toList();
  }

  /// Fetches published reviews only for public feeds.
  Future<List<Review>> getPublishedReviews() async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('status', isEqualTo: 'published')
        .get();
    return snapshot.docs.map((d) => Review.fromJson(d.data())).toList();
  }

  /// Fetch reviews filtered by status.
  Future<List<Review>> getReviewsByStatus(
    String status, {
    int limit = 50,
  }) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('status', isEqualTo: status)
        .limit(limit)
        .get();
    return snapshot.docs.map((d) => Review.fromJson(d.data())).toList();
  }

  /// Create new review
  Future<void> createReview(Review review) async {
    final docRef = _firestore.collection('reviews').doc(review.id);
    final existing = await docRef.get();
    if (existing.exists) {
      throw Exception('Bài viết với ID "${review.id}" đã tồn tại.');
    }

    final prepared = await _prepareReviewForWrite(review);
    await docRef.set(prepared.toJson());
  }

  /// Update existing review (excludes engagement stats fields)
  Future<void> updateReview(Review review) async {
    final prepared = await _prepareReviewForWrite(review);
    await _firestore
        .collection('reviews')
        .doc(review.id)
        .update(prepared.toEditableJson());
  }

  /// Delete review
  Future<void> deleteReview(String id) async {
    await _firestore.collection('reviews').doc(id).delete();
  }

  Future<Review> _prepareReviewForWrite(Review review) async {
    final uniqueLocationIds = review.relatedLocationIds.toSet().toList();
    final normalizedDestinationId = review.destinationId?.trim();

    var destinationName = review.destinationName?.trim();

    if (uniqueLocationIds.isNotEmpty) {
      if (normalizedDestinationId == null || normalizedDestinationId.isEmpty) {
        throw Exception('Bài viết gắn địa điểm phải chọn điểm đến.');
      }

      final locations = await _getLocationsByIds(uniqueLocationIds);
      if (locations.length != uniqueLocationIds.length) {
        throw Exception('Một hoặc nhiều địa điểm được chọn không còn tồn tại.');
      }

      final invalidLocations = locations
          .where(
            (location) => location.destinationId != normalizedDestinationId,
          )
          .toList();
      if (invalidLocations.isNotEmpty) {
        throw Exception(
          'Có địa điểm không thuộc điểm đến đã chọn: ${invalidLocations.first.name}.',
        );
      }
    }

    if (normalizedDestinationId != null && normalizedDestinationId.isNotEmpty) {
      final destinationDoc = await _firestore
          .collection('destinations')
          .doc(normalizedDestinationId)
          .get();

      if (!destinationDoc.exists) {
        throw Exception('Điểm đến đã chọn không tồn tại.');
      }

      destinationName = destinationName?.isNotEmpty == true
          ? destinationName
          : destinationDoc.data()?['name'] as String?;
    } else {
      destinationName = null;
    }

    return review.copyWith(
      destinationId: normalizedDestinationId?.isEmpty == true
          ? null
          : normalizedDestinationId,
      destinationName: destinationName,
      relatedLocationIds: uniqueLocationIds,
    );
  }

  Future<List<Map<String, dynamic>>> _getLocationDocsByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return const [];

    const chunkSize = 10;
    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(
        i,
        i + chunkSize > ids.length ? ids.length : i + chunkSize,
      );
      final snapshot = await _firestore
          .collection('locations')
          .where('id', whereIn: chunk)
          .get();
      results.addAll(snapshot.docs.map((doc) => doc.data()));
    }
    return results;
  }

  Future<List<({String id, String destinationId, String name})>>
  _getLocationsByIds(List<String> ids) async {
    final docs = await _getLocationDocsByIds(ids);
    return docs
        .map(
          (doc) => (
            id: doc['id'] as String,
            destinationId: doc['destinationId'] as String,
            name: doc['name'] as String,
          ),
        )
        .toList();
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
    try {
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
      final lastDoc = snapshot.docs.length == limit ? snapshot.docs.last : null;
      return (items: items, lastDoc: lastDoc);
    } catch (error) {
      if (!_isMissingIndexError(error)) rethrow;

      final items = (await getAllReviews()).where((review) {
        return destinationId == null ||
            destinationId.isEmpty ||
            review.destinationId == destinationId;
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return (items: items.take(limit).toList(), lastDoc: null);
    }
  }

  Future<({List<Review> items, DocumentSnapshot? lastDoc})> fetchAdminReviews({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? destinationId,
    String? category,
    String? locationId,
    String search = '',
  }) async {
    final normalizedSearch = search.trim().toLowerCase();
    final queryLimit = normalizedSearch.isNotEmpty ? 200 : limit;

    try {
      Query query = _firestore.collection('reviews');

      if (destinationId != null && destinationId.isNotEmpty) {
        query = query.where('destinationId', isEqualTo: destinationId);
      }
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }
      if (locationId != null && locationId.isNotEmpty) {
        query = query.where('relatedLocationIds', arrayContains: locationId);
      }

      query = query.orderBy('createdAt', descending: true).limit(queryLimit);

      if (startAfter != null && normalizedSearch.isEmpty) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      var items = snapshot.docs
          .map((doc) => Review.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      if (normalizedSearch.isNotEmpty) {
        items = items.where((review) {
          return review.title.toLowerCase().contains(normalizedSearch) ||
              review.authorName.toLowerCase().contains(normalizedSearch);
        }).toList();
      }

      return (
        items: normalizedSearch.isNotEmpty ? items.take(limit).toList() : items,
        lastDoc:
            normalizedSearch.isNotEmpty || snapshot.docs.length < queryLimit
            ? null
            : snapshot.docs.last,
      );
    } catch (error) {
      if (!_isMissingIndexError(error)) rethrow;

      var items = await getAllReviews();
      items = items.where((review) {
        final matchDestination =
            destinationId == null ||
            destinationId.isEmpty ||
            review.destinationId == destinationId;
        final matchCategory =
            category == null || category.isEmpty || review.category == category;
        final matchLocation =
            locationId == null ||
            locationId.isEmpty ||
            review.relatedLocationIds.contains(locationId);
        final matchSearch =
            normalizedSearch.isEmpty ||
            review.title.toLowerCase().contains(normalizedSearch) ||
            review.authorName.toLowerCase().contains(normalizedSearch);
        return matchDestination &&
            matchCategory &&
            matchLocation &&
            matchSearch;
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return (items: items.take(limit).toList(), lastDoc: null);
    }
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

  Future<List<Review>> searchPublishedReviewsByTitle(
    String prefix, {
    int limit = 20,
  }) async {
    if (prefix.isEmpty) return [];
    final allPublished = await getPublishedReviews();
    final normalizedPrefix = prefix.trim().toLowerCase();
    return allPublished
        .where(
          (review) => review.title.toLowerCase().contains(normalizedPrefix),
        )
        .take(limit)
        .toList();
  }
}

/// Provider for ReviewRepository
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(firestore: ref.watch(firestoreProvider));
});
