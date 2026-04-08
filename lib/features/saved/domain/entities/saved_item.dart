import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Represents a saved/bookmarked item (review or location).
///
/// Stored in Firestore at `users/{uid}/savedItems/{autoId}`.
@immutable
class SavedItem {
  /// Firestore document ID.
  final String id;

  /// The ID of the saved item (review ID or location ID).
  final String itemId;

  /// Type of item: 'review' or 'location'.
  final String itemType;

  /// Display title.
  final String title;

  /// Thumbnail image URL.
  final String? imageUrl;

  /// Destination ID (for AI planner integration).
  final String? destinationId;

  /// Destination display name.
  final String? destinationName;

  /// When the item was saved.
  final DateTime savedAt;

  const SavedItem({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.title,
    this.imageUrl,
    this.destinationId,
    this.destinationName,
    required this.savedAt,
  });

  /// Deserialize from Firestore document.
  factory SavedItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SavedItem(
      id: doc.id,
      itemId: data['itemId'] as String? ?? '',
      itemType: data['itemType'] as String? ?? 'location',
      title: data['title'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      destinationId: data['destinationId'] as String?,
      destinationName: data['destinationName'] as String?,
      savedAt: (data['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Serialize to Firestore document data.
  Map<String, dynamic> toFirestore() {
    return {
      'itemId': itemId,
      'itemType': itemType,
      'title': title,
      'imageUrl': imageUrl,
      'destinationId': destinationId,
      'destinationName': destinationName,
      'savedAt': Timestamp.fromDate(savedAt),
    };
  }

  /// Whether this is a location (vs review).
  bool get isLocation => itemType == 'location';

  /// Whether this is a review.
  bool get isReview => itemType == 'review';
}
