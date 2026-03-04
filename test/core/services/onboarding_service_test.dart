import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tour_vn/core/services/onboarding_service.dart';
import 'package:tour_vn/features/onboarding/domain/entities/mood.dart';

void main() {
  group('OnboardingService', () {
    late SharedPreferences prefs;
    late OnboardingService service;

    setUp(() async {
      // Initialize mock SharedPreferences with empty values
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = OnboardingService(prefs);
    });

    group('isOnboardingCompleted', () {
      test('returns false when onboarding has not been completed', () {
        expect(service.isOnboardingCompleted(), isFalse);
      });

      test('returns true after markOnboardingCompleted is called', () async {
        await service.markOnboardingCompleted();
        expect(service.isOnboardingCompleted(), isTrue);
      });
    });

    group('markOnboardingCompleted', () {
      test('persists completed state', () async {
        expect(service.isOnboardingCompleted(), isFalse);

        await service.markOnboardingCompleted();

        expect(service.isOnboardingCompleted(), isTrue);
      });

      test('state persists across service instances', () async {
        await service.markOnboardingCompleted();

        // Create new service instance with same prefs
        final newService = OnboardingService(prefs);

        expect(newService.isOnboardingCompleted(), isTrue);
      });
    });

    group('saveMoodPreferencesLocally', () {
      test('saves empty set', () async {
        await service.saveMoodPreferencesLocally({});

        final result = service.getMoodPreferencesLocally();
        expect(result, isEmpty);
      });

      test('saves single mood', () async {
        await service.saveMoodPreferencesLocally({Mood.healing});

        final result = service.getMoodPreferencesLocally();
        expect(result, {Mood.healing});
      });

      test('saves multiple moods', () async {
        final moods = {Mood.healing, Mood.adventure, Mood.party};
        await service.saveMoodPreferencesLocally(moods);

        final result = service.getMoodPreferencesLocally();
        expect(result, moods);
      });

      test('saves all moods', () async {
        final allMoods = Mood.all.toSet();
        await service.saveMoodPreferencesLocally(allMoods);

        final result = service.getMoodPreferencesLocally();
        expect(result, allMoods);
      });
    });

    group('getMoodPreferencesLocally', () {
      test('returns empty set when no preferences saved', () {
        final result = service.getMoodPreferencesLocally();
        expect(result, isEmpty);
      });

      test('returns correct mood set after save', () async {
        final moods = {Mood.foodie, Mood.photography};
        await service.saveMoodPreferencesLocally(moods);

        final result = service.getMoodPreferencesLocally();
        expect(result, moods);
        expect(result.length, 2);
      });

      test('handles invalid mood names gracefully', () async {
        // Manually set invalid data
        await prefs.setStringList('mood_preferences', [
          'invalid_mood',
          'healing',
        ]);

        // Should only return valid mood, ignoring invalid
        final result = service.getMoodPreferencesLocally();
        expect(result, {Mood.healing});
      });
    });

    group('getMoodPreferenceNames', () {
      test('returns empty list when no preferences saved', () {
        final result = service.getMoodPreferenceNames();
        expect(result, isEmpty);
      });

      test('returns list of mood names', () async {
        await service.saveMoodPreferencesLocally({
          Mood.foodie,
          Mood.photography,
        });

        final result = service.getMoodPreferenceNames();
        expect(result, containsAll(['foodie', 'photography']));
        expect(result.length, 2);
      });
    });

    group('resetOnboarding', () {
      test('clears onboarding completed flag', () async {
        await service.markOnboardingCompleted();
        expect(service.isOnboardingCompleted(), isTrue);

        await service.resetOnboarding();

        expect(service.isOnboardingCompleted(), isFalse);
      });

      test('clears mood preferences', () async {
        await service.saveMoodPreferencesLocally({Mood.adventure});
        expect(service.getMoodPreferencesLocally(), isNotEmpty);

        await service.resetOnboarding();

        expect(service.getMoodPreferencesLocally(), isEmpty);
      });

      test('clears both onboarding state and preferences', () async {
        await service.markOnboardingCompleted();
        await service.saveMoodPreferencesLocally({Mood.healing, Mood.party});

        await service.resetOnboarding();

        expect(service.isOnboardingCompleted(), isFalse);
        expect(service.getMoodPreferencesLocally(), isEmpty);
      });
    });

    group('complete flow', () {
      test('full onboarding completion flow works correctly', () async {
        // Initial state
        expect(service.isOnboardingCompleted(), isFalse);
        expect(service.getMoodPreferencesLocally(), isEmpty);

        // Select moods
        final selectedMoods = {Mood.healing, Mood.adventure, Mood.foodie};
        await service.saveMoodPreferencesLocally(selectedMoods);

        // Mark complete
        await service.markOnboardingCompleted();

        // Verify final state
        expect(service.isOnboardingCompleted(), isTrue);
        expect(service.getMoodPreferencesLocally(), selectedMoods);

        // Verify persistence with new instance
        final newService = OnboardingService(prefs);
        expect(newService.isOnboardingCompleted(), isTrue);
        expect(newService.getMoodPreferencesLocally(), selectedMoods);
      });
    });

    // Story 6.4: Skip Onboarding Tests
    group('isOnboardingSkipped', () {
      test('returns false when onboarding has not been skipped', () {
        expect(service.isOnboardingSkipped(), isFalse);
      });

      test('returns true after markOnboardingSkipped is called', () async {
        await service.markOnboardingSkipped();
        expect(service.isOnboardingSkipped(), isTrue);
      });
    });

    group('markOnboardingSkipped', () {
      test('sets both skipped and completed flags to true', () async {
        await service.markOnboardingSkipped();

        expect(service.isOnboardingSkipped(), isTrue);
        expect(service.isOnboardingCompleted(), isTrue);
      });

      test('state persists across service instances', () async {
        await service.markOnboardingSkipped();

        // Create new service instance with same prefs
        final newService = OnboardingService(prefs);

        expect(newService.isOnboardingSkipped(), isTrue);
        expect(newService.isOnboardingCompleted(), isTrue);
      });
    });

    group('shouldShowOnboarding', () {
      test('returns true when neither completed nor skipped', () {
        expect(service.shouldShowOnboarding(), isTrue);
      });

      test('returns false when completed', () async {
        await service.markOnboardingCompleted();
        expect(service.shouldShowOnboarding(), isFalse);
      });

      test('returns false when skipped', () async {
        await service.markOnboardingSkipped();
        expect(service.shouldShowOnboarding(), isFalse);
      });
    });

    group('resetOnboarding with skip', () {
      test('clears skipped flag', () async {
        await service.markOnboardingSkipped();
        expect(service.isOnboardingSkipped(), isTrue);

        await service.resetOnboarding();

        expect(service.isOnboardingSkipped(), isFalse);
      });

      test('clears all onboarding state including skip', () async {
        await service.markOnboardingSkipped();
        await service.saveMoodPreferencesLocally({Mood.healing});

        await service.resetOnboarding();

        expect(service.isOnboardingCompleted(), isFalse);
        expect(service.isOnboardingSkipped(), isFalse);
        expect(service.getMoodPreferencesLocally(), isEmpty);
        expect(service.shouldShowOnboarding(), isTrue);
      });
    });

    group('skip onboarding flow', () {
      test('full skip flow works correctly', () async {
        // Initial state
        expect(service.isOnboardingCompleted(), isFalse);
        expect(service.isOnboardingSkipped(), isFalse);
        expect(service.shouldShowOnboarding(), isTrue);
        expect(service.getMoodPreferencesLocally(), isEmpty);

        // Skip onboarding
        await service.markOnboardingSkipped();

        // Verify final state
        expect(service.isOnboardingCompleted(), isTrue);
        expect(service.isOnboardingSkipped(), isTrue);
        expect(service.shouldShowOnboarding(), isFalse);
        expect(service.getMoodPreferencesLocally(), isEmpty);

        // Verify persistence with new instance
        final newService = OnboardingService(prefs);
        expect(newService.isOnboardingCompleted(), isTrue);
        expect(newService.isOnboardingSkipped(), isTrue);
        expect(newService.shouldShowOnboarding(), isFalse);
      });
    });
  });
}
