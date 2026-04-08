import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/saved_item.dart';

/// Repository for managing saved/bookmarked items in Firestore.
///
/// Collection path: `users/{uid}/savedItems`
class SavedRepository {
  final FirebaseFirestore _firestore;

  SavedRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reference to the savedItems subcollection for a user.
  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('savedItems');

  /// Watch all saved items for a user, ordered by savedAt desc.
  Stream<List<SavedItem>> watchSavedItems(String uid) {
    return _collection(uid)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SavedItem.fromFirestore(doc)).toList());
  }

  /// Check if a specific item is saved (by itemId).
  Stream<bool> watchIsItemSaved(String uid, String itemId) {
    return _collection(uid)
        .where('itemId', isEqualTo: itemId)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  /// Save an item (review or location).
  Future<void> saveItem(String uid, SavedItem item) async {
    // Check if already saved to avoid duplicates
    final existing = await _collection(uid)
        .where('itemId', isEqualTo: item.itemId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return; // Already saved

    await _collection(uid).add(item.toFirestore());
  }

  /// Unsave an item (by itemId, not document ID).
  Future<void> unsaveItem(String uid, String itemId) async {
    final snapshot = await _collection(uid)
        .where('itemId', isEqualTo: itemId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Delete a saved item by its document ID.
  Future<void> deleteById(String uid, String docId) async {
    await _collection(uid).doc(docId).delete();
  }

  /// Get all saved location IDs for AI planner integration.
  Future<List<String>> getSavedLocationIds(String uid) async {
    final snapshot = await _collection(uid)
        .where('itemType', isEqualTo: 'location')
        .get();

    return snapshot.docs
        .map((doc) => doc.data()['itemId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }
}
