import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/home/domain/entities/review_preview.dart';
import 'package:tour_vn/features/home/presentation/widgets/review_card.dart';

void main() {
  final reviewWithMetadata = ReviewPreview(
    id: 'review-1',
    title: 'Cà phê ngắm hoàng hôn',
    authorName: 'Linh Nguyễn',
    authorAvatar: 'https://example.com/avatar.jpg',
    shortText: 'Một quán nhỏ nhìn ra biển, rất hợp cho buổi chiều thư giãn.',
    heroImage: 'https://example.com/hero.jpg',
    likeCount: 42,
    commentCount: 12,
    destinationId: 'da-nang',
    destinationName: 'Đà Nẵng',
    category: 'food',
    categoryName: 'Ăn uống',
    categoryEmoji: '🍜',
    rating: 4.8,
    createdAt: DateTime(2026, 1, 20),
  );

  const reviewWithoutImage = ReviewPreview(
    id: 'review-2',
    title: 'Không có ảnh',
    authorName: 'Test User',
    authorAvatar: 'https://example.com/avatar.jpg',
    shortText: 'Nội dung ngắn',
    likeCount: 0,
    commentCount: 0,
    heroImage: null,
  );

  Widget buildTestWidget(
    ReviewPreview review, {
    VoidCallback? onTap,
    double? distanceKm,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReviewCard(
              review: review,
              onTap: onTap,
              distanceKm: distanceKm,
            ),
          ),
        ),
      ),
    );
  }

  group('ReviewCard', () {
    testWidgets('renders title and 16:9 image section', (tester) async {
      await tester.pumpWidget(buildTestWidget(reviewWithMetadata));
      await tester.pump();

      expect(find.text('Cà phê ngắm hoàng hôn'), findsOneWidget);
      expect(find.byType(AspectRatio), findsOneWidget);

      final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspectRatio.aspectRatio, closeTo(16 / 9, 0.01));
    });

    testWidgets('uses CachedNetworkImage when heroImage is provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(reviewWithMetadata));
      await tester.pump();

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('shows placeholder icon when heroImage is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(reviewWithoutImage));
      await tester.pump();

      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('renders subtitle metadata for destination, rating, and category', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(reviewWithMetadata));
      await tester.pump();

      expect(find.text('Đà Nẵng'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('🍜 Ăn uống'), findsOneWidget);
    });

    testWidgets('shows distance badge when distance is provided', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(reviewWithMetadata, distanceKm: 2.4),
      );
      await tester.pump();

      expect(find.byIcon(Icons.near_me), findsOneWidget);
      expect(find.textContaining('2.4'), findsOneWidget);
    });

    testWidgets('calls onTap callback when provided', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildTestWidget(reviewWithMetadata, onTap: () => tapped = true),
      );
      await tester.pump();

      await tester.tap(find.byType(ReviewCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('keeps gesture and scale animation wrappers', (tester) async {
      await tester.pumpWidget(buildTestWidget(reviewWithMetadata));
      await tester.pump();

      expect(find.byType(GestureDetector), findsWidgets);
      expect(find.byType(Transform), findsWidgets);
    });
  });
}
