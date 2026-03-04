import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/mappers/trip_mapper.dart';

/// Service for migrating trips between users.
///
/// Used when an anonymous user signs in with an existing Google/Facebook account
/// and trips need to be migrated from the anonymous user to the authenticated user.
class TripMigrationService {
  final FirebaseFirestore _firestore;

  TripMigrationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Migrate trips using cached trip data.
  ///
  /// This is the preferred method when switching from anonymous to existing
  /// authenticated account, because the trips are fetched BEFORE signing out
  /// of the anonymous session.
  ///
  /// Returns the number of trips migrated.
  Future<int> migrateTripsFromCache({
    required String toUserId,
    required List<Map<String, dynamic>> tripDataList,
  }) async {
    if (tripDataList.isEmpty) {
      debugPrint('🔵 [TripMigration] No cached trips to migrate');
      return 0;
    }

    debugPrint(
      '🔵 [TripMigration] Migrating ${tripDataList.length} cached trips to $toUserId',
    );

    try {
      final toTripsRef = _firestore
          .collection('users')
          .doc(toUserId)
          .collection('trips');

      int migratedCount = 0;
      final batch = _firestore.batch();

      for (final tripData in tripDataList) {
        final trip = TripMapper.fromFirestore(tripData);

        // Check if trip with same destination already exists in target user
        final existingTrips = await toTripsRef
            .where('destinationId', isEqualTo: trip.destinationId)
            .limit(1)
            .get();

        if (existingTrips.docs.isEmpty) {
          // No existing trip, create new one with new userId
          final migratedTrip = trip.copyWith(
            userId: toUserId,
            updatedAt: DateTime.now(),
          );

          batch.set(
            toTripsRef.doc(trip.id),
            TripMapper.toFirestore(migratedTrip),
          );
          migratedCount++;
          debugPrint(
            '🔵 [TripMigration] Queued migration for trip: ${trip.name}',
          );
        } else {
          debugPrint(
            '⚠️ [TripMigration] Trip for ${trip.destinationName} already exists, skipping',
          );
        }
      }

      // Commit all migrations
      await batch.commit();
      debugPrint(
        '✅ [TripMigration] Successfully migrated $migratedCount trips',
      );

      return migratedCount;
    } catch (e, stackTrace) {
      debugPrint('🔴 [TripMigration] Error: $e');
      debugPrint('🔴 [TripMigration] StackTrace: $stackTrace');
      return 0;
    }
  }

  /// Migrate all trips from anonymous user to authenticated user.
  ///
  /// This copies trips from `users/{fromUserId}/trips` to `users/{toUserId}/trips`.
  /// Note: This may fail with permission-denied if anonymous session has ended.
  /// Use migrateTripsFromCache instead when possible.
  ///
  /// Returns the number of trips migrated.
  Future<int> migrateTrips({
    required String fromUserId,
    required String toUserId,
  }) async {
    if (fromUserId == toUserId) {
      debugPrint('🔵 [TripMigration] Same user IDs, no migration needed');
      return 0;
    }

    debugPrint(
      '🔵 [TripMigration] Starting migration from $fromUserId to $toUserId',
    );

    try {
      // Get all trips from anonymous user
      final fromTripsRef = _firestore
          .collection('users')
          .doc(fromUserId)
          .collection('trips');

      final toTripsRef = _firestore
          .collection('users')
          .doc(toUserId)
          .collection('trips');

      final snapshot = await fromTripsRef.get();

      if (snapshot.docs.isEmpty) {
        debugPrint('🔵 [TripMigration] No trips to migrate');
        return 0;
      }

      debugPrint(
        '🔵 [TripMigration] Found ${snapshot.docs.length} trips to migrate',
      );

      int migratedCount = 0;
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        final tripData = doc.data();
        final trip = TripMapper.fromFirestore(tripData);

        // Check if trip with same destination already exists in target user
        final existingTrips = await toTripsRef
            .where('destinationId', isEqualTo: trip.destinationId)
            .limit(1)
            .get();

        if (existingTrips.docs.isEmpty) {
          // No existing trip, create new one with new userId
          final migratedTrip = trip.copyWith(
            userId: toUserId,
            updatedAt: DateTime.now(),
          );

          batch.set(
            toTripsRef.doc(trip.id),
            TripMapper.toFirestore(migratedTrip),
          );
          migratedCount++;
          debugPrint(
            '🔵 [TripMigration] Queued migration for trip: ${trip.name}',
          );
        } else {
          // Trip already exists, skip (could merge in the future)
          debugPrint(
            '⚠️ [TripMigration] Trip for ${trip.destinationName} already exists, skipping',
          );
        }
      }

      // Commit all migrations
      await batch.commit();
      debugPrint(
        '✅ [TripMigration] Successfully migrated $migratedCount trips',
      );

      return migratedCount;
    } catch (e, stackTrace) {
      // Permission denied is expected - anonymous user session has ended
      // so we can't read their trips anymore
      if (e.toString().contains('permission-denied')) {
        debugPrint(
          '⚠️ [TripMigration] Cannot migrate: anonymous session expired. '
          'Trips from anonymous session are not recoverable.',
        );
      } else {
        debugPrint('🔴 [TripMigration] Error: $e');
        debugPrint('🔴 [TripMigration] StackTrace: $stackTrace');
      }
      return 0;
    }
  }
}
