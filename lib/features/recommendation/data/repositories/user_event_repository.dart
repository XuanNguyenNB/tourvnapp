import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/user_interaction_event.dart';

/// Repository for tracking user interaction events in Firestore.
///
/// Schema: `users/{uid}/events/{eventId}` (append-only log).
/// Events are used to compute the user interest vector for recommendations.
class UserEventRepository {
  final FirebaseFirestore _firestore;
  static const _uuid = Uuid();

  UserEventRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _eventsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('events');

  /// Log a new interaction event.
  Future<void> logEvent({
    required String userId,
    required String locationId,
    required String destinationId,
    required InteractionType type,
    String? locationCategory,
    List<String> locationTags = const [],
    int? ratingValue,
  }) async {
    final event = UserInteractionEvent(
      id: _uuid.v4(),
      userId: userId,
      locationId: locationId,
      destinationId: destinationId,
      locationCategory: locationCategory,
      locationTags: locationTags,
      type: type,
      ratingValue: ratingValue,
      timestamp: DateTime.now(),
    );
    await _eventsCollection(userId).doc(event.id).set(event.toMap());
  }

  /// Get all events for a user (most recent first).
  /// Limited to [limit] events to avoid loading too much data.
  Future<List<UserInteractionEvent>> getEvents(
    String userId, {
    int limit = 200,
  }) async {
    final snapshot = await _eventsCollection(
      userId,
    ).orderBy('timestamp', descending: true).limit(limit).get();
    return snapshot.docs
        .map((doc) => UserInteractionEvent.fromMap(doc.data()))
        .toList();
  }

  /// Get events for a specific destination.
  Future<List<UserInteractionEvent>> getEventsByDestination(
    String userId,
    String destinationId, {
    int limit = 100,
  }) async {
    final snapshot = await _eventsCollection(userId)
        .where('destinationId', isEqualTo: destinationId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => UserInteractionEvent.fromMap(doc.data()))
        .toList();
  }

  /// Get set of location IDs the user has interacted with (save/addToTrip).
  /// Used for novelty scoring — locations not in this set are novel.
  Future<Set<String>> getInteractedLocationIds(String userId) async {
    final snapshot = await _eventsCollection(
      userId,
    ).where('type', whereIn: ['save', 'addToTrip']).get();
    return snapshot.docs
        .map((doc) => doc.data()['locationId'] as String)
        .toSet();
  }

  /// Compute weighted interest scores per category from events.
  ///
  /// Returns a map of categoryId -> weighted score.
  /// Used as the "interest vector" for recommendation scoring.
  Future<Map<String, double>> computeCategoryInterests(String userId) async {
    final events = await getEvents(userId);
    final interests = <String, double>{};

    for (final event in events) {
      final cat = event.locationCategory;
      if (cat == null) continue;

      // Time decay: events older than 30 days get halved weight
      final daysSince = DateTime.now().difference(event.timestamp).inDays;
      final decay = daysSince > 30 ? 0.5 : 1.0;

      interests[cat] = (interests[cat] ?? 0) + event.type.weight * decay;
    }

    return interests;
  }

  /// Compute weighted interest scores per tag from events.
  Future<Map<String, double>> computeTagInterests(String userId) async {
    final events = await getEvents(userId);
    final interests = <String, double>{};

    for (final event in events) {
      final daysSince = DateTime.now().difference(event.timestamp).inDays;
      final decay = daysSince > 30 ? 0.5 : 1.0;

      for (final tag in event.locationTags) {
        interests[tag] = (interests[tag] ?? 0) + event.type.weight * decay;
      }
    }

    return interests;
  }
}

/// Riverpod provider for UserEventRepository.
final userEventRepositoryProvider = Provider<UserEventRepository>((ref) {
  return UserEventRepository();
});
