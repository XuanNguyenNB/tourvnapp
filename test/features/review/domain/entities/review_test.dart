import 'package:flutter_test/flutter_test.dart';

import 'package:tour_vn/features/review/domain/entities/review.dart';

void main() {
  group('Review Entity', () {
    late Review review;

    setUp(() {
      review = Review(
        id: 'r1',
        heroImage: 'https://example.com/image.jpg',
        title: 'Test Review',
        authorId: 'u1',
        authorName: 'Test Author',
        authorAvatar: 'https://example.com/avatar.jpg',
        fullText: 'This is a test review with full text content.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        likeCount: 1234,
        commentCount: 56,
        saveCount: 89,
        relatedLocationIds: ['loc1', 'loc2'],
      );
    });

    test('should create Review with required fields', () {
      expect(review.id, 'r1');
      expect(review.heroImage, 'https://example.com/image.jpg');
      expect(review.authorName, 'Test Author');
      expect(review.fullText, 'This is a test review with full text content.');
      expect(review.likeCount, 1234);
      expect(review.relatedLocationIds, ['loc1', 'loc2']);
    });

    test('formattedLikes should format large numbers with k suffix', () {
      expect(review.formattedLikes, '1.2k');

      final smallReview = review.copyWith(likeCount: 500);
      expect(smallReview.formattedLikes, '500');
    });

    test('formattedComments should format correctly', () {
      expect(review.formattedComments, '56');

      final largeComments = review.copyWith(commentCount: 2500);
      expect(largeComments.formattedComments, '2.5k');
    });

    test('formattedSaves should format correctly', () {
      expect(review.formattedSaves, '89');

      final largeSaves = review.copyWith(saveCount: 10000);
      expect(largeSaves.formattedSaves, '10.0k');
    });

    test('formattedDate should show relative time for recent dates', () {
      // 2 days ago
      expect(review.formattedDate, '2 ngày trước');

      // 5 hours ago
      final hoursAgo = review.copyWith(
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      );
      expect(hoursAgo.formattedDate, '5 giờ trước');

      // 10 minutes ago
      final minutesAgo = review.copyWith(
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      expect(minutesAgo.formattedDate, '10 phút trước');

      // Just now
      final justNow = review.copyWith(
        createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );
      expect(justNow.formattedDate, 'Vừa xong');
    });

    test('formattedDate should show full date for older reviews', () {
      final oldReview = review.copyWith(createdAt: DateTime(2025, 6, 15));
      expect(oldReview.formattedDate, '15/6/2025');
    });

    test('copyWith should create new instance with updated fields', () {
      final updated = review.copyWith(
        likeCount: 9999,
        authorName: 'New Author',
      );

      expect(updated.likeCount, 9999);
      expect(updated.authorName, 'New Author');
      expect(updated.id, review.id); // unchanged
      expect(updated.fullText, review.fullText); // unchanged
    });

    test('equality should be based on id', () {
      final same = Review(
        id: 'r1',
        title: 'Test Title',
        heroImage: 'different-image.jpg',
        authorId: 'u2',
        authorName: 'Different Author',
        authorAvatar: 'avatar.jpg',
        fullText: 'Different text',
        createdAt: DateTime.now(),
        likeCount: 0,
        commentCount: 0,
        saveCount: 0,
      );

      expect(review == same, true);
      expect(review.hashCode, same.hashCode);

      final different = review.copyWith(id: 'r2');
      expect(review == different, false);
    });
  });
}
