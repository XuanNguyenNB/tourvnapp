import 'entities/mood.dart';

/// Shared mapping from Mood enums to recommendation categories and tags.
///
/// Used by both:
/// - `OnboardingNotifier` to seed UserProfile on Firestore
/// - `homeRecommendationsProvider` to build local fallback profile
///
/// Ensures consistent mood→preference mapping across the app.
class MoodCategoryMapping {
  MoodCategoryMapping._();

  /// Maps each mood to relevant location categories.
  static const Map<Mood, List<String>> moodToCategories = {
    Mood.healing: ['places', 'stay'],
    Mood.foodie: ['food'],
    Mood.photography: ['places'],
    Mood.party: ['places', 'food'],
  };

  /// Maps each mood to relevant location tags.
  static const Map<Mood, List<String>> moodToTags = {
    Mood.healing: ['chill', 'resort', 'hidden-gem'],
    Mood.foodie: ['local-favorite', 'street-food'],
    Mood.photography: ['instagram-worthy', 'check-in'],
    Mood.party: ['nightlife', 'vui chơi'],
  };

  /// Resolve a set of moods into deduplicated category IDs and tags.
  ///
  /// Returns `(categoryIds, tags)`.
  static (List<String>, List<String>) resolve(Set<Mood> moods) {
    final categories = <String>{};
    final tags = <String>{};

    for (final mood in moods) {
      categories.addAll(moodToCategories[mood] ?? []);
      tags.addAll(moodToTags[mood] ?? []);
    }

    return (categories.toList(), tags.toList());
  }
}
