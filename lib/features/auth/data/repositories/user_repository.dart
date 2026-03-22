import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tour_vn/core/exceptions/app_exception.dart';
import 'package:tour_vn/features/auth/domain/entities/user.dart';

class UserOnboardingData {
  final List<String> moodPreferences;
  final List<String> destinationPreferenceIds;
  final bool onboardingCompleted;
  final bool onboardingSkipped;

  const UserOnboardingData({
    this.moodPreferences = const [],
    this.destinationPreferenceIds = const [],
    this.onboardingCompleted = false,
    this.onboardingSkipped = false,
  });

  bool get hasAnyData =>
      onboardingCompleted ||
      onboardingSkipped ||
      moodPreferences.isNotEmpty ||
      destinationPreferenceIds.isNotEmpty;
}

/// Repository for user profile data in Firestore
/// Handles CRUD operations for user documents in 'users' collection
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reference to the users collection
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Create or update user profile in Firestore
  /// Uses merge: true to preserve existing data while updating new fields
  ///
  /// This method performs an upsert operation:
  /// - If user document exists: updates only the provided fields
  /// - If user document doesn't exist: creates new document
  Future<void> createOrUpdateUser(User user) async {
    try {
      final now = FieldValue.serverTimestamp();

      // Main user data update (merge to preserve existing fields)
      await _usersCollection.doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
        'isAnonymous': user.isAnonymous,
        'updatedAt': now,
      }, SetOptions(merge: true));

      // Set createdAt only on first creation (won't overwrite if exists)
      final docSnapshot = await _usersCollection.doc(user.uid).get();
      if (docSnapshot.exists && docSnapshot.data()?['createdAt'] == null) {
        await _usersCollection.doc(user.uid).update({'createdAt': now});
      }
    } on FirebaseException catch (e) {
      throw AppException(
        code: AppException.FIRESTORE_ERROR,
        message: 'Không thể lưu thông tin người dùng.',
        details: 'FirestoreException: ${e.code} - ${e.message}',
      );
    } catch (e) {
      throw AppException(
        code: AppException.UNKNOWN_ERROR,
        message: 'Đã xảy ra lỗi khi lưu thông tin người dùng.',
        details: e.toString(),
      );
    }
  }

  /// Get user profile from Firestore by UID
  /// Returns null if user document doesn't exist
  Future<User?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return User.fromJson(doc.data()!);
    } on FirebaseException catch (e) {
      throw AppException(
        code: AppException.FIRESTORE_ERROR,
        message: 'Không thể tải thông tin người dùng.',
        details: 'FirestoreException: ${e.code} - ${e.message}',
      );
    } catch (e) {
      throw AppException(
        code: AppException.UNKNOWN_ERROR,
        message: 'Đã xảy ra lỗi khi tải thông tin người dùng.',
        details: e.toString(),
      );
    }
  }

  Future<UserOnboardingData?> getOnboardingData(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()!;
      return UserOnboardingData(
        moodPreferences:
            (data['moodPreferences'] as List<dynamic>?)
                ?.map((entry) => entry as String)
                .toList() ??
            const [],
        destinationPreferenceIds:
            (data['destinationPreferences'] as List<dynamic>?)
                ?.map((entry) => entry as String)
                .toList() ??
            const [],
        onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
        onboardingSkipped: data['onboardingSkipped'] as bool? ?? false,
      );
    } on FirebaseException catch (e) {
      throw AppException(
        code: AppException.FIRESTORE_ERROR,
        message: 'Khong the tai du lieu onboarding.',
        details: 'FirestoreException: ${e.code} - ${e.message}',
      );
    } catch (e) {
      throw AppException(
        code: AppException.UNKNOWN_ERROR,
        message: 'Da xay ra loi khi tai du lieu onboarding.',
        details: e.toString(),
      );
    }
  }

  /// Check if user document exists in Firestore
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } on FirebaseException catch (e) {
      throw AppException(
        code: AppException.FIRESTORE_ERROR,
        message: 'Không thể kiểm tra thông tin người dùng.',
        details: 'FirestoreException: ${e.code} - ${e.message}',
      );
    }
  }

  /// Delete user document from Firestore
  /// Used when user deletes their account
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
    } on FirebaseException catch (e) {
      throw AppException(
        code: AppException.FIRESTORE_ERROR,
        message: 'Không thể xóa thông tin người dùng.',
        details: 'FirestoreException: ${e.code} - ${e.message}',
      );
    }
  }

  /// Update user's mood preferences (Story 6.3)
  ///
  /// Saves the list of mood preference names to the user's Firestore document.
  /// Uses merge to preserve other fields.
  Future<void> updateMoodPreferences(String uid, List<String> moods) async {
    try {
      await _usersCollection.doc(uid).set({
        'moodPreferences': moods,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw AppException(
        code: AppException.FIRESTORE_ERROR,
        message: 'Không thể lưu sở thích của bạn.',
        details: 'FirestoreException: ${e.code} - ${e.message}',
      );
    } catch (e) {
      throw AppException(
        code: AppException.UNKNOWN_ERROR,
        message: 'Đã xảy ra lỗi khi lưu sở thích.',
        details: e.toString(),
      );
    }
  }

  /// Mark onboarding as completed (Story 6.3)
  ///
  /// Sets the onboardingCompleted flag to true in Firestore.
  /// This ensures the user won't see onboarding again after signing in
  /// on a different device.
  Future<void> markOnboardingCompleted(
    String uid, {
    List<String> destinationIds = const [],
  }) async {
    try {
      await _usersCollection.doc(uid).set({
        'onboardingCompleted': true,
        'onboardingSkipped': false,
        'destinationPreferences': destinationIds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw AppException(
        code: AppException.FIRESTORE_ERROR,
        message: 'Không thể cập nhật trạng thái.',
        details: 'FirestoreException: ${e.code} - ${e.message}',
      );
    } catch (e) {
      throw AppException(
        code: AppException.UNKNOWN_ERROR,
        message: 'Đã xảy ra lỗi khi cập nhật trạng thái.',
        details: e.toString(),
      );
    }
  }

  /// Save both mood preferences and mark onboarding complete (Story 6.3)
  ///
  /// Convenience method to perform both operations in a single write.
  Future<void> completeOnboarding(
    String uid,
    List<String> moods, {
    List<String> destinationIds = const [],
  }) async {
    try {
      await _usersCollection.doc(uid).set({
        'moodPreferences': moods,
        'destinationPreferences': destinationIds,
        'onboardingCompleted': true,
        'onboardingSkipped': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw AppException(
        code: AppException.FIRESTORE_ERROR,
        message: 'Không thể hoàn tất onboarding.',
        details: 'FirestoreException: ${e.code} - ${e.message}',
      );
    } catch (e) {
      throw AppException(
        code: AppException.UNKNOWN_ERROR,
        message: 'Đã xảy ra lỗi khi hoàn tất onboarding.',
        details: e.toString(),
      );
    }
  }

  /// Mark onboarding as skipped (Story 6.4)
  ///
  /// User chose to skip mood selection:
  /// - onboardingSkipped: true (for tracking)
  /// - onboardingCompleted: true (for router redirect logic)
  /// - moodPreferences: [] (empty = no filter applied)
  Future<void> markOnboardingSkipped(String uid) async {
    try {
      await _usersCollection.doc(uid).set({
        'onboardingSkipped': true,
        'onboardingCompleted': true,
        'moodPreferences': <String>[], // Empty = no personalization
        'destinationPreferences': <String>[],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw AppException(
        code: AppException.FIRESTORE_ERROR,
        message: 'Không thể bỏ qua onboarding.',
        details: 'FirestoreException: ${e.code} - ${e.message}',
      );
    } catch (e) {
      throw AppException(
        code: AppException.UNKNOWN_ERROR,
        message: 'Đã xảy ra lỗi khi bỏ qua onboarding.',
        details: e.toString(),
      );
    }
  }
}
