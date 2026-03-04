import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of user interactions tracked for personalization.
enum InteractionType {
  /// User viewed a location detail page.
  view,

  /// User saved/bookmarked a location.
  save,

  /// User added a location to their trip.
  addToTrip,

  /// User removed a location from their trip.
  removeFromTrip,

  /// User rated a location after visiting.
  rate;

  /// Weight multiplier for recommendation scoring.
  /// Higher weight = stronger signal of preference.
  double get weight {
    switch (this) {
      case InteractionType.view:
        return 1.0;
      case InteractionType.save:
        return 3.0;
      case InteractionType.addToTrip:
        return 5.0;
      case InteractionType.removeFromTrip:
        return -2.0;
      case InteractionType.rate:
        return 4.0;
    }
  }
}

/// A single user interaction event for personalization tracking.
///
/// Stored at `users/{uid}/events/{eventId}` in Firestore.
/// These events power the recommendation engine by capturing
/// implicit (view) and explicit (save, addToTrip) user signals.
class UserInteractionEvent {
  /// Unique event ID.
  final String id;

  /// Firebase Auth UID of the user.
  final String userId;

  /// ID of the location interacted with.
  final String locationId;

  /// Parent destination ID of the location.
  final String destinationId;

  /// Category of the location (e.g., 'food', 'places').
  final String? locationCategory;

  /// Tags of the location at time of interaction.
  final List<String> locationTags;

  /// Type of interaction.
  final InteractionType type;

  /// Optional rating value (1-5), only for [InteractionType.rate].
  final int? ratingValue;

  /// Timestamp of the interaction.
  final DateTime timestamp;

  const UserInteractionEvent({
    required this.id,
    required this.userId,
    required this.locationId,
    required this.destinationId,
    this.locationCategory,
    this.locationTags = const [],
    required this.type,
    this.ratingValue,
    required this.timestamp,
  });

  /// Create from Firestore document.
  factory UserInteractionEvent.fromMap(Map<String, dynamic> map) {
    return UserInteractionEvent(
      id: map['id'] as String,
      userId: map['userId'] as String,
      locationId: map['locationId'] as String,
      destinationId: map['destinationId'] as String,
      locationCategory: map['locationCategory'] as String?,
      locationTags:
          (map['locationTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      type: InteractionType.values.firstWhere(
        (e) => e.name == (map['type'] as String?),
        orElse: () => InteractionType.view,
      ),
      ratingValue: map['ratingValue'] as int?,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Serialize to Firestore map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'locationId': locationId,
      'destinationId': destinationId,
      'locationCategory': locationCategory,
      'locationTags': locationTags,
      'type': type.name,
      'ratingValue': ratingValue,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  @override
  String toString() =>
      'UserInteractionEvent(type: ${type.name}, location: $locationId)';
}
