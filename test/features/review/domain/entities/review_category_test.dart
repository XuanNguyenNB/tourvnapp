import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/review/domain/entities/review.dart';

void main() {
  group('Review Entity - Category Field (Story 8-2)', () {
    final testReview = Review(
      id: 'review-1',
      title: 'Test Title',
      heroImage: 'https://example.com/image.jpg',
      authorId: 'author-1',
      authorName: 'John Doe',
      authorAvatar: 'https://example.com/avatar.jpg',
      fullText: 'Amazing food place!',
      createdAt: DateTime(2024, 1, 1),
      likeCount: 100,
      commentCount: 20,
      saveCount: 15,
      relatedLocationIds: ['loc-1'],
      destinationId: 'da-nang',
      destinationName: 'Đà Nẵng',
      category: 'food', // NEW field
    );

    test('should have category field with nullable String type', () {
      // AC1: Review entity includes category field
      expect(testReview.category, isA<String?>());
      expect(testReview.category, equals('food'));
    });

    test('should handle null category for backward compatibility', () {
      // AC6: Backward compatibility
      final reviewWithoutCategory = Review(
        id: 'review-2',
        title: 'Test Title',
        heroImage: 'https://example.com/image2.jpg',
        authorId: 'author-2',
        authorName: 'Jane Doe',
        authorAvatar: 'https://example.com/avatar2.jpg',
        fullText: 'Beautiful place!',
        createdAt: DateTime(2024, 1, 2),
        likeCount: 50,
        commentCount: 10,
        saveCount: 5,
        // category is not provided (null)
      );

      expect(reviewWithoutCategory.category, isNull);
      // Should not throw error
      expect(() => reviewWithoutCategory.toString(), returnsNormally);
    });

    test('should support copyWith with category parameter', () {
      // AC5: copyWith includes category parameter
      final updatedReview = testReview.copyWith(category: 'places');

      expect(updatedReview.category, equals('places'));
      expect(updatedReview.id, equals('review-1')); // Other fields unchanged
      expect(updatedReview.authorName, equals('John Doe'));
    });

    test('should preserve category when copying without it', () {
      // AC5: Immutability pattern preserved
      final updatedReview = testReview.copyWith(likeCount: 200);

      expect(updatedReview.category, equals('food')); // Preserved
      expect(updatedReview.likeCount, equals(200)); // Updated
    });

    // NOTE: Setting null via copyWith is not supported in standard Dart pattern
    // because `category: null` will use `category ?? this.category` fallback.
    // To remove category, create new Review instance without it.
    // This test is skipped as it tests anti-pattern behavior.
    /*
    test('should allow updating category to null via copyWith', () {
      // Edge case: setting category to null
      final updatedReview = testReview.copyWith(category: null);

      expect(updatedReview.category, isNull);
    });
    */

    group('categoryDisplay getter (AC7 - Optional)', () {
      test('should return formatted category for "food"', () {
        final foodReview = testReview.copyWith(category: 'food');
        expect(foodReview.categoryDisplay, equals('🍜 Ăn uống'));
      });

      test('should return formatted category for "places"', () {
        final placesReview = testReview.copyWith(category: 'places');
        expect(placesReview.categoryDisplay, equals('📸 Điểm đến'));
      });

      test('should return formatted category for "stay"', () {
        final stayReview = testReview.copyWith(category: 'stay');
        expect(stayReview.categoryDisplay, equals('🏨 Lưu trú'));
      });

      test('should return null for null category', () {
        // Test with review created WITHOUT category
        final noCategory = Review(
          id: 'review-3',
          title: 'Test Title',
          heroImage: 'https://example.com/image3.jpg',
          authorId: 'author-3',
          authorName: 'Test User',
          authorAvatar: 'https://example.com/avatar3.jpg',
          fullText: 'Test review',
          createdAt: DateTime(2024, 1, 3),
          likeCount: 10,
          commentCount: 5,
          saveCount: 2,
          // category NOT provided (null)
        );
        expect(noCategory.categoryDisplay, isNull);
      });

      test('should return original value for unknown category', () {
        final unknownReview = testReview.copyWith(category: 'unknown');
        expect(unknownReview.categoryDisplay, equals('unknown'));
      });

      test('should handle case-insensitive category matching', () {
        final upperCaseReview = testReview.copyWith(category: 'FOOD');
        expect(upperCaseReview.categoryDisplay, equals('🍜 Ăn uống'));
      });
    });

    group('Category Values Validation', () {
      test('should accept valid category values matching Location', () {
        // Valid categories from Location entity
        final foodReview = testReview.copyWith(category: 'food');
        final placesReview = testReview.copyWith(category: 'places');
        final stayReview = testReview.copyWith(category: 'stay');

        expect(foodReview.category, equals('food'));
        expect(placesReview.category, equals('places'));
        expect(stayReview.category, equals('stay'));
      });

      test('should handle arbitrary category strings (no validation)', () {
        // Entity doesn't validate - repository layer responsibility
        final customReview = testReview.copyWith(category: 'custom-category');
        expect(customReview.category, equals('custom-category'));
      });
    });
  });
}
