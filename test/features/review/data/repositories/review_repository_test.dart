import 'package:flutter_test/flutter_test.dart';

import 'package:tour_vn/features/review/data/repositories/review_repository.dart';
import 'package:tour_vn/features/review/domain/entities/review.dart';

void main() {
  group('ReviewRepository', () {
    late ReviewRepository repository;

    setUp(() {
      repository = ReviewRepository();
    });

    test('getReviewById should return review for valid id', () async {
      final review = await repository.getReviewById('review-1');

      expect(review, isNotNull);
      expect(review.id, 'review-1');
      expect(review.authorName, 'Linh Nguyễn');
    });

    test('getReviewById should throw for invalid id', () async {
      expect(() => repository.getReviewById('invalid-id'), throwsException);
    });

    test('getAllReviews should return list of reviews', () async {
      final reviews = await repository.getAllReviews();

      expect(reviews, isNotEmpty);
      expect(reviews.length, 9);
      expect(reviews.every((r) => r is Review), true);
    });

    test('mockReviews should be accessible', () {
      final mocks = ReviewRepository.mockReviews;

      expect(mocks, isNotEmpty);
      expect(mocks.length, 9);
    });

    test('mock reviews should have valid data', () async {
      final reviews = await repository.getAllReviews();

      for (final review in reviews) {
        expect(review.id, isNotEmpty);
        expect(review.heroImage, isNotEmpty);
        expect(review.authorName, isNotEmpty);
        expect(review.fullText, isNotEmpty);
        expect(review.likeCount, greaterThanOrEqualTo(0));
        expect(review.commentCount, greaterThanOrEqualTo(0));
        expect(review.saveCount, greaterThanOrEqualTo(0));
      }
    });

    test('mock reviews should have related locations', () async {
      final review = await repository.getReviewById('review-1');

      expect(review.relatedLocationIds, isNotEmpty);
      expect(review.relatedLocationIds.length, 3);
    });
  });
}
