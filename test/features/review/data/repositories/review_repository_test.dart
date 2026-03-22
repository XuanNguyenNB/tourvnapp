import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/review/data/repositories/review_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ReviewRepository repository;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    repository = ReviewRepository(firestore: firestore);

    await firestore.collection('reviews').doc('review-1').set({
      'id': 'review-1',
      'heroImage': 'https://example.com/review-1.jpg',
      'title': 'Quán cà phê Đà Lạt',
      'authorId': 'admin',
      'authorName': 'Linh Nguyễn',
      'authorAvatar': 'https://example.com/avatar-1.jpg',
      'fullText': 'Bài review chi tiết về quán cà phê.',
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      'likeCount': 10,
      'commentCount': 2,
      'saveCount': 4,
      'relatedLocationIds': ['loc-1', 'loc-2'],
      'destinationId': 'da-lat',
      'destinationName': 'Đà Lạt',
      'category': 'food',
      'status': 'published',
    });

    await firestore.collection('reviews').doc('review-2').set({
      'id': 'review-2',
      'heroImage': 'https://example.com/review-2.jpg',
      'title': 'Lịch trình Tràng An',
      'authorId': 'admin',
      'authorName': 'Mai Anh',
      'authorAvatar': 'https://example.com/avatar-2.jpg',
      'fullText': 'Gợi ý lịch trình khám phá Tràng An.',
      'createdAt': DateTime(2026, 1, 2).toIso8601String(),
      'likeCount': 25,
      'commentCount': 3,
      'saveCount': 8,
      'relatedLocationIds': ['loc-3'],
      'destinationId': 'ninh-binh',
      'destinationName': 'Ninh Bình',
      'category': 'places',
      'status': 'draft_ai',
    });
  });

  group('ReviewRepository', () {
    test('getReviewById returns review for valid id', () async {
      final review = await repository.getReviewById('review-1');

      expect(review.id, 'review-1');
      expect(review.authorName, 'Linh Nguyễn');
      expect(review.relatedLocationIds, hasLength(2));
    });

    test('getReviewById throws for invalid id', () async {
      expect(() => repository.getReviewById('invalid-id'), throwsException);
    });

    test('getAllReviews returns all seeded reviews', () async {
      final reviews = await repository.getAllReviews();

      expect(reviews, hasLength(2));
      expect(reviews.every((review) => review.title.isNotEmpty), isTrue);
    });

    test('getReviewsByStatus filters reviews server-side', () async {
      final publishedReviews = await repository.getReviewsByStatus('published');
      final draftReviews = await repository.getReviewsByStatus('draft_ai');

      expect(publishedReviews, hasLength(1));
      expect(publishedReviews.single.id, 'review-1');
      expect(draftReviews, hasLength(1));
      expect(draftReviews.single.id, 'review-2');
    });
  });
}
