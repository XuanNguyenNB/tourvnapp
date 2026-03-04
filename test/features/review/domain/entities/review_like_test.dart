import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/review/domain/entities/review_like.dart';

void main() {
  group('ReviewLike Entity', () {
    test('should create ReviewLike with required fields', () {
      final now = DateTime.now();
      final like = ReviewLike(
        reviewId: 'review-123',
        userId: 'user-456',
        createdAt: now,
      );

      expect(like.reviewId, 'review-123');
      expect(like.userId, 'user-456');
      expect(like.createdAt, now);
    });

    test('should generate correct key', () {
      final like = ReviewLike(
        reviewId: 'review-123',
        userId: 'user-456',
        createdAt: DateTime.now(),
      );

      expect(like.key, 'user-456:review-123');
    });

    test('should be equal if reviewId and userId are same', () {
      final like1 = ReviewLike(
        reviewId: 'review-123',
        userId: 'user-456',
        createdAt: DateTime(2024, 1, 1),
      );

      final like2 = ReviewLike(
        reviewId: 'review-123',
        userId: 'user-456',
        createdAt: DateTime(2024, 6, 15), // Different date
      );

      expect(like1, equals(like2));
      expect(like1.hashCode, equals(like2.hashCode));
    });

    test('should not be equal if reviewId differs', () {
      final like1 = ReviewLike(
        reviewId: 'review-123',
        userId: 'user-456',
        createdAt: DateTime.now(),
      );

      final like2 = ReviewLike(
        reviewId: 'review-different',
        userId: 'user-456',
        createdAt: DateTime.now(),
      );

      expect(like1, isNot(equals(like2)));
    });

    test('should not be equal if userId differs', () {
      final like1 = ReviewLike(
        reviewId: 'review-123',
        userId: 'user-456',
        createdAt: DateTime.now(),
      );

      final like2 = ReviewLike(
        reviewId: 'review-123',
        userId: 'user-different',
        createdAt: DateTime.now(),
      );

      expect(like1, isNot(equals(like2)));
    });

    test('copyWith should create new instance with updated fields', () {
      final original = ReviewLike(
        reviewId: 'review-123',
        userId: 'user-456',
        createdAt: DateTime(2024, 1, 1),
      );

      final copied = original.copyWith(userId: 'new-user');

      expect(copied.reviewId, 'review-123'); // Unchanged
      expect(copied.userId, 'new-user'); // Changed
      expect(copied.createdAt, DateTime(2024, 1, 1)); // Unchanged
      expect(original.userId, 'user-456'); // Original unchanged
    });

    test('toString should return formatted string', () {
      final like = ReviewLike(
        reviewId: 'review-123',
        userId: 'user-456',
        createdAt: DateTime(2024, 1, 1, 12, 0, 0),
      );

      final result = like.toString();

      expect(result, contains('review-123'));
      expect(result, contains('user-456'));
      expect(result, contains('ReviewLike'));
    });
  });
}
