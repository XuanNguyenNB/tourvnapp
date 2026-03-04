# Error Handling in TourVN

This directory contains the centralized error handling system for TourVN using `AppException`.

## AppException Class

All errors in TourVN should be wrapped in `AppException` to provide:
- Consistent error codes
- User-friendly Vietnamese messages
- Technical details for debugging (without exposing to users)
- Integration with Riverpod AsyncValue

## Error Codes

### Firebase Errors
- `FIRESTORE_ERROR` - Database operation failed
- `AUTH_ERROR` - Authentication failed
- `NETWORK_ERROR` - No internet connection

### Resource Not Found
- `TRIP_NOT_FOUND` - Trip does not exist
- `DESTINATION_NOT_FOUND` - Destination does not exist
- `LOCATION_NOT_FOUND` - Location does not exist
- `REVIEW_NOT_FOUND` - Review does not exist

### Permission & Validation
- `VALIDATION_ERROR` - User input validation failed
- `PERMISSION_DENIED` - User lacks permission
- `AUTH_REQUIRED` - Authentication required

### Other
- `UNKNOWN_ERROR` - Unexpected error (fallback)

## Usage Patterns

### Firestore Error Handling

```dart
// In Repository layer
Future<Trip> getTrip(String tripId) async {
  try {
    final doc = await _firestore.collection('trips').doc(tripId).get();
    
    if (!doc.exists) {
      throw AppException(
        code: AppException.TRIP_NOT_FOUND,
        message: AppException.getMessageForCode(AppException.TRIP_NOT_FOUND),
        details: 'Trip ID: $tripId does not exist',
      );
    }
    
    return Trip.fromFirestore(doc);
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') {
      throw AppException(
        code: AppException.PERMISSION_DENIED,
        message: AppException.getMessageForCode(AppException.PERMISSION_DENIED),
        details: e.toString(),
      );
    }
    throw AppException(
      code: AppException.FIRESTORE_ERROR,
      message: AppException.getMessageForCode(AppException.FIRESTORE_ERROR),
      details: e.toString(),
    );
  } catch (e) {
    throw AppException(
      code: AppException.UNKNOWN_ERROR,
      message: AppException.getMessageForCode(AppException.UNKNOWN_ERROR),
      details: e.toString(),
    );
  }
}
```

### Firebase Auth Error Handling

```dart
// In Auth Repository
Future<User> signInWithGoogle() async {
  try {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw AppException(
        code: AppException.AUTH_ERROR,
        message: 'Đăng nhập bị hủy',
        details: 'User cancelled Google sign-in',
      );
    }
    
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    return userCredential.user!;
    
  } on FirebaseAuthException catch (e) {
    throw AppException(
      code: AppException.AUTH_ERROR,
      message: _getAuthErrorMessage(e.code),
      details: e.toString(),
    );
  } catch (e) {
    throw AppException(
      code: AppException.UNKNOWN_ERROR,
      message: AppException.getMessageForCode(AppException.UNKNOWN_ERROR),
      details: e.toString(),
    );
  }
}

String _getAuthErrorMessage(String code) {
  switch (code) {
    case 'user-disabled':
      return 'Tài khoản đã bị vô hiệu hóa.';
    case 'user-not-found':
      return 'Không tìm thấy tài khoản.';
    case 'network-request-failed':
      return 'Không có kết nối mạng.';
    default:
      return AppException.getMessageForCode(AppException.AUTH_ERROR);
  }
}
```

### Riverpod Integration

```dart
// Using AsyncNotifier with AppException
class TripsNotifier extends AsyncNotifier<List<Trip>> {
  @override
  Future<List<Trip>> build() async {
    try {
      final userId = ref.watch(authStateProvider).value?.uid;
      if (userId == null) {
        throw AppException(
          code: AppException.AUTH_REQUIRED,
          message: AppException.getMessageForCode(AppException.AUTH_REQUIRED),
        );
      }
      
      return await ref.read(tripRepositoryProvider).getTrips(userId);
    } on AppException {
      rethrow; // Already wrapped
    } catch (e) {
      throw AppException(
        code: AppException.UNKNOWN_ERROR,
        message: AppException.getMessageForCode(AppException.UNKNOWN_ERROR),
        details: e.toString(),
      );
    }
  }
  
  Future<void> createTrip(Trip trip) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(tripRepositoryProvider).createTrip(trip);
      return build(); // Refresh
    });
  }
}

// UI Error Display
class TripListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsProvider);
    
    return tripsAsync.when(
      data: (trips) => TripList(trips: trips),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) {
        final appError = error as AppException;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                appError.message, // User-friendly Vietnamese
                style: AppTypography.bodyMD,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(tripsProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

## Best Practices

### DO ✅
- Always wrap Firebase exceptions in AppException
- Use `AppException.getMessageForCode()` for consistent messages
- Include technical details in `details` field for debugging
- Rethrow AppException if already wrapped
- Use specific error codes for different scenarios

### DON'T ❌
- Don't throw generic `Exception()` - always use AppException
- Don't expose technical details to users
- Don't hardcode error messages - use `getMessageForCode()`
- Don't leave `print()` statements - use `details` field
- Don't catch AppException and wrap again

## Troubleshooting

### Error not showing Vietnamese message?
Make sure you're casting to AppException in UI:
```dart
error: (error, stack) {
  final appError = error as AppException;  // Cast first
  return Text(appError.message);
}
```

### Want to add new error code?
1. Add constant in `AppException` class
2. Add Vietnamese message in `getMessageForCode()` method
3. Document in this README

### Need custom message for specific error?
Pass custom message directly (don't use `getMessageForCode()`):
```dart
throw AppException(
  code: AppException.AUTH_ERROR,
  message: 'Tài khoản đã bị khóa do vi phạm chính sách',
  details: 'Custom auth error scenario',
);
```

## Testing

```dart
// Test AppException
test('AppException should format message correctly', () {
  final exception = AppException(
    code: AppException.TRIP_NOT_FOUND,
    message: App Exception.getMessageForCode(AppException.TRIP_NOT_FOUND),
    details: 'Test details',
  );
  
  expect(exception.code, AppException.TRIP_NOT_FOUND);
  expect(exception.message, 'Không tìm thấy chuyến đi.');
  expect(exception.toString(), contains('TRIP_NOT_FOUND'));
});
```
