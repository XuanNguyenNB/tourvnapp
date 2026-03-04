import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/core/utils/distance_calculator.dart';

void main() {
  group('DistanceCalculator', () {
    group('calculate', () {
      test('should return 0 for same coordinates', () {
        final distance = DistanceCalculator.calculate(
          lat1: 10.762622,
          lng1: 106.660172,
          lat2: 10.762622,
          lng2: 106.660172,
        );

        expect(distance, equals(0.0));
      });

      test(
        'should calculate distance correctly between Ho Chi Minh and Ha Noi',
        () {
          // Ho Chi Minh City: 10.8231° N, 106.6297° E
          // Ha Noi: 21.0285° N, 105.8542° E
          // Approximate distance: ~1,150 km

          final distance = DistanceCalculator.calculate(
            lat1: 10.8231,
            lng1: 106.6297,
            lat2: 21.0285,
            lng2: 105.8542,
          );

          // Allow 5% margin of error
          expect(distance, greaterThan(1100000)); // > 1100 km
          expect(distance, lessThan(1200000)); // < 1200 km
        },
      );

      test('should calculate short distance correctly', () {
        // Two points approximately 1km apart in Ho Chi Minh City
        // Ben Thanh Market: 10.772461, 106.698059
        // A point ~1km away: 10.781461, 106.698059 (roughly 1km north)

        final distance = DistanceCalculator.calculate(
          lat1: 10.772461,
          lng1: 106.698059,
          lat2: 10.781461,
          lng2: 106.698059,
        );

        // Should be approximately 1000m (1km)
        expect(distance, greaterThan(900)); // > 900m
        expect(distance, lessThan(1100)); // < 1100m
      });

      test('should handle negative coordinates', () {
        // Sydney, Australia: -33.8688° S, 151.2093° E
        // Melbourne, Australia: -37.8136° S, 144.9631° E
        // Approximate distance: ~713 km

        final distance = DistanceCalculator.calculate(
          lat1: -33.8688,
          lng1: 151.2093,
          lat2: -37.8136,
          lng2: 144.9631,
        );

        // Allow 5% margin of error
        expect(distance, greaterThan(680000)); // > 680 km
        expect(distance, lessThan(750000)); // < 750 km
      });

      test('should handle coordinates crossing prime meridian', () {
        // London: 51.5074° N, -0.1278° W
        // Paris: 48.8566° N, 2.3522° E
        // Approximate distance: ~343 km

        final distance = DistanceCalculator.calculate(
          lat1: 51.5074,
          lng1: -0.1278,
          lat2: 48.8566,
          lng2: 2.3522,
        );

        // Allow 5% margin of error
        expect(distance, greaterThan(325000)); // > 325 km
        expect(distance, lessThan(365000)); // < 365 km
      });
    });

    group('format', () {
      test('should format meters correctly for distance < 1km', () {
        expect(DistanceCalculator.format(500), equals('500m'));
        expect(DistanceCalculator.format(100), equals('100m'));
        expect(DistanceCalculator.format(999), equals('999m'));
        expect(DistanceCalculator.format(50.6), equals('51m')); // rounds
      });

      test('should format kilometers correctly for distance >= 1km', () {
        expect(DistanceCalculator.format(1000), equals('1.0km'));
        expect(DistanceCalculator.format(1500), equals('1.5km'));
        expect(DistanceCalculator.format(2345), equals('2.3km'));
        expect(DistanceCalculator.format(9999), equals('10.0km'));
      });

      test('should format large distances without decimal', () {
        expect(DistanceCalculator.format(10000), equals('10km'));
        expect(DistanceCalculator.format(15600), equals('16km'));
        expect(DistanceCalculator.format(100000), equals('100km'));
      });

      test('should handle 0 meters', () {
        expect(DistanceCalculator.format(0), equals('0m'));
      });
    });

    group('calculateAndFormat', () {
      test('should return formatted distance for valid coordinates', () {
        final result = DistanceCalculator.calculateAndFormat(
          userLat: 10.772461,
          userLng: 106.698059,
          locationLat: 10.781461,
          locationLng: 106.698059,
        );

        expect(result, isNotNull);
        expect(result, contains('m')); // Should be in meters
      });

      test('should return null if user lat is null', () {
        final result = DistanceCalculator.calculateAndFormat(
          userLat: null,
          userLng: 106.698059,
          locationLat: 10.781461,
          locationLng: 106.698059,
        );

        expect(result, isNull);
      });

      test('should return null if user lng is null', () {
        final result = DistanceCalculator.calculateAndFormat(
          userLat: 10.772461,
          userLng: null,
          locationLat: 10.781461,
          locationLng: 106.698059,
        );

        expect(result, isNull);
      });

      test('should return null if location lat is null', () {
        final result = DistanceCalculator.calculateAndFormat(
          userLat: 10.772461,
          userLng: 106.698059,
          locationLat: null,
          locationLng: 106.698059,
        );

        expect(result, isNull);
      });

      test('should return null if location lng is null', () {
        final result = DistanceCalculator.calculateAndFormat(
          userLat: 10.772461,
          userLng: 106.698059,
          locationLat: 10.781461,
          locationLng: null,
        );

        expect(result, isNull);
      });
    });

    group('isWithinRadius', () {
      test('should return true when within radius', () {
        final isWithin = DistanceCalculator.isWithinRadius(
          userLat: 10.772461,
          userLng: 106.698059,
          locationLat: 10.773461, // ~100m away
          locationLng: 106.698059,
          radiusMeters: 500,
        );

        expect(isWithin, isTrue);
      });

      test('should return false when outside radius', () {
        final isWithin = DistanceCalculator.isWithinRadius(
          userLat: 10.772461,
          userLng: 106.698059,
          locationLat: 10.782461, // ~1.1km away
          locationLng: 106.698059,
          radiusMeters: 500,
        );

        expect(isWithin, isFalse);
      });

      test('should return true when distance is less than radius', () {
        // ~1km away (approximately 1000m)
        final isWithin = DistanceCalculator.isWithinRadius(
          userLat: 10.772461,
          userLng: 106.698059,
          locationLat: 10.781461,
          locationLng: 106.698059,
          radiusMeters:
              1100, // Use slightly more than 1km to account for precision
        );

        expect(isWithin, isTrue);
      });

      test('should return false for null coordinates', () {
        final isWithin = DistanceCalculator.isWithinRadius(
          userLat: null,
          userLng: 106.698059,
          locationLat: 10.781461,
          locationLng: 106.698059,
          radiusMeters: 1000,
        );

        expect(isWithin, isFalse);
      });
    });
  });
}
