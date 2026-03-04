import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/features/auth/data/repositories/auth_repository.dart';
import 'package:tour_vn/features/auth/data/repositories/user_repository.dart';
import 'package:tour_vn/features/auth/domain/entities/user.dart';
import 'package:tour_vn/features/trip/domain/services/trip_migration_service.dart';

/// Provider for AuthRepository instance
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider for UserRepository instance
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Stream provider for auth state changes
/// Emits User when signed in, null when signed out
final authStateProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

/// Provider for current user (synchronous access)
/// Returns User if signed in, null otherwise
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.asData?.value;
});

/// Provider to check if current user is anonymous
final isAnonymousProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isAnonymous ?? false;
});

/// Provider to check if user is signed in
final isSignedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Auth Notifier for sign-in/sign-out actions
/// Handles async operations with loading/success/error states
///
/// Usage:
/// ```dart
/// // In widget
/// final authState = ref.watch(authNotifierProvider);
///
/// // Trigger sign-in
/// ref.read(authNotifierProvider.notifier).signInWithGoogle();
/// ```
class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No initial async work needed
  }

  /// Sign in with Google OAuth
  /// Handles account linking from anonymous automatically
  /// Creates/updates user document in Firestore after successful sign-in
  /// Migrates trips if switching from anonymous to existing Google account
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      // Sign in with Google (handles account linking automatically)
      final user = await authRepo.signInWithGoogle();

      // Check if we need to migrate trips from an anonymous account
      final pendingMigrationUid = authRepo.consumePendingMigrationUid();
      final cachedTrips = authRepo.consumeCachedAnonymousTrips();

      if (pendingMigrationUid != null && pendingMigrationUid != user.uid) {
        final migrationService = TripMigrationService();

        if (cachedTrips != null && cachedTrips.isNotEmpty) {
          // Use cached trips (preferred - no permission issues)
          await migrationService.migrateTripsFromCache(
            toUserId: user.uid,
            tripDataList: cachedTrips,
          );
        } else {
          // Fallback to direct migration (may fail with permission-denied)
          await migrationService.migrateTrips(
            fromUserId: pendingMigrationUid,
            toUserId: user.uid,
          );
        }
      }

      // Create/update user document in Firestore
      await userRepo.createOrUpdateUser(user);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Sign in with Email and Password
  /// Handles account linking from anonymous automatically
  /// Creates/updates user document in Firestore after successful sign-in
  /// Migrates trips if switching from anonymous to existing Email account
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      final user = await authRepo.signInWithEmailAndPassword(email, password);

      // Check if we need to migrate trips from an anonymous account
      final pendingMigrationUid = authRepo.consumePendingMigrationUid();
      final cachedTrips = authRepo.consumeCachedAnonymousTrips();

      if (pendingMigrationUid != null && pendingMigrationUid != user.uid) {
        final migrationService = TripMigrationService();

        if (cachedTrips != null && cachedTrips.isNotEmpty) {
          await migrationService.migrateTripsFromCache(
            toUserId: user.uid,
            tripDataList: cachedTrips,
          );
        } else {
          await migrationService.migrateTrips(
            fromUserId: pendingMigrationUid,
            toUserId: user.uid,
          );
        }
      }

      // Create/update user document in Firestore
      await userRepo.createOrUpdateUser(user);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Register with Email and Password
  /// Handles account linking from anonymous automatically (via linkWithCredential)
  /// Creates user document in Firestore after successful registration
  Future<void> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      final user = await authRepo.registerWithEmailAndPassword(
        email,
        password,
        displayName,
      );

      // If we linked from an anonymous account, the UID doesn't change,
      // but we still want to update the user doc with the new email/displayName
      await userRepo.createOrUpdateUser(user);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Sign out from Google and Firebase
  Future<void> signOut() async {
    state = const AsyncValue.loading();

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for AuthNotifier
/// Use this to trigger sign-in/sign-out actions
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(() {
  return AuthNotifier();
});
