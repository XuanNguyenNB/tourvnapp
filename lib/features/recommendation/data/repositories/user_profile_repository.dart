import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_profile.dart';

/// Repository for managing user profiles in Firestore.
///
/// Schema: `users/{uid}/profile` (single document per user).
class UserProfileRepository {
  final FirebaseFirestore _firestore;

  UserProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _profileDoc(String userId) =>
      _firestore.collection('users').doc(userId);

  /// Get user profile. Returns null if not yet created.
  Future<UserProfile?> getProfile(String userId) async {
    final doc = await _profileDoc(userId).get();
    final data = doc.data();
    if (data == null || !data.containsKey('preferredCategoryIds')) {
      return null;
    }
    return UserProfile.fromMap({...data, 'userId': userId});
  }

  /// Stream user profile for reactive updates.
  Stream<UserProfile?> watchProfile(String userId) {
    return _profileDoc(userId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null || !data.containsKey('preferredCategoryIds')) {
        return null;
      }
      return UserProfile.fromMap({...data, 'userId': userId});
    });
  }

  /// Create or update user profile.
  Future<void> saveProfile(UserProfile profile) async {
    await _profileDoc(
      profile.userId,
    ).set(profile.toMap(), SetOptions(merge: true));
  }

  /// Update only specific preference fields.
  Future<void> updatePreferences({
    required String userId,
    List<String>? preferredCategoryIds,
    List<String>? preferredTags,
    TravelPace? travelPace,
    BudgetLevel? budgetLevel,
    GroupType? groupType,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (preferredCategoryIds != null) {
      updates['preferredCategoryIds'] = preferredCategoryIds;
    }
    if (preferredTags != null) {
      updates['preferredTags'] = preferredTags;
    }
    if (travelPace != null) {
      updates['travelPace'] = travelPace.name;
    }
    if (budgetLevel != null) {
      updates['budgetLevel'] = budgetLevel.name;
    }
    if (groupType != null) {
      updates['groupType'] = groupType.name;
    }
    await _profileDoc(userId).set(updates, SetOptions(merge: true));
  }
}

/// Riverpod provider for UserProfileRepository.
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository();
});
