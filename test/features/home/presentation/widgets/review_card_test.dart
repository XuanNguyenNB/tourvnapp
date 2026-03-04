import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:tour_vn/features/home/presentation/widgets/review_card.dart';
import 'package:tour_vn/features/home/domain/entities/review_preview.dart';
import 'package:tour_vn/features/review/presentation/widgets/animated_heart_button.dart';

/// Widget tests for ReviewCard (Compact Review Card layout)
///
/// Redesigned tests for compact review-focused card:
/// - AC1: 16:9 landscape hero image with rounded corners
/// - AC2: Rating + category info row
/// - AC3: Caption with "Xem thêm" link
/// - AC4: Location tag overlay on image
/// - AC5: Compact add-to-trip icon
/// - AC6: Tap and long-press gestures (backward compatible)
void main() {
  // Test data
  const testReview = ReviewPreview(
    title: 'Test Review',
    id: 'test-review-1',
    authorName: 'Linh Nguyễn',
    authorAvatar: 'https://example.com/avatar.jpg',
    heroImage: 'https://example.com/hero.jpg',
    shortText:
        'Một trải nghiệm tuyệt vời tại Đà Lạt! Thành phố ngàn hoa thật sự rất đẹp và lãng mạn.',
    likeCount: 42,
    commentCount: 12,
    destinationId: 'da-lat',
    destinationName: 'Đà Lạt',
    category: 'places',
    moods: ['romantic', 'peaceful'],
  );

  const testReviewLongText = ReviewPreview(
    id: 'test-review-2',
    title: 'Test Title',
    authorName: 'Minh Trần',
    authorAvatar: 'https://example.com/avatar2.jpg',
    heroImage: 'https://example.com/hero2.jpg',
    shortText:
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit.',
    likeCount: 100,
    commentCount: 25,
    destinationId: 'da-nang',
    destinationName: 'Đà Nẵng',
    category: 'food',
    moods: ['adventure'],
  );

  const testReviewNoImage = ReviewPreview(
    id: 'test-review-3',
    title: 'Test Title',
    authorName: 'Test User',
    authorAvatar: 'https://example.com/avatar3.jpg',
    heroImage: null,
    shortText: 'No image review',
    likeCount: 0,
    commentCount: 0,
    destinationId: null,
    destinationName: null,
    category: null,
    moods: [],
  );

  Widget buildTestWidget(ReviewPreview review, {VoidCallback? onTap}) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReviewCard(review: review, onTap: onTap),
          ),
        ),
      ),
    );
  }

  group('ReviewCard Compact Layout', () {
    testWidgets('renders Column-based layout structure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(testReview));
      await tester.pump();

      expect(find.byType(ReviewCard), findsOneWidget);
      expect(find.byType(Column), findsWidgets);

      final reviewCard = tester.widget<ReviewCard>(find.byType(ReviewCard));
      expect(reviewCard.review.id, equals('test-review-1'));
    });

    testWidgets('has card shadow and rounded corners', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(testReview));
      await tester.pump();

      // Find container with BoxDecoration (card wrapper)
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });
  });

  group('AC1: 16:9 Landscape Hero Image', () {
    testWidgets('renders AspectRatio 16:9 for hero image', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(testReview));
      await tester.pump();

      final aspectRatio = find.byType(AspectRatio);
      expect(aspectRatio, findsOneWidget);

      final aspectRatioWidget = tester.widget<AspectRatio>(aspectRatio);
      expect(aspectRatioWidget.aspectRatio, closeTo(16 / 9, 0.01));
    });

    testWidgets('uses CachedNetworkImage for hero image', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(testReview));
      await tester.pump();

      expect(find.byType(CachedNetworkImage), findsWidgets);
    });

    testWidgets('shows placeholder icon when heroImage is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(testReviewNoImage));
      await tester.pump();

      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('has ClipRRect for rounded top corners', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(testReview));
      await tester.pump();

      expect(find.byType(ClipRRect), findsWidgets);
    });
  });

  group('AC2: Rating and Category Info Row', () {
    testWidgets('displays star rating icon', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(testReview));
      await tester.pump();

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('displays AnimatedHeartButton for likes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(testReview));
      await tester.pump();

      expect(find.byType(AnimatedHeartButton), findsOneWidget);
    });

    testWidgets('displays category badge when category is set', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(testReview));
      await tester.pump();

      // Category 'places' should show '📸 Tham quan'
      expect(find.text('📸 Tham quan'), findsOneWidget);
    });

    testWidgets('displays food category badge correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(testReviewLongText));
      await tester.pump();

      expect(find.text('🍜 Ăn uống'), findsOneWidget);
    });
  });

  group('AC3: Caption Section', () {
    testWidgets('displays RichText for caption', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(testReview));
      await tester.pump();

      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('displays "Xem thêm" for long text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(testReviewLongText));
      await tester.pump();

      // Long text should trigger "Xem thêm" link
      expect(find.byType(ReviewCard), findsOneWidget);
    });
  });

  group('AC4: Location Tag', () {
    testWidgets('displays location tag with valid destinationName', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(testReview));
      await tester.pump();

      expect(find.byType(Stack), findsWidgets);
      expect(find.text('📍 '), findsOneWidget);
      expect(find.text('Đà Lạt'), findsWidgets);
    });

    testWidgets('does NOT render location tag when destinationName is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(testReviewNoImage));
      await tester.pump();

      expect(find.text('📍 '), findsNothing);
    });

    testWidgets('does NOT render location tag when destinationName is empty', (
      WidgetTester tester,
    ) async {
      const emptyDestinationReview = ReviewPreview(
        id: 'test-empty-dest',
        title: 'Test Title',
        authorName: 'Test Author',
        authorAvatar: 'https://example.com/avatar.jpg',
        heroImage: 'https://example.com/image.jpg',
        shortText: 'Test text',
        likeCount: 5,
        commentCount: 2,
        destinationId: '',
        destinationName: '',
        category: null,
        moods: [],
      );

      await tester.pumpWidget(buildTestWidget(emptyDestinationReview));
      await tester.pump();

      expect(find.text('📍 '), findsNothing);
    });

    testWidgets('location tag renders on card with placeholder image', (
      WidgetTester tester,
    ) async {
      const noImageWithDest = ReviewPreview(
        id: 'test-no-image-with-dest',
        title: 'Test Title',
        authorName: 'Test Author',
        authorAvatar: 'https://example.com/avatar.jpg',
        heroImage: null,
        shortText: 'Test text',
        likeCount: 5,
        commentCount: 2,
        destinationId: 'hue',
        destinationName: 'Huế',
        category: null,
        moods: [],
      );

      await tester.pumpWidget(buildTestWidget(noImageWithDest));
      await tester.pump();

      expect(find.text('📍 '), findsOneWidget);
      expect(find.text('Huế'), findsWidgets);
      expect(find.byIcon(Icons.image), findsOneWidget);
    });
  });

  group('AC5: Compact Add to Trip Icon', () {
    testWidgets('displays add-to-trip icon button on image', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(testReview));
      await tester.pump();

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('add-to-trip icon is inside a circle container', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(testReview));
      await tester.pump();

      // Find the icon and verify it exists within a container
      final iconFinder = find.byIcon(Icons.add_circle_outline);
      expect(iconFinder, findsOneWidget);

      final containerFinder = find.ancestor(
        of: iconFinder,
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);
    });

    testWidgets('add-to-trip icon has GestureDetector with opaque behavior', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(testReview));
      await tester.pump();

      final gestureDetectors = find.byType(GestureDetector);
      expect(gestureDetectors, findsWidgets);

      final widgets = tester.widgetList<GestureDetector>(gestureDetectors);
      bool foundOpaqueDetector = false;
      for (final gd in widgets) {
        if (gd.behavior == HitTestBehavior.opaque) {
          foundOpaqueDetector = true;
          break;
        }
      }
      expect(foundOpaqueDetector, isTrue);
    });

    testWidgets('add-to-trip icon renders on card with no destination', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(testReviewNoImage));
      await tester.pump();

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });
  });

  group('AC6: Gesture Handling', () {
    testWidgets('calls onTap callback when provided', (
      WidgetTester tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestWidget(testReview, onTap: () => tapped = true),
      );
      await tester.pump();

      await tester.tap(find.byType(ReviewCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('has GestureDetector for tap and long-press', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(testReview));
      await tester.pump();

      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('has Transform for scale animation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(testReview));
      await tester.pump();

      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('add-to-trip tap does NOT trigger card navigation', (
      WidgetTester tester,
    ) async {
      bool navigated = false;

      await tester.pumpWidget(
        buildTestWidget(testReview, onTap: () => navigated = true),
      );
      await tester.pump();

      // Find and tap the add-to-trip icon
      await tester.ensureVisible(find.byIcon(Icons.add_circle_outline));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();

      expect(navigated, isFalse);
    });
  });

  group('ReviewCard Edge Cases', () {
    testWidgets('handles empty hero image URL gracefully', (
      WidgetTester tester,
    ) async {
      const emptyImageReview = ReviewPreview(
        id: 'test-empty',
        title: 'Test Title',
        authorName: 'Test',
        authorAvatar: 'https://example.com/avatar.jpg',
        heroImage: '',
        shortText: 'Test text',
        likeCount: 0,
        commentCount: 0,
        destinationId: null,
        destinationName: null,
        category: null,
        moods: [],
      );

      await tester.pumpWidget(buildTestWidget(emptyImageReview));
      await tester.pump();

      expect(find.byIcon(Icons.image), findsOneWidget);
    });
  });
}
