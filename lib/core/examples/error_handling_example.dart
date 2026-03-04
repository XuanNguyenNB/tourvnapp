// ignore_for_file: unused_element, unused_local_variable

/// Example patterns for error handling with AppException in TourVN.
///
/// This file demonstrates best practices for handling errors across
/// Firebase services and integrating with Riverpod state management.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../exceptions/app_exception.dart';

// ==========================================
// FIRESTORE ERROR HANDLING EXAMPLES
// ==========================================

/// Example: Firestore read with error handling
class _FirestoreReadExample {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getDocument(String docId) async {
    try {
      final doc = await _firestore.collection('trips').doc(docId).get();

      // Check if document exists
      if (!doc.exists) {
        throw AppException(
          code: AppException.TRIP_NOT_FOUND,
          message: AppException.getMessageForCode(AppException.TRIP_NOT_FOUND),
          details: 'Document ID: $docId not found in trips collection',
        );
      }

      return doc.data()!;
    } on FirebaseException catch (e) {
      // Handle specific Firebase errors
      if (e.code == 'permission-denied') {
        throw AppException(
          code: AppException.PERMISSION_DENIED,
          message: AppException.getMessageForCode(
            AppException.PERMISSION_DENIED,
          ),
          details: 'User lacks permission to read trips/$docId: ${e.message}',
        );
      }

      // Generic Firestore error
      throw AppException(
        code: AppException.FIRESTORE_ERROR,
        message: AppException.getMessageForCode(AppException.FIRESTORE_ERROR),
        details: 'Firestore read failed: ${e.code} - ${e.message}',
      );
    } catch (e) {
      // Catch any other unexpected errors
      throw AppException(
        code: AppException.UNKNOWN_ERROR,
        message: AppException.getMessageForCode(AppException.UNKNOWN_ERROR),
        details: 'Unexpected error in getDocument: $e',
      );
    }
  }
}

/// Example: Firestore write with error handling
class _FirestoreWriteExample {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createTrip(Map<String, dynamic> tripData) async {
    try {
      await _firestore.collection('trips').add(tripData);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw AppException(
          code: AppException.PERMISSION_DENIED,
          message: AppException.getMessageForCode(
            AppException.PERMISSION_DENIED,
          ),
          details: 'User cannot create trips: ${e.message}',
        );
      }

      throw AppException(
        code: AppException.FIRESTORE_ERROR,
        message: AppException.getMessageForCode(AppException.FIRESTORE_ERROR),
        details: 'Failed to create trip: ${e.code} - ${e.message}',
      );
    } catch (e) {
      throw AppException(
        code: AppException.UNKNOWN_ERROR,
        message: AppException.getMessageForCode(AppException.UNKNOWN_ERROR),
        details: 'Unexpected error in createTrip: $e',
      );
    }
  }
}

// ==========================================
// FIREBASE AUTH ERROR HANDLING EXAMPLES
// ==========================================

/// Example: Firebase Auth with custom error messages
class _AuthErrorHandlingExample {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw AppException(
          code: AppException.AUTH_ERROR,
          message: 'Đăng nhập thất bại',
          details: 'User credential returned null',
        );
      }

      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      // Map Firebase auth codes to Vietnamese messages
      throw AppException(
        code: AppException.AUTH_ERROR,
        message: _getAuthErrorMessage(e.code),
        details: 'Auth error: ${e.code} - ${e.message}',
      );
    } catch (e) {
      throw AppException(
        code: AppException.UNKNOWN_ERROR,
        message: AppException.getMessageForCode(AppException.UNKNOWN_ERROR),
        details: 'Unexpected auth error: $e',
      );
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không đúng.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'email-already-in-use':
        return 'Email đã được sử dụng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu.';
      case 'network-request-failed':
        return 'Không có kết nối mạng.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      default:
        return AppException.getMessageForCode(AppException.AUTH_ERROR);
    }
  }
}

// ==========================================
// RIVERPOD INTEGRATION EXAMPLES
// ==========================================

/// Example: AsyncNotifier with AppException error handling
class _ExampleNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    try {
      // Simulate data loading
      final data = await _fetchData();
      return data;
    } on AppException {
      // Already wrapped - just rethrow
      rethrow;
    } catch (e) {
      // Wrap unexpected errors
      throw AppException(
        code: AppException.UNKNOWN_ERROR,
        message: AppException.getMessageForCode(AppException.UNKNOWN_ERROR),
        details: 'Error in _ExampleNotifier.build: $e',
      );
    }
  }

  Future<List<String>> _fetchData() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 100));
    return ['Item 1', 'Item 2', 'Item 3'];
  }

  /// Example: Action method with AsyncValue.guard()
  Future<void> addItem(String item) async {
    state = const AsyncValue.loading();

    // AsyncValue.guard automatically catches errors
    state = await AsyncValue.guard(() async {
      await _saveItem(item);
      return build(); // Refresh data
    });
  }

  Future<void> _saveItem(String item) async {
    // Simulate save operation
    await Future.delayed(const Duration(milliseconds: 100));

    // Example: throw AppException if validation fails
    if (item.isEmpty) {
      throw AppException(
        code: AppException.VALIDATION_ERROR,
        message: AppException.getMessageForCode(AppException.VALIDATION_ERROR),
        details: 'Item name cannot be empty',
      );
    }
  }
}

// Provider definition (example)
final _exampleProvider = AsyncNotifierProvider<_ExampleNotifier, List<String>>(
  () {
    return _ExampleNotifier();
  },
);

// ==========================================
// VALIDATION ERROR EXAMPLES
// ==========================================

/// Example: Input validation with AppException
class _ValidationExample {
  void validateTripName(String name) {
    if (name.trim().isEmpty) {
      throw AppException(
        code: AppException.VALIDATION_ERROR,
        message: 'Tên chuyến đi không được để trống',
        details: 'Trip name validation failed: empty string',
      );
    }

    if (name.length < 3) {
      throw AppException(
        code: AppException.VALIDATION_ERROR,
        message: 'Tên chuyến đi phải có ít nhất 3 ký tự',
        details:
            'Trip name validation failed: too short (length: ${name.length})',
      );
    }

    if (name.length > 100) {
      throw AppException(
        code: AppException.VALIDATION_ERROR,
        message: 'Tên chuyến đi không được quá 100 ký tự',
        details:
            'Trip name validation failed: too long (length: ${name.length})',
      );
    }
  }
}

// ==========================================
// COMBINED EXAMPLE: COMPLETE FLOW
// ==========================================

/// Example: Complete repository with comprehensive error handling
class _TripRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getTrip(String tripId) async {
    try {
      // Validate input
      if (tripId.isEmpty) {
        throw AppException(
          code: AppException.VALIDATION_ERROR,
          message: 'Trip ID không hợp lệ',
          details: 'Trip ID is empty',
        );
      }

      // Fetch from Firestore
      final doc = await _firestore.collection('trips').doc(tripId).get();

      // Check existence
      if (!doc.exists) {
        throw AppException(
          code: AppException.TRIP_NOT_FOUND,
          message: AppException.getMessageForCode(AppException.TRIP_NOT_FOUND),
          details: 'Trip document $tripId does not exist',
        );
      }

      return doc.data()!;
    } on AppException {
      // Already wrapped - rethrow
      rethrow;
    } on FirebaseException catch (e) {
      // Wrap Firebase errors
      if (e.code == 'permission-denied') {
        throw AppException(
          code: AppException.PERMISSION_DENIED,
          message: AppException.getMessageForCode(
            AppException.PERMISSION_DENIED,
          ),
          details: 'Permission denied for trip $tripId: ${e.message}',
        );
      }

      throw AppException(
        code: AppException.FIRESTORE_ERROR,
        message: AppException.getMessageForCode(AppException.FIRESTORE_ERROR),
        details:
            'Firestore error reading trip $tripId: ${e.code} - ${e.message}',
      );
    } catch (e) {
      // Wrap any other errors
      throw AppException(
        code: AppException.UNKNOWN_ERROR,
        message: AppException.getMessageForCode(AppException.UNKNOWN_ERROR),
        details: 'Unexpected error in getTrip($tripId): $e',
      );
    }
  }
}
