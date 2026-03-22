import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/destination/data/repositories/destination_repository.dart';
import 'package:tour_vn/features/destination/domain/entities/destination.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';
import 'package:tour_vn/features/home/presentation/providers/location_search_provider.dart';
import 'package:tour_vn/features/review/data/repositories/review_repository.dart'
    show ReviewRepository;
import 'package:tour_vn/features/review/domain/entities/review.dart';

class FakeDestinationRepository extends DestinationRepository {
  FakeDestinationRepository() : super(firestore: FakeFirebaseFirestore());

  final destinations = const [
    Destination(
      id: 'da-nang',
      name: 'Đà Nẵng',
      heroImage: 'https://example.com/da-nang.jpg',
      description: 'City',
      postCount: 12,
    ),
    Destination(
      id: 'hoi-an',
      name: 'Hội An',
      heroImage: 'https://example.com/hoi-an.jpg',
      description: 'Ancient town',
      postCount: 8,
    ),
  ];

  final locations = const [
    Location(
      id: 'loc-1',
      destinationId: 'da-nang',
      destinationName: 'Đà Nẵng',
      name: 'Bánh mì Đà Nẵng',
      image: 'https://example.com/banh-mi.jpg',
      category: 'food',
      address: 'Đà Nẵng',
      searchKeywords: ['banh', 'banh mi', 'da nang'],
    ),
    Location(
      id: 'loc-2',
      destinationId: 'da-nang',
      destinationName: 'Đà Nẵng',
      name: 'Cầu Rồng',
      image: 'https://example.com/cau-rong.jpg',
      category: 'places',
      address: 'Đà Nẵng',
      searchKeywords: ['cau rong', 'da nang'],
    ),
    Location(
      id: 'loc-3',
      destinationId: 'hoi-an',
      destinationName: 'Hội An',
      name: 'Bánh mì Phượng',
      image: 'https://example.com/phuong.jpg',
      category: 'food',
      address: 'Hội An',
      searchKeywords: ['banh', 'banh mi', 'hoi an'],
    ),
    Location(
      id: 'loc-4',
      destinationId: 'da-nang',
      destinationName: 'Đà Nẵng',
      name: 'Cafe biển Mỹ Khê',
      image: 'https://example.com/cafe.jpg',
      category: 'cafe',
      address: 'Đà Nẵng',
      searchKeywords: ['cafe', 'bien', 'my khe'],
    ),
    Location(
      id: 'loc-5',
      destinationId: 'da-nang',
      destinationName: 'Đà Nẵng',
      name: 'Ăn vặt Sơn Trà',
      image: 'https://example.com/an-vat.jpg',
      category: 'food',
      address: 'Đà Nẵng',
      searchKeywords: ['an vat', 'son tra'],
    ),
    Location(
      id: 'loc-6',
      destinationId: 'da-nang',
      destinationName: 'Đà Nẵng',
      name: 'Bãi biển Đà Nẵng',
      image: 'https://example.com/bien.jpg',
      category: 'places',
      address: 'Đà Nẵng',
      searchKeywords: ['bien', 'da nang'],
    ),
  ];

  @override
  Future<List<Destination>> getAllDestinations() async => destinations;

  @override
  Future<List<Location>> searchLocations(String query) async {
    final normalized = query.toLowerCase();
    return locations
        .where(
          (location) =>
              location.name.toLowerCase().contains(normalized) ||
              (location.address ?? '').toLowerCase().contains(normalized) ||
              location.searchKeywords.any((keyword) => keyword.contains(normalized)),
        )
        .toList();
  }

  @override
  Future<List<Location>> getAllLocations() async => locations;
}

class FakeReviewRepository extends ReviewRepository {
  FakeReviewRepository() : super(firestore: FakeFirebaseFirestore());

  final reviews = [
    Review(
      id: 'review-1',
      heroImage: 'https://example.com/review.jpg',
      title: 'Bánh mì ngon ở Đà Nẵng',
      authorId: 'user-1',
      authorName: 'Tester',
      authorAvatar: 'https://example.com/avatar.jpg',
      fullText: 'Great food',
      createdAt: DateTime(2026, 1, 1),
      likeCount: 10,
      commentCount: 2,
      saveCount: 1,
      destinationId: 'da-nang',
      destinationName: 'Đà Nẵng',
    ),
  ];

  @override
  Future<List<Review>> searchReviewsByTitle(String prefix, {int limit = 20}) async {
    final normalized = prefix.toLowerCase();
    return reviews
        .where((review) => review.title.toLowerCase().contains(normalized))
        .take(limit)
        .toList();
  }

  @override
  Future<List<Review>> getAllReviews() async => reviews;
}

void main() {
  group('LocationSearchState', () {
    test('should have default empty state', () {
      const state = LocationSearchState();

      expect(state.query, equals(''));
      expect(state.destinations, isEmpty);
      expect(state.locations, isEmpty);
      expect(state.reviews, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('hasResults should return true when results exist', () {
      final state = LocationSearchState(
        locations: const [
          Location(
            id: 'loc-1',
            destinationId: 'da-nang',
            name: 'Test Location',
            image: 'https://example.com/image.jpg',
            category: 'food',
          ),
        ],
      );

      expect(state.hasResults, isTrue);
    });

    test('copyWith should clear errorMessage when passing null', () {
      const original = LocationSearchState(errorMessage: 'Error');

      final copied = original.copyWith(errorMessage: null);

      expect(copied.errorMessage, isNull);
    });
  });

  group('LocationSearchNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          destinationRepositoryProvider.overrideWithValue(
            FakeDestinationRepository(),
          ),
          reviewRepositoryProvider.overrideWithValue(FakeReviewRepository()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should have initial empty state', () {
      final state = container.read(locationSearchProvider);

      expect(state.query, equals(''));
      expect(state.destinations, isEmpty);
      expect(state.locations, isEmpty);
      expect(state.reviews, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('search with empty query should clear results', () async {
      final notifier = container.read(locationSearchProvider.notifier);

      await notifier.search('');

      final state = container.read(locationSearchProvider);
      expect(state.query, equals(''));
      expect(state.locations, isEmpty);
      expect(state.reviews, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('search should set loading state initially', () async {
      final notifier = container.read(locationSearchProvider.notifier);

      final searchFuture = notifier.search('banh');

      expect(container.read(locationSearchProvider).isLoading, isTrue);

      await searchFuture;
    });

    test('search should return matching results', () async {
      final notifier = container.read(locationSearchProvider.notifier);

      await notifier.search('banh');

      final state = container.read(locationSearchProvider);

      expect(state.locations, isNotEmpty);
      expect(
        state.locations.any(
          (location) => location.name.toLowerCase().contains('bánh'),
        ),
        isTrue,
      );
      expect(
        state.reviews.any(
          (review) => review.title.toLowerCase().contains('bánh'),
        ),
        isTrue,
      );
    });

    test('search should limit results to maximum 5 per category', () async {
      final notifier = container.read(locationSearchProvider.notifier);

      await notifier.search('da nang');

      final state = container.read(locationSearchProvider);

      expect(state.locations.length, lessThanOrEqualTo(5));
      expect(state.destinations.length, lessThanOrEqualTo(5));
      expect(state.reviews.length, lessThanOrEqualTo(5));
    });

    test('clear should reset to initial state', () async {
      final notifier = container.read(locationSearchProvider.notifier);

      await notifier.search('test');
      notifier.clear();

      final state = container.read(locationSearchProvider);
      expect(state.query, equals(''));
      expect(state.destinations, isEmpty);
      expect(state.locations, isEmpty);
      expect(state.reviews, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('search should update query', () async {
      final notifier = container.read(locationSearchProvider.notifier);

      await notifier.search('đà nẵng');

      expect(container.read(locationSearchProvider).query, equals('đà nẵng'));
    });

    test('search should match Vietnamese without diacritics', () async {
      final notifier = container.read(locationSearchProvider.notifier);

      await notifier.search('da nang');

      final state = container.read(locationSearchProvider);

      expect(
        state.locations.any(
          (location) =>
              location.destinationName?.toLowerCase().contains('đà nẵng') == true ||
              location.destinationId == 'da-nang',
        ),
        isTrue,
      );
    });

    test('search should clear previous error on new search', () async {
      final notifier = container.read(locationSearchProvider.notifier);

      await notifier.search('test1');
      await notifier.search('test2');

      expect(container.read(locationSearchProvider).errorMessage, isNull);
    });
  });

  group('destinationRepositoryProvider', () {
    test('should provide a DestinationRepository instance when overridden', () {
      final container = ProviderContainer(
        overrides: [
          destinationRepositoryProvider.overrideWithValue(
            FakeDestinationRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(destinationRepositoryProvider),
        isA<DestinationRepository>(),
      );
    });
  });
}
