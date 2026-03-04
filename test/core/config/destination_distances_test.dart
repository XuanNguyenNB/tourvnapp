import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/core/config/destination_distances.dart';

void main() {
  group('DestinationDistances', () {
    group('getDistance', () {
      test('should return distance for known destination pair', () {
        final distance = DestinationDistances.getDistance('da-nang', 'hoi-an');

        expect(distance, isNotNull);
        expect(distance!.distanceKm, 30);
        expect(distance.travelTimeMin, 45);
      });

      test('should return distance with bidirectional lookup', () {
        // Test reverse direction
        final distance = DestinationDistances.getDistance('hoi-an', 'da-nang');

        expect(distance, isNotNull);
        expect(distance!.distanceKm, 30);
      });

      test('should return null for same destination', () {
        final distance = DestinationDistances.getDistance('da-nang', 'da-nang');

        expect(distance, isNull);
      });

      test('should return null for unknown destination pair', () {
        final distance = DestinationDistances.getDistance(
          'unknown-1',
          'unknown-2',
        );

        expect(distance, isNull);
      });

      test('should return null when only one destination is known', () {
        final distance = DestinationDistances.getDistance(
          'da-nang',
          'unknown-city',
        );

        expect(distance, isNull);
      });
    });

    group('areAdjacent', () {
      test('should return true for adjacent destinations (<50km)', () {
        // Đà Nẵng - Hội An: 30km
        expect(DestinationDistances.areAdjacent('da-nang', 'hoi-an'), true);
        expect(
          DestinationDistances.areAdjacent('da-nang', 'ba-na-hills'),
          true,
        );
      });

      test('should return false for non-adjacent destinations', () {
        // Đà Nẵng - Huế: 100km
        expect(DestinationDistances.areAdjacent('da-nang', 'hue'), false);
      });

      test('should return false for unknown destinations', () {
        expect(DestinationDistances.areAdjacent('unknown', 'da-nang'), false);
      });
    });

    group('areDifferent', () {
      test('should return true for different destinations (50-200km)', () {
        // Đà Nẵng - Huế: 100km
        expect(DestinationDistances.areDifferent('da-nang', 'hue'), true);

        // Hà Nội - Ninh Bình: 95km
        expect(DestinationDistances.areDifferent('ha-noi', 'ninh-binh'), true);
      });

      test('should return false for adjacent destinations', () {
        // Đà Nẵng - Hội An: 30km
        expect(DestinationDistances.areDifferent('da-nang', 'hoi-an'), false);
      });

      test('should return false for distant destinations', () {
        // Đà Nẵng - Quy Nhơn: 300km
        expect(DestinationDistances.areDifferent('da-nang', 'quy-nhon'), false);
      });
    });

    group('areDistant', () {
      test('should return true for distant destinations (>200km)', () {
        // Đà Nẵng - Quy Nhơn: 300km
        expect(DestinationDistances.areDistant('da-nang', 'quy-nhon'), true);

        // Hà Nội - Sa Pa: 320km
        expect(DestinationDistances.areDistant('ha-noi', 'sapa'), true);
      });

      test('should return false for closer destinations', () {
        // Đà Nẵng - Huế: 100km
        expect(DestinationDistances.areDistant('da-nang', 'hue'), false);
      });

      test('should return false for unknown destinations', () {
        expect(DestinationDistances.areDistant('unknown', 'da-nang'), false);
      });
    });

    group('thresholds', () {
      test('should have correct threshold values', () {
        expect(DestinationDistances.adjacentThreshold, 50);
        expect(DestinationDistances.differentThreshold, 200);
      });
    });

    group('knownDestinations', () {
      test('should return non-empty set', () {
        final destinations = DestinationDistances.knownDestinations;

        expect(destinations, isNotEmpty);
        expect(destinations.contains('da-nang'), true);
        expect(destinations.contains('ha-noi'), true);
        expect(destinations.contains('ho-chi-minh'), true);
      });
    });

    group('real-world distance data', () {
      test('Central Vietnam destinations', () {
        // Đà Nẵng - Huế: ~100km
        final daNangHue = DestinationDistances.getDistance('da-nang', 'hue');
        expect(daNangHue!.distanceKm, 100);

        // Đà Nẵng - Hội An: ~30km
        final daNangHoiAn = DestinationDistances.getDistance(
          'da-nang',
          'hoi-an',
        );
        expect(daNangHoiAn!.distanceKm, 30);
      });

      test('Northern Vietnam destinations', () {
        // Hà Nội - Hạ Long: ~170km
        final haNoiHaLong = DestinationDistances.getDistance(
          'ha-noi',
          'ha-long',
        );
        expect(haNoiHaLong!.distanceKm, 170);

        // Hà Nội - Sa Pa: ~320km
        final haNoiSapa = DestinationDistances.getDistance('ha-noi', 'sapa');
        expect(haNoiSapa!.distanceKm, 320);
      });

      test('Southern Vietnam destinations', () {
        // HCM - Vũng Tàu: ~125km
        final hcmVungTau = DestinationDistances.getDistance(
          'ho-chi-minh',
          'vung-tau',
        );
        expect(hcmVungTau!.distanceKm, 125);

        // HCM - Đà Lạt: ~310km
        final hcmDaLat = DestinationDistances.getDistance(
          'ho-chi-minh',
          'da-lat',
        );
        expect(hcmDaLat!.distanceKm, 310);
      });
    });
  });
}
