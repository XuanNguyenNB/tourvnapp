import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/features/admin/presentation/screens/manage_reviews_screen.dart';
import 'package:tour_vn/features/review/domain/entities/review.dart';
import 'package:tour_vn/features/review/data/repositories/review_repository.dart';
import 'package:tour_vn/features/admin/presentation/widgets/review_form_dialog.dart';

/// Mock HTTP overrides for image loading
class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

/// Fake review repository that doesn't touch Firebase
class FakeReviewRepository implements ReviewRepository {
  final List<Review> _reviews;

  FakeReviewRepository({List<Review>? reviews}) : _reviews = reviews ?? [];

  @override
  Future<List<Review>> getAllReviews() async => List.from(_reviews);

  @override
  Future<Review> getReviewById(String id) async =>
      _reviews.firstWhere((r) => r.id == id);

  @override
  Future<void> createReview(Review review) async {
    _reviews.add(review);
  }

  @override
  Future<void> updateReview(Review review) async {
    final index = _reviews.indexWhere((r) => r.id == review.id);
    if (index != -1) _reviews[index] = review;
  }

  @override
  Future<void> deleteReview(String id) async {
    _reviews.removeWhere((r) => r.id == id);
  }

  // Stub remaining methods
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  final mockReviews = [
    Review(
      id: 'rev-1',
      heroImage: 'https://via.placeholder.com/150',
      title: 'Quán cà phê Đà Lạt',
      authorId: 'admin',
      authorName: 'Linh Nguyễn',
      authorAvatar: 'https://via.placeholder.com/50',
      fullText: 'Test review content',
      createdAt: DateTime(2026, 1, 1),
      likeCount: 100,
      commentCount: 10,
      saveCount: 20,
      destinationName: 'Đà Lạt',
      category: 'food',
    ),
    Review(
      id: 'rev-2',
      heroImage: 'https://via.placeholder.com/150',
      title: 'Tràng An Ninh Bình',
      authorId: 'admin',
      authorName: 'Mai Anh',
      authorAvatar: 'https://via.placeholder.com/50',
      fullText: 'Another test review content',
      createdAt: DateTime(2026, 1, 2),
      likeCount: 200,
      commentCount: 20,
      saveCount: 40,
      destinationName: 'Ninh Bình',
      category: 'places',
    ),
    Review(
      id: 'rev-3',
      heroImage: 'https://via.placeholder.com/150',
      title: 'Homestay giữa núi',
      authorId: 'admin',
      authorName: 'Thảo Vy',
      authorAvatar: 'https://via.placeholder.com/50',
      fullText: 'Homestay content',
      createdAt: DateTime(2026, 1, 3),
      likeCount: 50,
      commentCount: 5,
      saveCount: 10,
      destinationName: 'Ninh Bình',
      category: 'stay',
    ),
  ];

  Widget createWidgetUnderTest({List<Review>? reviews}) {
    final fakeRepo = FakeReviewRepository(
      reviews: reviews ?? List<Review>.from(mockReviews),
    );

    return ProviderScope(
      overrides: [reviewRepositoryProvider.overrideWithValue(fakeRepo)],
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: const ManageReviewsScreen(),
        ),
      ),
    );
  }

  testWidgets('Should display header and review rows', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Quản lý Bài viết'), findsOneWidget);
    expect(find.text('Quán cà phê Đà Lạt'), findsOneWidget);
    expect(find.text('Tràng An Ninh Bình'), findsOneWidget);
    expect(find.text('Homestay giữa núi'), findsOneWidget);
  });

  testWidgets('Should display search field', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Tìm theo tiêu đề, tác giả...'),
      findsOneWidget,
    );
  });

  testWidgets('Search should filter reviews by title', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Type search query
    await tester.enterText(
      find.widgetWithText(TextField, 'Tìm theo tiêu đề, tác giả...'),
      'cà phê',
    );
    // Wait for debounce
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Quán cà phê Đà Lạt'), findsOneWidget);
    expect(find.text('Tràng An Ninh Bình'), findsNothing);
    expect(find.text('Homestay giữa núi'), findsNothing);
  });

  testWidgets('Search should filter reviews by author name', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Tìm theo tiêu đề, tác giả...'),
      'Mai Anh',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Tràng An Ninh Bình'), findsOneWidget);
    expect(find.text('Quán cà phê Đà Lạt'), findsNothing);
  });

  testWidgets('Should display filter chips for destinations', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilterChip, 'Đà Lạt'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Ninh Bình'), findsOneWidget);
  });

  testWidgets('Tapping destination filter chip should filter reviews', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap Ninh Bình filter
    await tester.tap(find.widgetWithText(FilterChip, 'Ninh Bình'));
    await tester.pumpAndSettle();

    expect(find.text('Tràng An Ninh Bình'), findsOneWidget);
    expect(find.text('Homestay giữa núi'), findsOneWidget);
    expect(find.text('Quán cà phê Đà Lạt'), findsNothing);
  });

  testWidgets('Should display category filter chips', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilterChip, '🍜 Ăn uống'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, '📸 Điểm đến'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, '🏨 Lưu trú'), findsOneWidget);
  });

  testWidgets('Should show checkboxes for batch selection', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Header checkbox + 3 row checkboxes
    expect(find.byType(Checkbox), findsNWidgets(4));
  });

  testWidgets('Selecting items should show batch action bar', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Initially no batch bar
    expect(find.text('Bỏ chọn'), findsNothing);

    // Tap first row checkbox (skip header = index 0)
    final checkboxes = find.byType(Checkbox);
    await tester.tap(checkboxes.at(1));
    await tester.pumpAndSettle();

    // Batch bar should appear
    expect(find.textContaining('Đã chọn'), findsOneWidget);
    expect(find.text('Bỏ chọn'), findsOneWidget);
    expect(find.text('Xóa'), findsOneWidget);
  });

  testWidgets('Clear selection should hide batch action bar', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Select an item
    final checkboxes = find.byType(Checkbox);
    await tester.tap(checkboxes.at(1));
    await tester.pumpAndSettle();

    expect(find.text('Bỏ chọn'), findsOneWidget);

    // Clear selection
    await tester.tap(find.text('Bỏ chọn'));
    await tester.pumpAndSettle();

    expect(find.text('Bỏ chọn'), findsNothing);
  });

  testWidgets('Batch delete should show confirmation dialog', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Select an item
    final checkboxes = find.byType(Checkbox);
    await tester.tap(checkboxes.at(1));
    await tester.pumpAndSettle();

    // Tap delete button in batch bar
    await tester.tap(find.byKey(const Key('batch_delete_button')));
    await tester.pumpAndSettle();

    expect(find.text('Xóa hàng loạt?'), findsOneWidget);
  });

  testWidgets('Should show empty state when no reviews', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(reviews: []));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có bài viết nào'), findsOneWidget);
  });

  testWidgets('Should open form dialog when tapping add button', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thêm bài viết'));
    await tester.pumpAndSettle();

    // ReviewFormDialog should appear
    expect(find.byType(ReviewFormDialog), findsOneWidget);
  });

  testWidgets('Delete single review should show confirmation', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Xóa').first);
    await tester.pumpAndSettle();

    expect(find.text('Xóa Bài viết?'), findsOneWidget);
  });

  testWidgets('Clear filters button should reset all filters', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Apply a filter
    await tester.tap(find.widgetWithText(FilterChip, 'Ninh Bình'));
    await tester.pumpAndSettle();

    // Clear filter should be visible
    expect(find.text('Xóa bộ lọc'), findsOneWidget);

    await tester.tap(find.text('Xóa bộ lọc'));
    await tester.pumpAndSettle();

    // All reviews should be visible again
    expect(find.text('Quán cà phê Đà Lạt'), findsOneWidget);
    expect(find.text('Tràng An Ninh Bình'), findsOneWidget);
    expect(find.text('Homestay giữa núi'), findsOneWidget);
  });
}
