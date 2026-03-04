import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/review/data/repositories/review_like_repository.dart';

void main() {
  late ReviewLikeRepository repository;

  setUp(() {
    repository = ReviewLikeRepository();
  });

  group('ReviewLikeRepository', () {
    group('likeReview', () {
      test('should add a like successfully', () async {
        await repository.likeReview('review-1', 'user-1');

        final isLiked = await repository.isLikedByUser('review-1', 'user-1');
        expect(isLiked, isTrue);
      });

      test('should throw when liking same review twice', () async {
        await repository.likeReview('review-1', 'user-1');

        expect(
          () => repository.likeReview('review-1', 'user-1'),
          throwsException,
        );
      });

      test('should increment like count delta', () async {
        expect(repository.getLikeCountDelta('review-1'), 0);

        await repository.likeReview('review-1', 'user-1');

        expect(repository.getLikeCountDelta('review-1'), 1);
      });

      test('different users can like same review', () async {
        await repository.likeReview('review-1', 'user-1');
        await repository.likeReview('review-1', 'user-2');

        expect(repository.getLikeCountDelta('review-1'), 2);
      });
    });

    group('unlikeReview', () {
      test('should remove a like successfully', () async {
        await repository.likeReview('review-1', 'user-1');
        await repository.unlikeReview('review-1', 'user-1');

        final isLiked = await repository.isLikedByUser('review-1', 'user-1');
        expect(isLiked, isFalse);
      });

      test('should decrement like count delta', () async {
        await repository.likeReview('review-1', 'user-1');
        expect(repository.getLikeCountDelta('review-1'), 1);

        await repository.unlikeReview('review-1', 'user-1');
        expect(repository.getLikeCountDelta('review-1'), 0);
      });

      test('unliking without prior like decreases delta below 0', () async {
        await repository.unlikeReview('review-1', 'user-1');
        expect(repository.getLikeCountDelta('review-1'), -1);
      });
    });

    group('isLikedByUser', () {
      test('should return false for non-liked review', () async {
        final isLiked = await repository.isLikedByUser('review-1', 'user-1');
        expect(isLiked, isFalse);
      });

      test('should return true for liked review', () async {
        await repository.likeReview('review-1', 'user-1');

        final isLiked = await repository.isLikedByUser('review-1', 'user-1');
        expect(isLiked, isTrue);
      });

      test('should return false for different user', () async {
        await repository.likeReview('review-1', 'user-1');

        final isLiked = await repository.isLikedByUser('review-1', 'user-2');
        expect(isLiked, isFalse);
      });
    });

    group('isLikedByUserSync', () {
      test('returns true synchronously when liked', () async {
        await repository.likeReview('review-1', 'user-1');

        final isLiked = repository.isLikedByUserSync('review-1', 'user-1');
        expect(isLiked, isTrue);
      });

      test('returns false synchronously when not liked', () {
        final isLiked = repository.isLikedByUserSync('review-1', 'user-1');
        expect(isLiked, isFalse);
      });
    });

    group('getLikesForReview', () {
      test('should return empty list for review with no likes', () async {
        final likes = await repository.getLikesForReview('review-1');
        expect(likes, isEmpty);
      });

      test('should return all likes for a review', () async {
        await repository.likeReview('review-1', 'user-1');
        await repository.likeReview('review-1', 'user-2');
        await repository.likeReview('review-2', 'user-1');

        final likes = await repository.getLikesForReview('review-1');

        expect(likes.length, 2);
        expect(likes.every((like) => like.reviewId == 'review-1'), isTrue);
      });
    });

    group('toggleLike', () {
      test('should like when not liked', () async {
        final result = await repository.toggleLike('review-1', 'user-1');

        expect(result, isTrue);
        expect(await repository.isLikedByUser('review-1', 'user-1'), isTrue);
      });

      test('should unlike when already liked', () async {
        await repository.likeReview('review-1', 'user-1');

        final result = await repository.toggleLike('review-1', 'user-1');

        expect(result, isFalse);
        expect(await repository.isLikedByUser('review-1', 'user-1'), isFalse);
      });

      test('toggle twice returns to original state', () async {
        await repository.toggleLike('review-1', 'user-1'); // Like
        await repository.toggleLike('review-1', 'user-1'); // Unlike

        expect(await repository.isLikedByUser('review-1', 'user-1'), isFalse);
        expect(repository.getLikeCountDelta('review-1'), 0);
      });
    });

    group('getLikeCountDelta', () {
      test('should return 0 for new review', () {
        expect(repository.getLikeCountDelta('new-review'), 0);
      });

      test('should track multiple likes correctly', () async {
        await repository.likeReview('review-1', 'user-1');
        await repository.likeReview('review-1', 'user-2');
        await repository.likeReview('review-1', 'user-3');

        expect(repository.getLikeCountDelta('review-1'), 3);
      });

      test('should track likes and unlikes correctly', () async {
        await repository.likeReview('review-1', 'user-1');
        await repository.likeReview('review-1', 'user-2');
        await repository.unlikeReview('review-1', 'user-1');

        expect(repository.getLikeCountDelta('review-1'), 1);
      });
    });
  });
}
