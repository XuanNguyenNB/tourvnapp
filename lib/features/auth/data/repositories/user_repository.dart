import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tour_vn/core/exceptions/app_exception.dart';
import 'package:tour_vn/features/auth/domain/entities/user.dart';

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
  Future<void> markOnboardingCompleted(String uid) async {
    try {
      await _usersCollection.doc(uid).set({
        'onboardingCompleted': true,
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
  Future<void> completeOnboarding(String uid, List<String> moods) async {
    try {
      await _usersCollection.doc(uid).set({
        'moodPreferences': moods,
        'onboardingCompleted': true,
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
