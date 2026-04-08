import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';
import 'package:tour_vn/features/recommendation/domain/entities/user_profile.dart';
import 'package:tour_vn/features/recommendation/domain/services/recommendation_service.dart';

void main() {
  group('RecommendationService explainability', () {
    const service = RecommendationService();

    final candidates = [
      const Location(
        id: 'loc-food',
        destinationId: 'da-nang',
        destinationName: 'Đà Nẵng',
        name: 'Bún mắm nêm Vân',
        image: 'https://example.com/bun.jpg',
        category: 'food',
        tags: ['local-favorite', 'budget-friendly'],
        rating: 4.8,
        latitude: 16.0678,
        longitude: 108.2208,
        viewCount: 320,
        saveCount: 85,
      ),
      const Location(
        id: 'loc-place',
        destinationId: 'da-nang',
        destinationName: 'Đà Nẵng',
        name: 'Cầu Rồng',
        image: 'https://example.com/cau-rong.jpg',
        category: 'places',
        tags: ['instagram-worthy'],
        rating: 4.6,
        latitude: 16.0612,
        longitude: 108.2272,
        viewCount: 500,
        saveCount: 140,
      ),
    ];

    test('trả breakdown hợp lệ và reasons không rỗng khi có profile', () {
      final profile = UserProfile(
        userId: 'u1',
        preferredCategoryIds: const ['food'],
        preferredTags: const ['local-favorite', 'budget-friendly'],
        preferredDestinationIds: const ['da-nang'],
        updatedAt: DateTime(2026, 4, 8),
      );

      final items = service.recommend(
        candidates: candidates,
        profile: profile,
        categoryInterests: const {'food': 1.0},
        tagInterests: const {'local-favorite': 0.8},
        interactedLocationIds: const {},
        userLat: 16.0678,
        userLng: 108.2208,
      );

      expect(items, isNotEmpty);
      expect(items.first.reasons, isNotEmpty);
      expect(items.first.scoreBreakdown.maxValue, greaterThan(0));
      expect(items.first.scoreBreakdown.category, greaterThan(0));
      expect(items.first.scoreBreakdown.quality, greaterThan(0));
    });

    test('vẫn có breakdown và reasons khi không có profile', () {
      final items = service.recommend(
        candidates: candidates,
        profile: null,
        interactedLocationIds: const {},
        userLat: 16.0678,
        userLng: 108.2208,
      );

      expect(items, isNotEmpty);
      expect(items.first.reasons, isNotEmpty);
      expect(items.first.scoreBreakdown.maxValue, greaterThan(0));
      expect(items.first.scoreBreakdown.quality, greaterThan(0));
      expect(items.first.scoreBreakdown.proximity, greaterThanOrEqualTo(0));
    });
  });
}
