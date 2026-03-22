import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/admin/presentation/providers/admin_category_provider.dart';
import 'package:tour_vn/features/admin/presentation/screens/manage_reviews_screen.dart';
import 'package:tour_vn/features/admin/presentation/widgets/review_form_dialog.dart';
import 'package:tour_vn/features/destination/data/repositories/destination_repository.dart';
import 'package:tour_vn/features/destination/domain/entities/category.dart';
import 'package:tour_vn/features/destination/domain/entities/destination.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';
import 'package:tour_vn/features/destination/presentation/providers/destination_provider.dart';
import 'package:tour_vn/features/review/data/repositories/review_repository.dart';
import 'package:tour_vn/features/review/domain/entities/review.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

class FakeReviewRepository implements ReviewRepository {
  FakeReviewRepository({List<Review>? reviews})
    : _reviews = reviews ?? <Review>[];

  final List<Review> _reviews;

  @override
  Future<List<Review>> getAllReviews() async => List<Review>.from(_reviews);

  @override
  Future<Review> getReviewById(String id) async {
    return _reviews.firstWhere((review) => review.id == id);
  }

  @override
  Future<void> createReview(Review review) async {
    _reviews.add(review);
  }

  @override
  Future<void> updateReview(Review review) async {
    final index = _reviews.indexWhere((item) => item.id == review.id);
    if (index != -1) {
      _reviews[index] = review;
    }
  }

  @override
  Future<void> deleteReview(String id) async {
    _reviews.removeWhere((review) => review.id == id);
  }

  @override
  Future<void> deleteReviewBatch(List<String> ids) async {
    _reviews.removeWhere((review) => ids.contains(review.id));
  }

  @override
  Future<List<Review>> getReviewsByStatus(
    String status, {
    int limit = 50,
  }) async {
    return _reviews
        .where((review) => review.status == status)
        .take(limit)
        .toList();
  }

  @override
  Future<({List<Review> items, DocumentSnapshot? lastDoc})>
  getReviewsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? destinationId,
  }) async {
    final filtered = destinationId == null
        ? _reviews
        : _reviews
              .where((review) => review.destinationId == destinationId)
              .toList();
    return (items: filtered.take(limit).toList(), lastDoc: null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDestinationRepository implements DestinationRepository {
  FakeDestinationRepository({
    List<Location>? locations,
    List<Destination>? destinations,
  }) : _locations = locations ?? <Location>[],
       _destinations = destinations ?? <Destination>[];

  final List<Location> _locations;
  final List<Destination> _destinations;

  @override
  Future<List<Location>> getAllLocations() async => _locations;

  @override
  Future<List<Destination>> getAllDestinations() async => _destinations;

  @override
  Future<({List<Destination> items, DocumentSnapshot? lastDoc})>
  getDestinationsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    return (items: _destinations.take(limit).toList(), lastDoc: null);
  }

  @override
  Future<({List<Location> items, DocumentSnapshot? lastDoc})>
  getLocationsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? destinationId,
  }) async {
    final filtered = destinationId == null
        ? _locations
        : _locations
              .where((location) => location.destinationId == destinationId)
              .toList();
    return (items: filtered.take(limit).toList(), lastDoc: null);
  }

  @override
  Future<int> fixInconsistentDestinationIds() async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  final mockLocations = [
    const Location(
      id: 'loc-1',
      destinationId: 'da-lat',
      name: 'Hồ Xuân Hương',
      image: 'https://via.placeholder.com/150',
      category: 'places',
    ),
    const Location(
      id: 'loc-2',
      destinationId: 'ninh-binh',
      name: 'Tràng An',
      image: 'https://via.placeholder.com/150',
      category: 'places',
    ),
  ];

  final mockDestinations = [
    const Destination(
      id: 'da-lat',
      name: 'Đà Lạt',
      description: 'City of flowers',
      heroImage: 'https://via.placeholder.com/150',
      engagementCount: 10,
    ),
    const Destination(
      id: 'ninh-binh',
      name: 'Ninh Bình',
      description: 'Heritage site',
      heroImage: 'https://via.placeholder.com/150',
      engagementCount: 5,
    ),
  ];

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
      relatedLocationIds: const ['loc-1'],
      destinationId: 'da-lat',
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
      relatedLocationIds: const ['loc-2'],
      destinationId: 'ninh-binh',
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
      relatedLocationIds: const ['loc-2'],
      destinationId: 'ninh-binh',
      destinationName: 'Ninh Bình',
      category: 'stay',
    ),
  ];

  Widget createWidgetUnderTest({List<Review>? reviews}) {
    final fakeReviewRepository = FakeReviewRepository(
      reviews: reviews ?? List<Review>.from(mockReviews),
    );
    final fakeDestinationRepository = FakeDestinationRepository(
      locations: List<Location>.from(mockLocations),
      destinations: List<Destination>.from(mockDestinations),
    );

    return ProviderScope(
      overrides: [
        reviewRepositoryProvider.overrideWithValue(fakeReviewRepository),
        destinationRepositoryProvider.overrideWithValue(
          fakeDestinationRepository,
        ),
        activeCategoriesProvider.overrideWith(
          (_) async => Category.defaultCategories.take(3).toList(),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1600, 1200)),
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

    await tester.enterText(
      find.widgetWithText(TextField, 'Tìm theo tiêu đề, tác giả...'),
      'cà phê',
    );
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

    expect(find.byType(Checkbox), findsNWidgets(4));
  });

  testWidgets('Selecting items should show batch action bar', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Bỏ chọn'), findsNothing);

    final checkboxes = find.byType(Checkbox);
    await tester.tap(checkboxes.at(1));
    await tester.pumpAndSettle();

    expect(find.textContaining('Đã chọn'), findsOneWidget);
    expect(find.text('Bỏ chọn'), findsOneWidget);
    expect(find.text('Xóa'), findsWidgets);
  });

  testWidgets('Clear selection should hide batch action bar', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final checkboxes = find.byType(Checkbox);
    await tester.tap(checkboxes.at(1));
    await tester.pumpAndSettle();

    expect(find.text('Bỏ chọn'), findsOneWidget);

    await tester.tap(find.text('Bỏ chọn'));
    await tester.pumpAndSettle();

    expect(find.text('Bỏ chọn'), findsNothing);
  });

  testWidgets('Batch delete should show confirmation dialog', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final checkboxes = find.byType(Checkbox);
    await tester.tap(checkboxes.at(1));
    await tester.pumpAndSettle();

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

    await tester.tap(find.widgetWithText(FilterChip, 'Ninh Bình'));
    await tester.pumpAndSettle();

    expect(find.text('Xóa bộ lọc'), findsOneWidget);

    await tester.tap(find.text('Xóa bộ lọc'));
    await tester.pumpAndSettle();

    expect(find.text('Quán cà phê Đà Lạt'), findsOneWidget);
    expect(find.text('Tràng An Ninh Bình'), findsOneWidget);
    expect(find.text('Homestay giữa núi'), findsOneWidget);
  });
}
