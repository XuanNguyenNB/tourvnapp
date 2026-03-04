import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/core/services/onboarding_service.dart';
import 'package:tour_vn/features/auth/presentation/providers/auth_provider.dart';
import 'package:tour_vn/features/onboarding/domain/entities/mood.dart';
import 'package:tour_vn/features/recommendation/data/repositories/user_profile_repository.dart';
import 'package:tour_vn/features/recommendation/domain/entities/user_profile.dart';

/// Mood → Category/Tags mapping for recommendation cold-start.
///
/// When a user selects moods during onboarding, we convert them
/// into `preferredCategoryIds` and `preferredTags` to seed
/// the recommendation engine's UserProfile.
const Map<Mood, List<String>> _moodToCategories = {
  Mood.healing: ['places', 'stay'],
  Mood.adventure: ['places'],
  Mood.foodie: ['food'],
  Mood.photography: ['places'],
  Mood.party: ['places', 'food'],
};

const Map<Mood, List<String>> _moodToTags = {
  Mood.healing: ['chill', 'resort', 'hidden-gem'],
  Mood.adventure: ['adventure', 'trekking', 'outdoor'],
  Mood.foodie: ['local-favorite', 'street-food'],
  Mood.photography: ['instagram-worthy', 'check-in'],
  Mood.party: ['nightlife', 'vui chơi'],
};

/// State for the onboarding completion process.
///
/// Tracks the loading and completion status during the
/// save operation when user taps the CTA button.
class OnboardingCompletionState {
  /// Whether the save operation is in progress
  final bool isLoading;

  /// Whether onboarding was successfully completed
  final bool isCompleted;

  /// Error message if save operation failed
  final String? error;

  const OnboardingCompletionState({
    this.isLoading = false,
    this.isCompleted = false,
    this.error,
  });

  /// Creates a copy with updated fields
  OnboardingCompletionState copyWith({
    bool? isLoading,
    bool? isCompleted,
    String? error,
  }) {
    return OnboardingCompletionState(
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error,
    );
  }
}

/// Notifier for managing the onboarding completion flow.
///
/// Handles saving mood preferences and marking onboarding complete
/// for both anonymous users (local storage) and authenticated users (Firestore).
///
/// Also seeds the recommendation engine's UserProfile with
/// categories and tags derived from the selected moods (cold-start).
///
/// Story 6.3: Implement Onboarding CTA & Navigation
class OnboardingNotifier extends Notifier<OnboardingCompletionState> {
  @override
  OnboardingCompletionState build() => const OnboardingCompletionState();

  /// Complete the onboarding flow.
  ///
  /// 1. Saves mood preferences locally
  /// 2. Marks onboarding as complete
  /// 3. Saves to Firestore (authenticated users)
  /// 4. Creates UserProfile with mood-derived categories/tags (cold-start)
  /// 5. Returns true on success
  Future<bool> completeOnboarding(
    Set<Mood> moods, {
    List<String> selectedDestinationIds = const [],
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final currentUser = ref.read(currentUserProvider);
      final onboardingService = ref.read(onboardingServiceProvider);

      // Convert moods to list of names
      final moodNames = moods.map((m) => m.name).toList();

      // Always save locally first (for quick access on next launch)
      await onboardingService.saveMoodPreferencesLocally(moods);
      await onboardingService.markOnboardingCompleted();

      // If user is authenticated (not anonymous), also save to Firestore
      if (currentUser != null && !currentUser.isAnonymous) {
        try {
          final userRepo = ref.read(userRepositoryProvider);
          await userRepo.completeOnboarding(currentUser.uid, moodNames);
        } catch (e) {
          // Log error but don't fail - local save was successful
        }
      }

      // Seed recommendation UserProfile for ALL users (including anonymous)
      if (currentUser != null) {
        try {
          await _seedUserProfile(
            currentUser.uid,
            moods,
            destinationIds: selectedDestinationIds,
          );
        } catch (e) {
          // Non-critical: recommendation profile will be created later
        }
      }

      state = state.copyWith(isLoading: false, isCompleted: true);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Đã xảy ra lỗi. Vui lòng thử lại.',
      );
      return false;
    }
  }

  /// Seed the recommendation UserProfile from selected moods.
  ///
  /// Maps each mood to categories and tags, deduplicates, and saves
  /// to Firestore as the initial UserProfile for the recommendation engine.
  Future<void> _seedUserProfile(
    String userId,
    Set<Mood> moods, {
    List<String> destinationIds = const [],
  }) async {
    final categories = <String>{};
    final tags = <String>{};

    for (final mood in moods) {
      categories.addAll(_moodToCategories[mood] ?? []);
      tags.addAll(_moodToTags[mood] ?? []);
    }

    final profile = UserProfile(
      userId: userId,
      preferredCategoryIds: categories.toList(),
      preferredTags: tags.toList(),
      preferredDestinationIds: destinationIds,
      updatedAt: DateTime.now(),
    );

    final profileRepo = ref.read(userProfileRepositoryProvider);
    await profileRepo.saveProfile(profile);
  }

  /// Skip the onboarding flow without setting preferences.
  ///
  /// Story 6.4: Implement Skip Onboarding
  /// 1. Marks onboarding as skipped (and completed for router logic)
  /// 2. Does NOT save any mood preferences (empty list = no filter)
  /// 3. Returns true on success
  ///
  /// For anonymous users: saves locally via OnboardingService
  /// For authenticated users: also saves to Firestore via UserRepository
  Future<bool> skipOnboarding() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final currentUser = ref.read(currentUserProvider);
      final onboardingService = ref.read(onboardingServiceProvider);

      // Always mark skipped locally first (for quick access on next launch)
      await onboardingService.markOnboardingSkipped();

      // If user is authenticated (not anonymous), also save to Firestore
      if (currentUser != null && !currentUser.isAnonymous) {
        try {
          final userRepo = ref.read(userRepositoryProvider);
          await userRepo.markOnboardingSkipped(currentUser.uid);
        } catch (e) {
          // Log error but don't fail - local save was successful
          // User preferences are still saved locally
          // Firestore will sync next time
        }
      }

      state = state.copyWith(isLoading: false, isCompleted: true);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Đã xảy ra lỗi. Vui lòng thử lại.',
      );
      return false;
    }
  }

  /// Reset the state (for testing or retry)
  void reset() {
    state = const OnboardingCompletionState();
  }
}

/// Provider for OnboardingNotifier.
///
/// Usage:
/// ```dart
/// // Watch state
/// final onboardingState = ref.watch(onboardingNotifierProvider);
///
/// // Complete onboarding
/// final success = await ref.read(onboardingNotifierProvider.notifier)
///     .completeOnboarding(selectedMoods);
/// ```
final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingCompletionState>(() {
      return OnboardingNotifier();
    });
