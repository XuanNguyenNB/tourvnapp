import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tour_vn/features/onboarding/domain/entities/mood.dart';

/// Service for managing onboarding state and mood preferences locally.
/// Uses SharedPreferences for persistence across app restarts.
///
/// This service handles:
/// - Checking if onboarding has been completed
/// - Marking onboarding as complete
/// - Saving/loading mood preferences locally (for anonymous users)
///
/// Story 6.3: Implement Onboarding CTA & Navigation
class OnboardingService {
  /// SharedPreferences key for onboarding completion flag
  static const String _keyOnboardingCompleted = 'onboarding_completed';

  /// SharedPreferences key for mood preferences
  static const String _keyMoodPreferences = 'mood_preferences';

  /// SharedPreferences key for onboarding skipped flag
  /// Story 6.4: Implement Skip Onboarding
  static const String _keyOnboardingSkipped = 'onboarding_skipped';

  final SharedPreferences _prefs;

  /// Creates an OnboardingService with the given SharedPreferences instance.
  OnboardingService(this._prefs);

  /// Check if user has completed onboarding.
  ///
  /// Returns `true` if onboarding was previously completed, `false` otherwise.
  /// This is synchronous since SharedPreferences is already initialized.
  bool isOnboardingCompleted() {
    return _prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  /// Check if user has skipped onboarding.
  ///
  /// Returns `true` if user chose to skip, `false` otherwise.
  /// Story 6.4: Implement Skip Onboarding
  bool isOnboardingSkipped() {
    return _prefs.getBool(_keyOnboardingSkipped) ?? false;
  }

  /// Check if onboarding should be shown.
  ///
  /// Returns `false` if user has either completed or skipped onboarding.
  /// Story 6.4: Implement Skip Onboarding
  bool shouldShowOnboarding() {
    return !isOnboardingCompleted() && !isOnboardingSkipped();
  }

  /// Mark onboarding as complete.
  ///
  /// This persists the completion state so that the user won't see
  /// the onboarding screen again on subsequent app launches.
  Future<void> markOnboardingCompleted() async {
    await _prefs.setBool(_keyOnboardingCompleted, true);
  }

  /// Mark onboarding as skipped.
  ///
  /// User chose to skip mood selection, so mark both flags:
  /// - skipped = true (for tracking that user skipped)
  /// - completed = true (for router redirect logic)
  ///
  /// Story 6.4: Implement Skip Onboarding
  Future<void> markOnboardingSkipped() async {
    await _prefs.setBool(_keyOnboardingSkipped, true);
    await _prefs.setBool(_keyOnboardingCompleted, true);
  }

  /// Reset onboarding completion state.
  ///
  /// Useful for testing or if user wants to redo onboarding.
  Future<void> resetOnboarding() async {
    await _prefs.remove(_keyOnboardingCompleted);
    await _prefs.remove(_keyMoodPreferences);
    await _prefs.remove(_keyOnboardingSkipped);
  }

  /// Save mood preferences locally.
  ///
  /// Converts the Set of Mood enums to their string names for storage.
  /// This is used for anonymous users who don't have Firestore accounts.
  Future<void> saveMoodPreferencesLocally(Set<Mood> moods) async {
    final moodNames = moods.map((m) => m.name).toList();
    await _prefs.setStringList(_keyMoodPreferences, moodNames);
  }

  /// Get locally saved mood preferences.
  ///
  /// Returns an empty Set if no preferences were saved.
  /// Handles cases where saved mood names no longer exist (gracefully skips them).
  Set<Mood> getMoodPreferencesLocally() {
    final moodNames = _prefs.getStringList(_keyMoodPreferences) ?? [];
    final Set<Mood> result = {};

    for (final name in moodNames) {
      try {
        final mood = Mood.values.firstWhere((m) => m.name == name);
        result.add(mood);
      } catch (_) {
        // Mood name not found in enum, skip it (might be from old version)
      }
    }

    return result;
  }

  /// Get the list of mood preference names as strings.
  ///
  /// Useful for comparing with Firestore data or display purposes.
  List<String> getMoodPreferenceNames() {
    return _prefs.getStringList(_keyMoodPreferences) ?? [];
  }
}

/// Provider for OnboardingService.
///
/// This must be overridden in the ProviderScope with an actual instance
/// after SharedPreferences is initialized in main.dart.
///
/// Example:
/// ```dart
/// final prefs = await SharedPreferences.getInstance();
/// runApp(
///   ProviderScope(
///     overrides: [
///       onboardingServiceProvider.overrideWithValue(OnboardingService(prefs)),
///     ],
///     child: const MyApp(),
///   ),
/// );
/// ```
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  throw UnimplementedError(
    'onboardingServiceProvider must be overridden with a SharedPreferences instance. '
    'Initialize SharedPreferences in main() and override this provider.',
  );
});

/// FutureProvider to get SharedPreferences instance.
///
/// Alternative to manual initialization in main.dart.
/// Can be used with ref.watch() in async contexts.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

/// Computed provider: true nếu user chưa hoàn thành && chưa skip onboarding.
///
/// Dùng ở bất kỳ đâu cần check nhanh:
/// ```dart
/// final shouldShow = ref.watch(shouldShowOnboardingProvider);
/// if (shouldShow) context.push('/onboarding');
/// ```
final shouldShowOnboardingProvider = Provider<bool>((ref) {
  final service = ref.watch(onboardingServiceProvider);
  return service.shouldShowOnboarding();
});
