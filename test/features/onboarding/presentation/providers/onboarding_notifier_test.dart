import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tour_vn/core/services/onboarding_service.dart';
import 'package:tour_vn/features/auth/data/repositories/user_repository.dart';
import 'package:tour_vn/features/auth/domain/entities/user.dart';
import 'package:tour_vn/features/auth/presentation/providers/auth_provider.dart';
import 'package:tour_vn/features/onboarding/domain/entities/mood.dart';
import 'package:tour_vn/features/onboarding/presentation/providers/onboarding_notifier.dart';

// Mocks
class MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('OnboardingNotifier', () {
    late SharedPreferences prefs;
    late OnboardingService onboardingService;
    late MockUserRepository mockUserRepo;

    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(<String>[]);
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      onboardingService = OnboardingService(prefs);
      mockUserRepo = MockUserRepository();
    });

    ProviderContainer createContainer({User? currentUser}) {
      return ProviderContainer(
        overrides: [
          onboardingServiceProvider.overrideWithValue(onboardingService),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
          currentUserProvider.overrideWithValue(currentUser),
        ],
      );
    }

    group('initial state', () {
      test('has default values', () {
        final container = createContainer();
        final state = container.read(onboardingNotifierProvider);

        expect(state.isLoading, isFalse);
        expect(state.isCompleted, isFalse);
        expect(state.error, isNull);

        container.dispose();
      });
    });

    group('completeOnboarding for anonymous user', () {
      test('saves preferences locally and marks complete', () async {
        final container = createContainer(
          currentUser: const User(uid: 'anon-123', isAnonymous: true),
        );

        final notifier = container.read(onboardingNotifierProvider.notifier);
        final moods = {Mood.healing, Mood.adventure};

        final result = await notifier.completeOnboarding(moods);

        expect(result, isTrue);
        expect(onboardingService.isOnboardingCompleted(), isTrue);
        expect(onboardingService.getMoodPreferencesLocally(), moods);

        final state = container.read(onboardingNotifierProvider);
        expect(state.isCompleted, isTrue);
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);

        // Verify Firestore was NOT called for anonymous user
        verifyNever(() => mockUserRepo.completeOnboarding(any(), any()));

        container.dispose();
      });

      test('saves locally when user is null', () async {
        final container = createContainer(currentUser: null);

        final notifier = container.read(onboardingNotifierProvider.notifier);
        final moods = {Mood.foodie};

        final result = await notifier.completeOnboarding(moods);

        expect(result, isTrue);
        expect(onboardingService.isOnboardingCompleted(), isTrue);
        expect(onboardingService.getMoodPreferencesLocally(), moods);

        verifyNever(() => mockUserRepo.completeOnboarding(any(), any()));

        container.dispose();
      });
    });

    group('completeOnboarding for authenticated user', () {
      test('saves both locally and to Firestore', () async {
        when(
          () => mockUserRepo.completeOnboarding(any(), any()),
        ).thenAnswer((_) async {});

        final container = createContainer(
          currentUser: const User(
            uid: 'auth-user-123',
            isAnonymous: false,
            email: 'test@example.com',
          ),
        );

        final notifier = container.read(onboardingNotifierProvider.notifier);
        final moods = {Mood.healing, Mood.photography};

        final result = await notifier.completeOnboarding(moods);

        expect(result, isTrue);

        // Verify local save
        expect(onboardingService.isOnboardingCompleted(), isTrue);
        expect(onboardingService.getMoodPreferencesLocally(), moods);

        // Verify Firestore save
        verify(
          () => mockUserRepo.completeOnboarding('auth-user-123', [
            'healing',
            'photography',
          ]),
        ).called(1);

        container.dispose();
      });

      test('succeeds locally even if Firestore fails', () async {
        when(
          () => mockUserRepo.completeOnboarding(any(), any()),
        ).thenThrow(Exception('Firestore error'));

        final container = createContainer(
          currentUser: const User(uid: 'auth-user-123', isAnonymous: false),
        );

        final notifier = container.read(onboardingNotifierProvider.notifier);
        final moods = {Mood.party};

        // Should still succeed because local save works
        final result = await notifier.completeOnboarding(moods);

        expect(result, isTrue);
        expect(onboardingService.isOnboardingCompleted(), isTrue);

        container.dispose();
      });
    });

    group('reset', () {
      test('resets state to default', () async {
        final container = createContainer(
          currentUser: const User(uid: 'test', isAnonymous: true),
        );

        final notifier = container.read(onboardingNotifierProvider.notifier);

        // Complete onboarding first
        await notifier.completeOnboarding({Mood.healing});
        expect(container.read(onboardingNotifierProvider).isCompleted, isTrue);

        // Reset
        notifier.reset();

        final state = container.read(onboardingNotifierProvider);
        expect(state.isLoading, isFalse);
        expect(state.isCompleted, isFalse);
        expect(state.error, isNull);

        container.dispose();
      });
    });

    group('OnboardingCompletionState', () {
      test('copyWith preserves values when not specified', () {
        const original = OnboardingCompletionState(
          isLoading: true,
          isCompleted: true,
          error: 'some error',
        );

        final copied = original.copyWith();

        expect(copied.isLoading, isTrue);
        expect(copied.isCompleted, isTrue);
        // Note: error is cleared by default in copyWith (null)
      });

      test('copyWith updates specified values', () {
        const original = OnboardingCompletionState();

        final copied = original.copyWith(
          isLoading: true,
          isCompleted: true,
          error: 'new error',
        );

        expect(copied.isLoading, isTrue);
        expect(copied.isCompleted, isTrue);
        expect(copied.error, 'new error');
      });
    });
  });
}
