import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tour_vn/core/utils/vietnamese_text_utils.dart';
import '../../domain/entities/destination.dart';
import '../../domain/entities/location.dart';

/// Repository for fetching destination data from Firestore.
class DestinationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get destination by ID
  ///
  /// Returns the destination if found, throws exception if not found.
  Future<Destination> getDestinationById(String id) async {
    final doc = await _firestore.collection('destinations').doc(id).get();
    if (!doc.exists) {
      throw Exception('Destination not found: $id');
    }
    return Destination.fromJson(doc.data()!);
  }

  /// Get all destinations
  Future<List<Destination>> getAllDestinations() async {
    final snapshot = await _firestore.collection('destinations').get();
    return snapshot.docs.map((d) => Destination.fromJson(d.data())).toList();
  }

  /// Search destinations by name
  Future<List<Destination>> searchDestinations(String query) async {
    final all = await getAllDestinations();
    final lowerQuery = query.toLowerCase();
    return all.where((d) => d.name.toLowerCase().contains(lowerQuery)).toList();
  }

  /// Create new destination
  Future<void> createDestination(Destination destination) async {
    await _firestore
        .collection('destinations')
        .doc(destination.id)
        .set(destination.toJson());
  }

  /// Update existing destination (excludes computed stats fields)
  Future<void> updateDestination(Destination destination) async {
    await _firestore
        .collection('destinations')
        .doc(destination.id)
        .update(destination.toEditableJson());
  }

  /// Delete destination
  Future<void> deleteDestination(String id) async {
    await _firestore.collection('destinations').doc(id).delete();
  }

  /// Get all locations for a destination
  Future<List<Location>> getLocationsByDestination(String destinationId) async {
    final snapshot = await _firestore
        .collection('locations')
        .where('destinationId', isEqualTo: destinationId)
        .get();
    return snapshot.docs.map((d) => Location.fromJson(d.data())).toList();
  }

  /// Get locations filtered by category
  Future<List<Location>> getLocationsByCategory(
    String destinationId,
    String category,
  ) async {
    var query = _firestore
        .collection('locations')
        .where('destinationId', isEqualTo: destinationId);

    if (category.toLowerCase() != 'all') {
      query = query.where('category', isEqualTo: category.toLowerCase());
    }

    final snapshot = await query.get();
    return snapshot.docs.map((d) => Location.fromJson(d.data())).toList();
  }

  /// Get a single location by ID
  Future<Location> getLocationById(String locationId) async {
    final doc = await _firestore.collection('locations').doc(locationId).get();
    if (!doc.exists) throw Exception('Location not found: $locationId');
    return Location.fromJson(doc.data()!);
  }

  /// Get multiple locations by their IDs
  Future<List<Location>> getLocationsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    // Firestore 'whereIn' supports up to 10 elements per query
    const int chunkSize = 10;
    final List<Location> result = [];

    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(
        i,
        i + chunkSize > ids.length ? ids.length : i + chunkSize,
      );

      final snapshot = await _firestore
          .collection('locations')
          .where('id', whereIn: chunk)
          .get();

      result.addAll(snapshot.docs.map((d) => Location.fromJson(d.data())));
    }

    return result;
  }

  /// Get all locations across all destinations
  Future<List<Location>> getAllLocations() async {
    final snapshot = await _firestore.collection('locations').get();
    return snapshot.docs.map((d) => Location.fromJson(d.data())).toList();
  }

  /// Fix locations that have destinationId stored as display name
  /// (e.g. "Đà Lạt") instead of the slug ID ("da-lat").
  /// This is a one-time data migration helper.
  Future<int> fixInconsistentDestinationIds() async {
    // Build name -> id map from destinations collection
    final destSnapshot = await _firestore.collection('destinations').get();
    final nameToId = <String, String>{};
    final validIds = <String>{};
    for (final doc in destSnapshot.docs) {
      final data = doc.data();
      final id = data['id'] as String? ?? doc.id;
      final name = data['name'] as String? ?? '';
      validIds.add(id);
      if (name.isNotEmpty) {
        nameToId[name] = id;
      }
    }

    // Find locations with wrong destinationId
    final locSnapshot = await _firestore.collection('locations').get();
    final batch = _firestore.batch();
    int fixCount = 0;

    for (final doc in locSnapshot.docs) {
      final data = doc.data();
      final destId = data['destinationId'] as String? ?? '';
      // If destinationId is not a valid slug ID but matches a name, fix it
      if (destId.isNotEmpty &&
          !validIds.contains(destId) &&
          nameToId.containsKey(destId)) {
        final correctId = nameToId[destId]!;
        print('Fixing location "${data['name']}": "$destId" -> "$correctId"');
        batch.update(doc.reference, {'destinationId': correctId});
        fixCount++;
      }
    }

    if (fixCount > 0) {
      await batch.commit();
      print('Fixed $fixCount locations with inconsistent destinationId');
    }
    return fixCount;
  }

  /// Search locations by query using server-side Firestore queries.
  ///
  /// **Scalability note:** Previously this method fetched ALL locations then
  /// filtered client-side, burning Firestore reads proportional to the entire
  /// collection size. Now uses `searchLocationsByKeywords` with Firestore
  /// `array-contains` for O(result) reads instead of O(total) reads.
  ///
  /// Searches both original and diacritics-removed versions of the query
  /// to support Vietnamese text search.
  Future<List<Location>> searchLocations(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final normalizedQuery = query.toLowerCase().trim();
      final noDiacriticsQuery = VietnameseTextUtils.removeDiacritics(
        normalizedQuery,
      );

      // Use server-side search with array-contains on searchKeywords
      final results = await searchLocationsByKeywords(
        noDiacriticsQuery,
        limit: 20,
      );

      // If diacritics version differs, also search with original to catch
      // locations that store Vietnamese keywords
      if (noDiacriticsQuery != normalizedQuery) {
        final vietnameseResults = await searchLocationsByKeywords(
          normalizedQuery,
          limit: 20,
        );

        // Merge results, avoiding duplicates
        final existingIds = results.map((r) => r.id).toSet();
        for (final loc in vietnameseResults) {
          if (!existingIds.contains(loc.id)) {
            results.add(loc);
          }
        }
      }

      return results;
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  /// Create new location
  Future<void> createLocation(Location location) async {
    await _firestore
        .collection('locations')
        .doc(location.id)
        .set(location.toJson());
  }

  /// Update existing location (excludes user-generated stats)
  Future<void> updateLocation(Location location) async {
    await _firestore
        .collection('locations')
        .doc(location.id)
        .update(location.toEditableJson());
  }

  /// Delete location
  Future<void> deleteLocation(String id) async {
    await _firestore.collection('locations').doc(id).delete();
  }

  // ── Pagination Methods ─────────────────────────────────────

  /// Get destinations with cursor-based pagination.
  /// Returns a record of (items, lastDocument for next page cursor).
  Future<({List<Destination> items, DocumentSnapshot? lastDoc})>
  getDestinationsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore
        .collection('destinations')
        .orderBy('name')
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snapshot = await query.get();
    final items = snapshot.docs
        .map((d) => Destination.fromJson(d.data() as Map<String, dynamic>))
        .toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    return (items: items, lastDoc: lastDoc);
  }

  /// Get locations with cursor-based pagination.
  /// Optionally filter by destinationId.
  Future<({List<Location> items, DocumentSnapshot? lastDoc})>
  getLocationsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? destinationId,
  }) async {
    Query query = _firestore
        .collection('locations')
        .orderBy('name')
        .limit(limit);
    if (destinationId != null && destinationId.isNotEmpty) {
      query = query.where('destinationId', isEqualTo: destinationId);
    }
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snapshot = await query.get();
    final items = snapshot.docs
        .map((d) => Location.fromJson(d.data() as Map<String, dynamic>))
        .toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    return (items: items, lastDoc: lastDoc);
  }

  // ── Batch Operations ───────────────────────────────────────

  /// Delete multiple destinations atomically using WriteBatch.
  /// Firestore limits batches to 500 operations.
  Future<void> deleteDestinationBatch(List<String> ids) async {
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.delete(_firestore.collection('destinations').doc(id));
    }
    await batch.commit();
  }

  /// Delete multiple locations atomically using WriteBatch.
  Future<void> deleteLocationBatch(List<String> ids) async {
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.delete(_firestore.collection('locations').doc(id));
    }
    await batch.commit();
  }

  // ── Server-Side Search ─────────────────────────────────────

  /// Search locations using Firestore array-contains on searchKeywords.
  /// More scalable than client-side search for large collections.
  Future<List<Location>> searchLocationsByKeywords(
    String keyword, {
    String? destinationId,
    int limit = 20,
  }) async {
    Query query = _firestore
        .collection('locations')
        .where('searchKeywords', arrayContains: keyword.toLowerCase())
        .limit(limit);

    if (destinationId != null && destinationId.isNotEmpty) {
      query = query.where('destinationId', isEqualTo: destinationId);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((d) => Location.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }
}
