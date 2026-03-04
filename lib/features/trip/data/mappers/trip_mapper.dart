import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/trip.dart';

/// Mapper to convert between [Trip] domain entity and Firestore documents.
///
/// This layer handles Firestore-specific types (e.g., [Timestamp]) so that
/// domain entities remain free of data-layer dependencies.
///
/// ## Architecture
/// ```
/// Domain (Trip with DateTime) <-> Data (TripMapper with Timestamp) <-> Firestore
/// ```
class TripMapper {
  /// Convert a [Trip] domain entity to a Firestore-compatible map.
  ///
  /// Converts [DateTime] fields to Firestore [Timestamp] for proper
  /// server-side indexing and ordering.
  static Map<String, dynamic> toFirestore(Trip trip) {
    final map = trip.toMap();
    // Override DateTime fields with Firestore Timestamp
    map['createdAt'] = Timestamp.fromDate(trip.createdAt);
    map['updatedAt'] = Timestamp.fromDate(trip.updatedAt);
    return map;
  }

  /// Convert a Firestore document map to a [Trip] domain entity.
  ///
  /// Handles both [Timestamp] (from Firestore) and raw values gracefully
  /// for backward compatibility and edge cases.
  static Trip fromFirestore(Map<String, dynamic> map) {
    // Convert Timestamp fields to DateTime before passing to Trip.fromMap
    final normalizedMap = Map<String, dynamic>.from(map);
    normalizedMap['createdAt'] = _toDateTime(map['createdAt']);
    normalizedMap['updatedAt'] = _toDateTime(map['updatedAt']);
    return Trip.fromMap(normalizedMap);
  }

  /// Safely convert a Firestore value to [DateTime].
  ///
  /// Handles:
  /// - [Timestamp] from Firestore
  /// - [DateTime] if already converted
  /// - [String] ISO 8601 format
  /// - Falls back to [DateTime.now()] if null or unrecognized
  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
