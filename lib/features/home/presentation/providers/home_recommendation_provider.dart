import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../destination/presentation/providers/destination_provider.dart';
import '../../../recommendation/data/repositories/user_event_repository.dart';
import '../../../recommendation/data/repositories/user_profile_repository.dart';
import '../../../recommendation/domain/entities/recommendation_item.dart';
import '../../../recommendation/domain/entities/user_profile.dart';
import '../../../recommendation/domain/services/recommendation_service.dart';

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
/// 2. Load user profile + interaction events
/// 3. Run RecommendationService scoring (+ proximity + boost) + MMR
/// 4. Return top 10 recommendations
final homeRecommendationsProvider =
    FutureProvider.family<List<RecommendationItem>, HomeRecParams>((
      ref,
      params,
    ) async {
      final user = FirebaseAuth.instance.currentUser;

      // 1. Load all locations
      final destRepo = ref.watch(destinationRepositoryProvider);
      final allLocations = await destRepo.getAllLocations();
      if (allLocations.isEmpty) return [];

      // 2. Load user data (profile, events) for ALL users including anonymous
      UserProfile? profile;
      Map<String, double> catInterests = {};
      Map<String, double> tagInterests = {};
      Set<String> interacted = {};

      if (user != null) {
        final profileRepo = ref.read(userProfileRepositoryProvider);
        final eventRepo = ref.read(userEventRepositoryProvider);

        // Wrap in try-catch: anonymous users may be denied by Firestore rules
        try {
          profile = await profileRepo.getProfile(user.uid);
        } catch (_) {
          // Profile unavailable — will use popularity-based fallback
        }
        try {
          catInterests = await eventRepo.computeCategoryInterests(user.uid);
          tagInterests = await eventRepo.computeTagInterests(user.uid);
          interacted = await eventRepo.getInteractedLocationIds(user.uid);
        } catch (_) {
          // Events unavailable — continue with empty data
        }
      }

      // 3. Run recommendation algorithm with GPS + boost
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
