import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/trip.dart';
import '../mappers/trip_mapper.dart';

/// Repository interface for Trip data operations.
///
/// Provides CRUD methods for managing trips in Firestore.
abstract class TripRepository {
  /// Create a new trip.
  Future<Trip> createTrip(Trip trip);

  /// Get a single trip by ID.
  Future<Trip?> getTrip(String userId, String tripId);

  /// Get all trips for a user as a stream for real-time updates.
  Stream<List<Trip>> getUserTrips(String userId);

  /// Get trip by destination ID (to detect existing trip for same destination).
  Future<Trip?> getTripByDestination(String userId, String destinationId);

  /// Update an existing trip.
  Future<void> updateTrip(Trip trip);

  /// Delete a trip.
  Future<void> deleteTrip(String userId, String tripId);

  /// Add activities to existing trip from pending state.
  Future<Trip> addToExistingTrip(Trip existingTrip, Trip newData);
}

/// Firestore implementation of TripRepository.
///
/// Uses `users/{userId}/trips/{tripId}` collection structure.
class FirestoreTripRepository implements TripRepository {
  final FirebaseFirestore _firestore;

  FirestoreTripRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get reference to user's trips collection.
  CollectionReference<Map<String, dynamic>> _tripsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('trips');
  }

  @override
  Future<Trip> createTrip(Trip trip) async {
    debugPrint(
      '📝 [TripRepo] Creating trip: ${trip.id} for user: ${trip.userId}',
    );
    debugPrint('📝 [TripRepo] Trip data: ${TripMapper.toFirestore(trip)}');
    final docRef = _tripsCollection(trip.userId).doc(trip.id);
    await docRef.set(TripMapper.toFirestore(trip));
    debugPrint('✅ [TripRepo] Trip created successfully!');
    return trip;
  }

  @override
  Future<Trip?> getTrip(String userId, String tripId) async {
    final doc = await _tripsCollection(userId).doc(tripId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return TripMapper.fromFirestore(doc.data()!);
  }

  @override
  Stream<List<Trip>> getUserTrips(String userId) {
    return _tripsCollection(
      userId,
    ).orderBy('updatedAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TripMapper.fromFirestore(doc.data()))
          .toList();
    });
  }

  @override
  Future<Trip?> getTripByDestination(
    String userId,
    String destinationId,
  ) async {
    final querySnapshot = await _tripsCollection(
      userId,
    ).where('destinationId', isEqualTo: destinationId).limit(1).get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return TripMapper.fromFirestore(querySnapshot.docs.first.data());
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    debugPrint('📝 [TripRepo] Updating trip: ${trip.id}');
    final docRef = _tripsCollection(trip.userId).doc(trip.id);
    await docRef.set(TripMapper.toFirestore(trip), SetOptions(merge: true));
    debugPrint('✅ [TripRepo] Trip updated successfully!');
  }

  @override
  Future<void> deleteTrip(String userId, String tripId) async {
    await _tripsCollection(userId).doc(tripId).delete();
  }

  @override
  Future<Trip> addToExistingTrip(Trip existingTrip, Trip newData) async {
    // Merge days and activities
    final updatedTrip = existingTrip.copyWith(
      days: newData.days,
      updatedAt: DateTime.now(),
    );

    await updateTrip(updatedTrip);
    return updatedTrip;
  }
}

/// Provider for TripRepository.
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return FirestoreTripRepository();
});
