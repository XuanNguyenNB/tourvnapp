import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:tour_vn/core/exceptions/app_exception.dart';
import 'package:tour_vn/features/auth/domain/entities/user.dart';

/// Repository for Firebase Authentication operations
/// Handles anonymous sign-in, Google OAuth, and auth state management
class AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// Stores anonymous UID when user signs in with existing Google/Facebook account
  /// Used by TripMigrationService to migrate trips from anonymous to authenticated user
  String? _pendingMigrationFromAnonymousUid;

  /// Cached trips from anonymous user (fetched before sign-in)
  /// Used when `credential-already-in-use` to preserve trip data
  List<Map<String, dynamic>>? _cachedAnonymousTrips;

  AuthRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  /// Get and clear the pending migration anonymous UID
  /// Returns the anonymous UID if there's a pending migration, null otherwise
  /// Calling this method clears the pending migration state
  String? consumePendingMigrationUid() {
    final uid = _pendingMigrationFromAnonymousUid;
    _pendingMigrationFromAnonymousUid = null;
    return uid;
  }

  /// Get and clear the cached anonymous trips
  /// Returns the trips if there are any, null otherwise
  List<Map<String, dynamic>>? consumeCachedAnonymousTrips() {
    final trips = _cachedAnonymousTrips;
    _cachedAnonymousTrips = null;
    return trips;
  }

  /// Stream of auth state changes
  /// Emits User when signed in, null when signed out
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null ? User.fromFirebaseUser(firebaseUser) : null;
    });
  }

  /// Get current user synchronously
  User? getCurrentUser() {
    final firebaseUser = _firebaseAuth.currentUser;
    return firebaseUser != null ? User.fromFirebaseUser(firebaseUser) : null;
  }

  /// Sign in anonymously
  /// Returns User entity on success
  /// Throws AppException on failure
  Future<User> signInAnonymously() async {
    try {
      final userCredential = await _firebaseAuth.signInAnonymously();
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw AppException(
          code: AppException.AUTH_ERROR,
          message: 'Không thể đăng nhập ẩn danh. Vui lòng thử lại.',
          details: 'FirebaseAuth returned null user after signInAnonymously',
        );
      }

      return User.fromFirebaseUser(firebaseUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AppException(
        code: AppException.AUTH_ERROR,
        message: 'Lỗi xác thực: ${e.message ?? "Không rõ lỗi"}',
        details: 'FirebaseAuthException: ${e.code} - ${e.message}',
      );
    } catch (e) {
      throw AppException(
        code: AppException.UNKNOWN_ERROR,
        message: 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.',
        details: e.toString(),
      );
    }
  }

  /// Sign in with Google OAuth
  /// If user is anonymous, attempts to link accounts
  /// Returns User entity on success
  /// Throws AppException on failure
  Future<User> signInWithGoogle() async {
    try {
      final currentUser = _firebaseAuth.currentUser;

      // Trigger the Google Sign-In flow
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw AppException(
          code: AppException.AUTH_CANCELLED,
          message: 'Đăng nhập bị hủy bởi người dùng.',
        );
      }

      // Obtain the auth details
      final googleAuth = await googleUser.authentication;

      // Create Firebase credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      firebase_auth.UserCredential userCredential;

      // If user is anonymous, try to link accounts
      if (currentUser != null && currentUser.isAnonymous) {
        final anonymousUid = currentUser.uid; // Save for potential migration
        try {
          userCredential = await currentUser.linkWithCredential(credential);
        } on firebase_auth.FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // Google account already linked to another user
            // First, fetch trips from anonymous user BEFORE signing out
            try {
              final tripsSnapshot = await cloud_firestore
                  .FirebaseFirestore
                  .instance
                  .collection('users')
                  .doc(anonymousUid)
                  .collection('trips')
                  .get();

              if (tripsSnapshot.docs.isNotEmpty) {
                _cachedAnonymousTrips = tripsSnapshot.docs
                    .map((doc) => doc.data())
                    .toList();
              }
            } catch (_) {
              // Ignore errors - we'll try to migrate anyway
            }

            // Now sign in with Google (this abandons anonymous account)
            userCredential = await _firebaseAuth.signInWithCredential(
              credential,
            );
            // Store anonymous UID for trip migration
            _pendingMigrationFromAnonymousUid = anonymousUid;
          } else {
            rethrow;
          }
        }
      } else {
        // Normal sign-in (not anonymous)
        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw AppException(
          code: AppException.AUTH_ERROR,
          message: 'Không thể đăng nhập với Google. Vui lòng thử lại.',
          details: 'Firebase returned null user after Google sign-in',
        );
      }

      return User.fromFirebaseUser(firebaseUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AppException(
        code: AppException.AUTH_ERROR,
        message: _getGoogleAuthErrorMessage(e.code),
        details: 'FirebaseAuthException: ${e.code} - ${e.message}',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        code: AppException.UNKNOWN_ERROR,
        message: 'Đã xảy ra lỗi khi đăng nhập với Google. Vui lòng thử lại.',
        details: e.toString(),
      );
    }
  }

  /// Sign out from all auth providers (Google, Firebase)
  Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();
      // Sign out from Firebase
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AppException(
        code: AppException.AUTH_ERROR,
        message: 'Không thể đăng xuất. Vui lòng thử lại.',
        details: e.toString(),
      );
    }
  }

  /// Sign in with Email and Password
  /// If user is anonymous, attempts to link accounts
  /// Returns User entity on success
  /// Throws AppException on failure
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      firebase_auth.UserCredential userCredential;

      // If user is anonymous, try to link accounts
      if (currentUser != null && currentUser.isAnonymous) {
        final anonymousUid = currentUser.uid; // Save for potential migration
        try {
          userCredential = await currentUser.linkWithCredential(credential);
        } on firebase_auth.FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            // Email already linked to another user
            // First, fetch trips from anonymous user BEFORE signing out
            try {
              final tripsSnapshot = await cloud_firestore
                  .FirebaseFirestore
                  .instance
                  .collection('users')
                  .doc(anonymousUid)
                  .collection('trips')
                  .get();

              if (tripsSnapshot.docs.isNotEmpty) {
                _cachedAnonymousTrips = tripsSnapshot.docs
                    .map((doc) => doc.data())
                    .toList();
              }
            } catch (_) {
              // Ignore errors - we'll try migration anyway
            }

            // Now sign in with Email (this abandons anonymous account)
            userCredential = await _firebaseAuth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            // Store anonymous UID for trip migration
            _pendingMigrationFromAnonymousUid = anonymousUid;
          } else {
            rethrow;
          }
        }
      } else {
        // Normal sign-in (not anonymous)
        userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw AppException(
          code: AppException.AUTH_ERROR,
          message: 'Không thể đăng nhập. Vui lòng thử lại.',
          details: 'Firebase returned null user after Email sign-in',
        );
      }

      return User.fromFirebaseUser(firebaseUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AppException(
        code: AppException.AUTH_ERROR,
        message: _getEmailAuthErrorMessage(e.code),
        details: 'FirebaseAuthException: ${e.code} - ${e.message}',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        code: AppException.UNKNOWN_ERROR,
        message: 'Đã xảy ra lỗi khi đăng nhập. Vui lòng thử lại.',
        details: e.toString(),
      );
    }
  }

  /// Register with Email and Password
  /// Returns User entity on success
  /// Throws AppException on failure
  Future<User> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      firebase_auth.UserCredential userCredential;

      // If user is anonymous, try to link accounts instead of creating new
      if (currentUser != null && currentUser.isAnonymous) {
        final credential = firebase_auth.EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        userCredential = await currentUser.linkWithCredential(credential);

        // Update display name for the linked user
        await userCredential.user?.updateDisplayName(displayName);
      } else {
        // Normal registration
        userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Update display name for the new user
        await userCredential.user?.updateDisplayName(displayName);
      }

      // Reload user to get updated display name
      await userCredential.user?.reload();
      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        throw AppException(
          code: AppException.AUTH_ERROR,
          message: 'Không thể đăng ký tài khoản. Vui lòng thử lại.',
          details: 'Firebase returned null user after Email registration',
        );
      }

      return User.fromFirebaseUser(firebaseUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AppException(
        code: AppException.AUTH_ERROR,
        message: _getEmailAuthErrorMessage(e.code),
        details: 'FirebaseAuthException: ${e.code} - ${e.message}',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        code: AppException.UNKNOWN_ERROR,
        message: 'Đã xảy ra lỗi khi đăng ký. Vui lòng thử lại.',
        details: e.toString(),
      );
    }
  }

  /// Check if current user is anonymous
  bool get isAnonymous {
    return _firebaseAuth.currentUser?.isAnonymous ?? false;
  }

  /// Check if user is signed in (anonymous or authenticated)
  bool get isSignedIn {
    return _firebaseAuth.currentUser != null;
  }

  /// Get user-friendly Vietnamese error message for Firebase Auth error codes
  String _getGoogleAuthErrorMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Tài khoản này đã được đăng ký với phương thức khác.';
      case 'invalid-credential':
        return 'Thông tin đăng nhập không hợp lệ.';
      case 'operation-not-allowed':
        return 'Đăng nhập với Google chưa được kích hoạt.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
      default:
        return 'Đã xảy ra lỗi đăng nhập. Vui lòng thử lại.';
    }
  }

  /// Get user-friendly Vietnamese error message for Email Auth error codes
  String _getEmailAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email này đã được sử dụng bởi một tài khoản khác.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'operation-not-allowed':
        return 'Đăng nhập bằng Email/Mật khẩu chưa được kích hoạt.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (phải có ít nhất 6 ký tự).';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'user-not-found':
        return 'Không tìm thấy người dùng với email này.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác.';
      case 'invalid-credential':
        return 'Thông tin đăng nhập không chính xác.';
      default:
        return 'Lỗi xác thực. Vui lòng thử lại sau.';
    }
  }
}
