import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/admin/presentation/screens/manage_destinations_screen.dart';
import 'package:tour_vn/features/destination/data/repositories/destination_repository.dart';
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

class FakeDestinationRepository implements DestinationRepository {
  FakeDestinationRepository({
    List<Destination>? destinations,
    List<Location>? locations,
  }) : destinations = destinations ?? <Destination>[],
       locations = locations ?? <Location>[];

  final List<Destination> destinations;
  final List<Location> locations;

  @override
  Future<void> createDestination(Destination destination) async {
    destinations.add(destination);
  }

  @override
  Future<void> deleteDestination(String id) async {
    destinations.removeWhere((destination) => destination.id == id);
  }

  @override
  Future<List<Destination>> getAllDestinations() async => destinations;

  @override
  Future<Destination> getDestinationById(String id) async {
    return destinations.firstWhere((destination) => destination.id == id);
  }

  @override
  Future<List<Destination>> getDestinationsByStatus(
    String status, {
    int limit = 50,
  }) async {
    return destinations
        .where((destination) => destination.status == status)
        .take(limit)
        .toList();
  }

  @override
  Future<List<Location>> getAllLocations() async => locations;

  @override
  Future<List<Location>> getLocationsByDestination(String destinationId) async {
    return locations
        .where((location) => location.destinationId == destinationId)
        .toList();
  }

  @override
  Future<List<Location>> getLocationsByStatus(
    String status, {
    int limit = 50,
  }) async {
    return locations
        .where((location) => location.status == status)
        .take(limit)
        .toList();
  }

  @override
  Future<({List<Destination> items, DocumentSnapshot? lastDoc})>
  getDestinationsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    return (items: destinations.take(limit).toList(), lastDoc: null);
  }

  @override
  Future<({List<Location> items, DocumentSnapshot? lastDoc})>
  getLocationsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? destinationId,
  }) async {
    final filtered = destinationId == null
        ? locations
        : locations
              .where((location) => location.destinationId == destinationId)
              .toList();
    return (items: filtered.take(limit).toList(), lastDoc: null);
  }

  @override
  Future<void> updateDestination(Destination destination) async {
    final index = destinations.indexWhere((item) => item.id == destination.id);
    if (index != -1) {
      destinations[index] = destination;
    }
  }

  @override
  Future<int> fixInconsistentDestinationIds() async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeReviewRepository implements ReviewRepository {
  FakeReviewRepository({List<Review>? reviews})
    : reviews = reviews ?? <Review>[];

  final List<Review> reviews;

  @override
  Future<List<Review>> getAllReviews() async => reviews;

  @override
  Future<List<Review>> getReviewsByStatus(
    String status, {
    int limit = 50,
  }) async {
    return reviews
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
        ? reviews
        : reviews
              .where((review) => review.destinationId == destinationId)
              .toList();
    return (items: filtered.take(limit).toList(), lastDoc: null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeDestinationRepository fakeDestinationRepository;
  late FakeReviewRepository fakeReviewRepository;

  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  setUp(() {
    fakeDestinationRepository = FakeDestinationRepository(
      destinations: [
        const Destination(
          id: 'test-1',
          name: 'Test Destination 1',
          heroImage: 'https://via.placeholder.com/150',
          description: 'Desc 1',
          engagementCount: 100,
          postCount: 50,
          countryCode: 'VN',
        ),
      ],
      locations: const [
        Location(
          id: 'loc-1',
          destinationId: 'test-1',
          name: 'Location 1',
          image: 'https://via.placeholder.com/150',
          category: 'places',
        ),
      ],
    );
    fakeReviewRepository = FakeReviewRepository(
      reviews: [
        Review(
          id: 'review-1',
          heroImage: 'https://via.placeholder.com/150',
          title: 'Review 1',
          authorId: 'admin',
          authorName: 'Admin',
          authorAvatar: '',
          fullText: 'Test review',
          createdAt: DateTime(2026, 1, 1),
          likeCount: 10,
          commentCount: 2,
          saveCount: 1,
          destinationId: 'test-1',
          destinationName: 'Test Destination 1',
        ),
      ],
    );
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        destinationRepositoryProvider.overrideWithValue(
          fakeDestinationRepository,
        ),
        reviewRepositoryProvider.overrideWithValue(fakeReviewRepository),
      ],
      child: const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(1400, 1000)),
          child: ManageDestinationsScreen(),
        ),
      ),
    );
  }

  testWidgets('Should display list of destinations', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Quản lý Điểm đến'), findsOneWidget);
    expect(find.text('Test Destination 1'), findsOneWidget);
    expect(find.text('Desc 1'), findsOneWidget);
  });

  testWidgets('Should open Add dialog and add new destination', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thêm điểm đến'));
    await tester.pumpAndSettle();

    expect(find.text('Thêm Điểm đến'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên điểm đến'),
      'Test Destination 2',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ảnh bìa (URL)'),
      'https://via.placeholder.com/150',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mô tả'),
      'Desc 2',
    );

    await tester.ensureVisible(find.text('Thêm').last);
    await tester.tap(find.text('Thêm').last);
    await tester.pumpAndSettle();

    expect(fakeDestinationRepository.destinations.length, 2);
    expect(find.text('Test Destination 2'), findsOneWidget);
  });

  testWidgets('Should open Edit dialog and update destination', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sửa'));
    await tester.pumpAndSettle();

    expect(find.text('Sửa Điểm đến'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên điểm đến'),
      'Updated Destination 1',
    );

    await tester.ensureVisible(find.text('Lưu').last);
    await tester.tap(find.text('Lưu').last);
    await tester.pumpAndSettle();

    expect(
      fakeDestinationRepository.destinations.first.name,
      'Updated Destination 1',
    );
    expect(find.text('Updated Destination 1'), findsOneWidget);
  });

  testWidgets('Should delete destination on confirmation', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Xóa'));
    await tester.pumpAndSettle();

    expect(find.text('Xóa Điểm đến?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Xóa'));
    await tester.pumpAndSettle();

    expect(fakeDestinationRepository.destinations, isEmpty);
    expect(find.text('Chưa có điểm đến nào'), findsOneWidget);
  });
}
