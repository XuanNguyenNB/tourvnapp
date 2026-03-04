import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/user_profile_repository.dart';
import '../../data/repositories/user_event_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/recommendation_item.dart';
import '../../domain/entities/user_interaction_event.dart';
import '../../domain/services/recommendation_service.dart';
import '../../../destination/presentation/providers/location_provider.dart';

// ──── User Profile Providers ────

/// Stream provider for current user's profile.
/// Returns null if user is not logged in or profile doesn't exist.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);
  final repo = ref.read(userProfileRepositoryProvider);
  return repo.watchProfile(user.uid);
});

// ──── Recommendation Provider ────

/// FutureProvider returning personalized recommendations for a destination.
///
/// Fetches user profile, interaction history, and candidates,
/// then runs the scoring algorithm.
final recommendedLocationsProvider =
    FutureProvider.family<List<RecommendationItem>, String>((
      ref,
      destinationId,
    ) async {
      final user = FirebaseAuth.instance.currentUser;

      // 1. Load all candidate locations for this destination
      final allLocations = await ref.read(
        locationsForDestinationProvider(destinationId).future,
      );

      if (allLocations.isEmpty) return [];

      // 2. Load user data (profile, events) — gracefully handle no user
      UserProfile? profile;
      Map<String, double> catInterests = {};
      Map<String, double> tagInterests = {};
      Set<String> interacted = {};

      if (user != null && !user.isAnonymous) {
        final profileRepo = ref.read(userProfileRepositoryProvider);
        final eventRepo = ref.read(userEventRepositoryProvider);

        profile = await profileRepo.getProfile(user.uid);
        catInterests = await eventRepo.computeCategoryInterests(user.uid);
        tagInterests = await eventRepo.computeTagInterests(user.uid);
        interacted = await eventRepo.getInteractedLocationIds(user.uid);
      }

      // 3. Run recommendation algorithm
      const service = RecommendationService();
      return service.recommend(
        candidates: allLocations,
        profile: profile,
        categoryInterests: catInterests,
        tagInterests: tagInterests,
        interactedLocationIds: interacted,
        topN: 10,
        diversify: true,
      );
    });

// ──── Event Logging Helpers ────

/// Helper to log a user interaction event from widgets.
///
/// Can be called from any ConsumerWidget / ConsumerStatefulWidget.
/// Example:
/// ```dart
/// logUserEvent(ref, locationId: 'abc', destinationId: 'da-nang',
///     type: InteractionType.save, locationCategory: 'food');
/// ```
Future<void> logUserEvent(
  WidgetRef ref, {
  required String locationId,
  required String destinationId,
  required InteractionType type,
  String? locationCategory,
  List<String> locationTags = const [],
  int? ratingValue,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.isAnonymous) return; // Skip for anonymous users

  final repo = ref.read(userEventRepositoryProvider);
  await repo.logEvent(
    userId: user.uid,
    locationId: locationId,
    destinationId: destinationId,
    type: type,
    locationCategory: locationCategory,
    locationTags: locationTags,
    ratingValue: ratingValue,
  );
}

/// Helper to log a user interaction event from providers/notifiers.
///
/// Same as [logUserEvent] but accepts [Ref] for use inside
/// Riverpod providers, notifiers, or other non-widget contexts.
Future<void> logUserEventFromProvider(
  Ref ref, {
  required String locationId,
  required String destinationId,
  required InteractionType type,
  String? locationCategory,
  List<String> locationTags = const [],
  int? ratingValue,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.isAnonymous) return;

  final repo = ref.read(userEventRepositoryProvider);
  await repo.logEvent(
    userId: user.uid,
    locationId: locationId,
    destinationId: destinationId,
    type: type,
    locationCategory: locationCategory,
    locationTags: locationTags,
    ratingValue: ratingValue,
  );
}
