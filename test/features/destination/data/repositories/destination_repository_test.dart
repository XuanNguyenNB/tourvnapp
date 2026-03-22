import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/destination/data/repositories/destination_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late DestinationRepository repository;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    repository = DestinationRepository(firestore: firestore);

    await firestore.collection('destinations').doc('ninh-binh').set({
      'id': 'ninh-binh',
      'name': 'Ninh Bình',
      'heroImage': 'https://example.com/ninh-binh.jpg',
      'description': 'Di sản thiên nhiên và văn hóa.',
      'engagementCount': 120,
      'postCount': 8,
      'locationCount': 2,
      'countryCode': 'VN',
      'status': 'published',
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
    });

    await firestore.collection('locations').doc('loc-food').set({
      'id': 'loc-food',
      'destinationId': 'ninh-binh',
      'name': 'Bún mọc Kim Sơn',
      'image': 'https://example.com/food.jpg',
      'category': 'food',
      'searchKeywords': ['bun moc kim son', 'bún mọc kim sơn', 'ninh binh'],
      'status': 'published',
    });

    await firestore.collection('locations').doc('loc-place').set({
      'id': 'loc-place',
      'destinationId': 'ninh-binh',
      'name': 'Tràng An',
      'image': 'https://example.com/place.jpg',
      'category': 'places',
      'searchKeywords': ['trang an', 'tràng an', 'ninh binh'],
      'status': 'published',
    });
  });

  group('DestinationRepository', () {
    test(
      'getDestinationById returns destination fields from Firestore',
      () async {
        final destination = await repository.getDestinationById('ninh-binh');

        expect(destination.id, 'ninh-binh');
        expect(destination.name, 'Ninh Bình');
        expect(destination.countryCode, 'VN');
        expect(destination.locationCount, 2);
        expect(destination.engagementCount, 120);
      },
    );

    test('getLocationsByDestination returns matching locations', () async {
      final locations = await repository.getLocationsByDestination('ninh-binh');

      expect(locations, hasLength(2));
      expect(locations.any((location) => location.category == 'food'), isTrue);
      expect(
        locations.any((location) => location.category == 'places'),
        isTrue,
      );
    });

    test(
      'searchLocations matches both diacritics and non-diacritics',
      () async {
        final exactResults = await repository.searchLocations('Tràng An');
        final normalizedResults = await repository.searchLocations('ninh binh');

        expect(exactResults, isNotEmpty);
        expect(normalizedResults, isNotEmpty);
      },
    );
  });
}
