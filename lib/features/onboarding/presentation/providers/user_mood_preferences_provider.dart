import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/onboarding_service.dart';

/// Provides user's mood preferences from either local storage or Firestore.
///
/// **Priority Order:**
/// 1. Authenticated user with Firestore preferences → use Firestore data
/// 2. Anonymous user or authenticated user without Firestore preferences →
///    use local SharedPreferences
///
/// Returns empty list if user has not set preferences (skipped onboarding).
///
/// **Usage:**
/// ```dart
/// final moodsAsync = ref.watch(userMoodPreferencesProvider);
/// moodsAsync.when(
///   data: (moods) => filterContent(moods),
///   loading: () => showLoading(),
///   error: (e, st) => showError(),
/// );
/// ```
///
/// Story 6.5: Implement Personalized Feed Filtering
final userMoodPreferencesProvider = FutureProvider<List<String>>((ref) async {
  // Watch current user for reactive updates
  final user = ref.watch(currentUserProvider);

  // For authenticated users with mood preferences in Firestore
  if (user != null && !user.isAnonymous) {
    final moods = user.moodPreferences;
    if (moods != null && moods.isNotEmpty) {
      return moods;
    }
  }

  // For anonymous users or authenticated users without Firestore preferences
  // Read from local storage (SharedPreferences)
  try {
    final service = ref.read(onboardingServiceProvider);
    final localMoods = service.getMoodPreferencesLocally();
    return localMoods.map((m) => m.id).toList();
  } catch (_) {
    // If onboardingServiceProvider is not initialized, return empty list
    return <String>[];
  }
});
