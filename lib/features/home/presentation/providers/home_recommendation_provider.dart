import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../destination/presentation/providers/destination_provider.dart';
import '../../../recommendation/data/repositories/user_event_repository.dart';
import '../../../recommendation/data/repositories/user_profile_repository.dart';
import '../../../recommendation/domain/entities/recommendation_item.dart';
import '../../../recommendation/domain/entities/user_profile.dart';
import '../../../recommendation/domain/services/recommendation_service.dart';
import '../../../onboarding/domain/mood_category_mapping.dart';
import '../../../../core/services/onboarding_service.dart';

/// Parameters for home recommendations.
class HomeRecParams {
  /// User GPS latitude (null if unavailable).
  final double? lat;

  /// User GPS longitude (null if unavailable).
  final double? lng;

  /// Category to boost (e.g. 'places' for check-in filter).
  final String? boostCategory;

  const HomeRecParams({this.lat, this.lng, this.boostCategory});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeRecParams &&
          lat == other.lat &&
          lng == other.lng &&
          boostCategory == other.boostCategory;

  @override
  int get hashCode => Object.hash(lat, lng, boostCategory);
}

/// Provider for personalized recommendations on the Home screen.
///
/// Accepts [HomeRecParams] with optional GPS position and category boost.
/// Flow:
/// 1. Fetch all locations from Firestore
/// 2. Load user profile (Firestore → local fallback)
/// 3. Load interaction events (if available)
/// 4. Run RecommendationService scoring (+ proximity + boost) + MMR
/// 5. Return top 10 recommendations
final homeRecommendationsProvider =
    FutureProvider.family<List<RecommendationItem>, HomeRecParams>((
      ref,
      params,
    ) async {
      final user = ref.watch(currentUserProvider);

      // 1. Load all locations
      final destRepo = ref.watch(destinationRepositoryProvider);
      final allLocations = await destRepo.getAllLocations();
      if (allLocations.isEmpty) return [];

      // 2. Load user profile: Firestore first, local fallback
      UserProfile? profile;
      Map<String, double> catInterests = {};
      Map<String, double> tagInterests = {};
      Set<String> interacted = {};

      if (user != null) {
        final profileRepo = ref.read(userProfileRepositoryProvider);
        final eventRepo = ref.read(userEventRepositoryProvider);

        // Try Firestore profile
        try {
          profile = await profileRepo.getProfile(user.uid);
        } catch (_) {
          // Profile unavailable from Firestore
        }

        // Try Firestore events
        try {
          catInterests = await eventRepo.computeCategoryInterests(user.uid);
          tagInterests = await eventRepo.computeTagInterests(user.uid);
          interacted = await eventRepo.getInteractedLocationIds(user.uid);
        } catch (_) {
          // Events unavailable — continue with empty data
        }
      }

      // 3. Local fallback: if no Firestore profile, build from SharedPreferences
      if (profile == null || !profile.hasPreferences) {
        profile = _buildProfileFromLocal(ref, user?.uid ?? 'anonymous');
      }

      // 4. Run recommendation algorithm with GPS + boost
      const service = RecommendationService();
      return service.recommend(
        candidates: allLocations,
        profile: profile,
        categoryInterests: catInterests,
        tagInterests: tagInterests,
        interactedLocationIds: interacted,
        userLat: params.lat,
        userLng: params.lng,
        boostCategory: params.boostCategory,
        topN: 10,
        diversify: true,
      );
    });

/// Build a UserProfile from local SharedPreferences onboarding data.
///
/// Used as fallback when Firestore profile is unavailable (anonymous users,
/// permission denied, offline, etc.).
UserProfile? _buildProfileFromLocal(Ref ref, String userId) {
  try {
    final service = ref.read(onboardingServiceProvider);

    // Get moods from local storage
    final localMoods = service.getMoodPreferencesLocally();
    if (localMoods.isEmpty) return null;

    // Convert moods → categories + tags using shared mapping
    final (categories, tags) = MoodCategoryMapping.resolve(localMoods);

    // Get destination preferences from local storage
    final destIds = service.getDestinationPreferencesLocally();

    return UserProfile(
      userId: userId,
      preferredCategoryIds: categories,
      preferredTags: tags,
      preferredDestinationIds: destIds,
      updatedAt: DateTime.now(),
    );
  } catch (_) {
    // onboardingServiceProvider not initialized
    return null;
  }
}
