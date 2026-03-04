import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/home/domain/entities/content_item.dart';
import 'package:tour_vn/features/home/domain/entities/destination_preview.dart';
import 'package:tour_vn/features/home/domain/entities/review_preview.dart';
import 'package:tour_vn/features/home/presentation/providers/filtered_home_content_provider.dart';
import 'package:tour_vn/features/home/presentation/providers/home_provider.dart';
import 'package:tour_vn/features/onboarding/presentation/providers/user_mood_preferences_provider.dart';

/// Tests for FilteredHomeContentNotifier
///
/// Story 6.5: Implement Personalized Feed Filtering
void main() {
  group('FilteredHomeContentNotifier', () {
    // Test data
    final healingDestination = DestinationPreview(
      id: 'da-lat',
      name: 'Đà Lạt',
      heroImage: 'https://example.com/dalat.jpg',
      engagementCount: 2341,
      moods: ['healing', 'photography'],
    );

    final adventureDestination = DestinationPreview(
      id: 'phu-quoc',
      name: 'Phú Quốc',
      heroImage: 'https://example.com/phuquoc.jpg',
      engagementCount: 3102,
      moods: ['adventure'],
    );

    final foodieReview = ReviewPreview(
      title: 'Test Review',
      id: 'review-1',
      authorName: 'Test User',
      authorAvatar: 'https://example.com/avatar.jpg',
      shortText: 'Great food!',
      heroImage: 'https://example.com/food.jpg',
      likeCount: 500,
      commentCount: 10,
      moods: ['foodie'],
    );

    final partyReview = ReviewPreview(
      id: 'review-2',
      title: 'Test Title',
      authorName: 'Test User 2',
      authorAvatar: 'https://example.com/avatar2.jpg',
      shortText: 'Great party!',
      heroImage: 'https://example.com/party.jpg',
      likeCount: 1000,
      commentCount: 20,
      moods: ['party'],
    );

    final mockContent = [
      DestinationContent(healingDestination),
      DestinationContent(adventureDestination),
      ReviewContent(foodieReview),
      ReviewContent(partyReview),
    ];

    test('returns content sorted by mood match score (AC #1)', () async {
      // Setup: User has [healing, photography] preferences
      final userMoods = ['healing', 'photography'];

      // Create container with overrides
      final container = ProviderContainer(
        overrides: [
          homeContentProvider.overrideWithValue(AsyncData(mockContent)),
          userMoodPreferencesProvider.overrideWithValue(AsyncData(userMoods)),
        ],
      );
      addTearDown(container.dispose);

      // Get filtered content
      final result = await container.read(filteredHomeContentProvider.future);

      // Assert: healing/photography content (Đà Lạt) appears first
      expect(result.isNotEmpty, true);
      expect(result.first, isA<DestinationContent>());
      final firstDest = (result.first as DestinationContent).destination;
      expect(firstDest.id, 'da-lat'); // Has healing + photography = 100% match
    });

    test('returns original order when no preferences set (AC #3)', () async {
      // Setup: User skipped onboarding (empty preferences)
      final container = ProviderContainer(
        overrides: [
          homeContentProvider.overrideWithValue(AsyncData(mockContent)),
          userMoodPreferencesProvider.overrideWithValue(const AsyncData([])),
        ],
      );
      addTearDown(container.dispose);

      // Get filtered content
      final result = await container.read(filteredHomeContentProvider.future);

      // Assert: Content in original order
      expect(result.length, mockContent.length);
      expect(result, mockContent);
    });

    test('includes all content even with no mood matches (AC #2)', () async {
      // Setup: User has [healing] but some content has no match
      final container = ProviderContainer(
        overrides: [
          homeContentProvider.overrideWithValue(AsyncData(mockContent)),
          userMoodPreferencesProvider.overrideWithValue(
            const AsyncData(['healing']),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Get filtered content
      final result = await container.read(filteredHomeContentProvider.future);

      // Assert: All content still returned
      expect(result.length, mockContent.length);
      // Assert: Healing content appears first
      final firstDest = (result.first as DestinationContent).destination;
      expect(firstDest.moods?.contains('healing'), true);
    });

    test('partial matches ranked by score correctly', () async {
      // Setup: User has multiple moods
      final container = ProviderContainer(
        overrides: [
          homeContentProvider.overrideWithValue(AsyncData(mockContent)),
          userMoodPreferencesProvider.overrideWithValue(
            const AsyncData(['healing', 'adventure']),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Get filtered content
      final result = await container.read(filteredHomeContentProvider.future);

      // Both destinations have partial matches
      // Đà Lạt: healing matches (1/2 = 0.5)
      // Phú Quốc: adventure matches (1/2 = 0.5)
      // When scores are equal, sort by engagement
      expect(result.length, mockContent.length);

      // Phú Quốc has higher engagement (3102 vs 2341)
      final firstDest = (result.first as DestinationContent).destination;
      expect(firstDest.id, 'phu-quoc');
    });

    test('non-matching content sorted by engagement at end', () async {
      final container = ProviderContainer(
        overrides: [
          homeContentProvider.overrideWithValue(AsyncData(mockContent)),
          userMoodPreferencesProvider.overrideWithValue(
            const AsyncData(['photography']),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(filteredHomeContentProvider.future);

      // Đà Lạt has photography (match), others don't
      final firstDest = (result.first as DestinationContent).destination;
      expect(firstDest.id, 'da-lat');

      // Last items should be non-matching, sorted by engagement
      // partyReview (1000 likes) > foodieReview (500 likes)
      final lastItem = result.last;
      expect(lastItem, isA<ReviewContent>());
    });
  });

  group('Content entity moods field', () {
    test('DestinationPreview stores moods correctly', () {
      final dest = DestinationPreview(
        id: 'test',
        name: 'Test',
        heroImage: 'https://test.com',
        engagementCount: 100,
        moods: ['healing', 'photography'],
      );

      expect(dest.moods, ['healing', 'photography']);
    });

    test('DestinationPreview copyWith preserves moods', () {
      final dest = DestinationPreview(
        id: 'test',
        name: 'Test',
        heroImage: 'https://test.com',
        engagementCount: 100,
        moods: ['healing'],
      );

      final copied = dest.copyWith(name: 'Updated');
      expect(copied.moods, ['healing']);
      expect(copied.name, 'Updated');
    });

    test('ReviewPreview stores moods correctly', () {
      final review = ReviewPreview(
        id: 'test',
        title: 'Test Title',
        authorName: 'Author',
        authorAvatar: 'https://avatar.com',
        shortText: 'Great!',
        likeCount: 100,
        commentCount: 10,
        moods: ['foodie', 'adventure'],
      );

      expect(review.moods, ['foodie', 'adventure']);
    });

    test('ReviewPreview copyWith preserves moods', () {
      final review = ReviewPreview(
        id: 'test',
        title: 'Test Title',
        authorName: 'Author',
        authorAvatar: 'https://avatar.com',
        shortText: 'Great!',
        likeCount: 100,
        commentCount: 10,
        moods: ['party'],
      );

      final copied = review.copyWith(shortText: 'Amazing!');
      expect(copied.moods, ['party']);
      expect(copied.shortText, 'Amazing!');
    });

    test('DestinationPreview handles null moods', () {
      final dest = DestinationPreview(
        id: 'test',
        name: 'Test',
        heroImage: 'https://test.com',
        engagementCount: 100,
      );

      expect(dest.moods, isNull);
    });

    test('ReviewPreview handles null moods', () {
      final review = ReviewPreview(
        id: 'test',
        title: 'Test Title',
        authorName: 'Author',
        authorAvatar: 'https://avatar.com',
        shortText: 'Great!',
        likeCount: 100,
        commentCount: 10,
      );

      expect(review.moods, isNull);
    });
  });
}
