import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/destination/data/repositories/destination_repository.dart';

void main() {
  late DestinationRepository repository;

  setUp(() {
    repository = DestinationRepository();
  });

  group('DestinationRepository Tests', () {
    test('getDestinationById return valid Ninh Binh destination', () async {
      final destination = await repository.getDestinationById('ninh-binh');

      expect(destination.id, 'ninh-binh');
      expect(destination.name, 'Ninh Bình');
      expect(destination.categories, containsAll(['Food', 'Places', 'Stay']));
      expect(destination.region, 'Miền Bắc');
      expect(destination.engagementCount, isNonZero);
    });

    test(
      'getLocationsByDestination for Ninh Binh returns 8+ locations',
      () async {
        final locations = await repository.getLocationsByDestination(
          'ninh-binh',
        );

        expect(locations.length, greaterThanOrEqualTo(8));

        // Verify category distribution
        final hasFood = locations.any((l) => l.category == 'food');
        final hasPlaces = locations.any((l) => l.category == 'places');
        final hasStay = locations.any((l) => l.category == 'stay');

        expect(hasFood, true);
        expect(hasPlaces, true);
        expect(hasStay, true);
      },
    );

    test('searchLocations matches diacritics', () async {
      // Test with exact spelling
      final resultsExact = await repository.searchLocations('Ninh Bình');
      expect(resultsExact.isNotEmpty, true, reason: 'Should match exact name');

      // Test without diacritics
      final resultsNoDiacritics = await repository.searchLocations('ninh binh');
      expect(
        resultsNoDiacritics.isNotEmpty,
        true,
        reason: 'Should match without diacritics',
      );
    });
  });
}
