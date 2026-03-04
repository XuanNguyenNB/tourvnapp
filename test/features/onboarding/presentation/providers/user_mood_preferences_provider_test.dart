import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tour_vn/core/services/onboarding_service.dart';
import 'package:tour_vn/features/auth/domain/entities/user.dart';
import 'package:tour_vn/features/auth/presentation/providers/auth_provider.dart';
import 'package:tour_vn/features/onboarding/domain/entities/mood.dart';
import 'package:tour_vn/features/onboarding/presentation/providers/user_mood_preferences_provider.dart';

/// Mock classes
class MockOnboardingService extends Mock implements OnboardingService {}

/// Tests for UserMoodPreferencesProvider
///
/// Story 6.5: Implement Personalized Feed Filtering
void main() {
  group('UserMoodPreferencesProvider', () {
    late MockOnboardingService mockOnboardingService;

    setUp(() {
      mockOnboardingService = MockOnboardingService();
    });

    test('returns Firestore moods for authenticated user (AC #5)', () async {
      // Setup: Authenticated user with Firestore preferences
      const user = User(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: null,
        isAnonymous: false,
        moodPreferences: ['healing', 'photography'],
        onboardingCompleted: true,
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(user),
          onboardingServiceProvider.overrideWithValue(mockOnboardingService),
        ],
      );
      addTearDown(container.dispose);

      // Get mood preferences
      final result = await container.read(userMoodPreferencesProvider.future);

      // Assert: Returns Firestore moods
      expect(result, ['healing', 'photography']);
      // OnboardingService should NOT be called
      verifyNever(() => mockOnboardingService.getMoodPreferencesLocally());
    });

    test('returns local moods for anonymous user (AC #4)', () async {
      // Setup: Anonymous user with local preferences
      const user = User(
        uid: 'anon-uid',
        email: null,
        displayName: null,
        photoUrl: null,
        isAnonymous: true,
      );

      when(
        () => mockOnboardingService.getMoodPreferencesLocally(),
      ).thenReturn({Mood.adventure, Mood.foodie});

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(user),
          onboardingServiceProvider.overrideWithValue(mockOnboardingService),
        ],
      );
      addTearDown(container.dispose);

      // Get mood preferences
      final result = await container.read(userMoodPreferencesProvider.future);

      // Assert: Returns local moods
      expect(result, containsAll(['adventure', 'foodie']));
      verify(() => mockOnboardingService.getMoodPreferencesLocally()).called(1);
    });

    test('returns empty list when user skipped onboarding (AC #3)', () async {
      // Setup: User who skipped onboarding (no moods)
      const user = User(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: null,
        isAnonymous: false,
        moodPreferences: null, // Skipped onboarding - no preferences set
        onboardingCompleted: true,
      );

      when(
        () => mockOnboardingService.getMoodPreferencesLocally(),
      ).thenReturn({});

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(user),
          onboardingServiceProvider.overrideWithValue(mockOnboardingService),
        ],
      );
      addTearDown(container.dispose);

      // Get mood preferences
      final result = await container.read(userMoodPreferencesProvider.future);

      // Assert: Returns empty list
      expect(result, isEmpty);
    });

    test('falls back to local moods when Firestore moods are empty', () async {
      // Setup: Authenticated user without Firestore preferences
      const user = User(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: null,
        isAnonymous: false,
        moodPreferences: [], // Empty Firestore moods
      );

      when(
        () => mockOnboardingService.getMoodPreferencesLocally(),
      ).thenReturn({Mood.healing});

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(user),
          onboardingServiceProvider.overrideWithValue(mockOnboardingService),
        ],
      );
      addTearDown(container.dispose);

      // Get mood preferences
      final result = await container.read(userMoodPreferencesProvider.future);

      // Assert: Falls back to local moods
      expect(result, ['healing']);
      verify(() => mockOnboardingService.getMoodPreferencesLocally()).called(1);
    });

    test('returns empty list when no user is logged in', () async {
      // Setup: No user logged in
      when(
        () => mockOnboardingService.getMoodPreferencesLocally(),
      ).thenReturn({});

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(null),
          onboardingServiceProvider.overrideWithValue(mockOnboardingService),
        ],
      );
      addTearDown(container.dispose);

      // Get mood preferences
      final result = await container.read(userMoodPreferencesProvider.future);

      // Assert: Returns empty list
      expect(result, isEmpty);
    });

    test('handles onboardingServiceProvider error gracefully', () async {
      // Setup: OnboardingService throws error
      const user = User(
        uid: 'anon-uid',
        email: null,
        displayName: null,
        photoUrl: null,
        isAnonymous: true,
      );

      when(
        () => mockOnboardingService.getMoodPreferencesLocally(),
      ).thenThrow(Exception('SharedPreferences error'));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(user),
          onboardingServiceProvider.overrideWithValue(mockOnboardingService),
        ],
      );
      addTearDown(container.dispose);

      // Get mood preferences - should not throw
      final result = await container.read(userMoodPreferencesProvider.future);

      // Assert: Returns empty list on error
      expect(result, isEmpty);
    });
  });
}
