import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/destination_distance.dart';

void main() {
  group('DestinationDistance', () {
    test('should create with required fields', () {
      const distance = DestinationDistance(distanceKm: 100, travelTimeMin: 120);

      expect(distance.distanceKm, 100);
      expect(distance.travelTimeMin, 120);
    });

    group('formattedTravelTime', () {
      test('should format minutes only when under 60', () {
        const distance = DestinationDistance(distanceKm: 30, travelTimeMin: 45);

        expect(distance.formattedTravelTime, '45 phút');
      });

      test('should format hours only when exact hours', () {
        const distance = DestinationDistance(
          distanceKm: 100,
          travelTimeMin: 120,
        );

        expect(distance.formattedTravelTime, '2 giờ');
      });

      test('should format hours and minutes', () {
        const distance = DestinationDistance(
          distanceKm: 130,
          travelTimeMin: 150,
        );

        expect(distance.formattedTravelTime, '2 giờ 30 phút');
      });
    });

    group('formattedDistance', () {
      test('should format kilometers', () {
        const distance = DestinationDistance(
          distanceKm: 100,
          travelTimeMin: 120,
        );

        expect(distance.formattedDistance, '100 km');
      });

      test('should format meters when under 1km', () {
        const distance = DestinationDistance(
          distanceKm: 0.5,
          travelTimeMin: 10,
        );

        expect(distance.formattedDistance, '500 m');
      });

      test('should round distance', () {
        const distance = DestinationDistance(
          distanceKm: 99.7,
          travelTimeMin: 120,
        );

        expect(distance.formattedDistance, '100 km');
      });
    });

    test('fromJson should parse correctly', () {
      final json = {'distanceKm': 100.5, 'travelTimeMin': 120};

      final distance = DestinationDistance.fromJson(json);

      expect(distance.distanceKm, 100.5);
      expect(distance.travelTimeMin, 120);
    });

    test('toJson should serialize correctly', () {
      const distance = DestinationDistance(distanceKm: 100, travelTimeMin: 120);

      final json = distance.toJson();

      expect(json['distanceKm'], 100);
      expect(json['travelTimeMin'], 120);
    });

    test('equality should work correctly', () {
      const distance1 = DestinationDistance(
        distanceKm: 100,
        travelTimeMin: 120,
      );
      const distance2 = DestinationDistance(
        distanceKm: 100,
        travelTimeMin: 120,
      );
      const distance3 = DestinationDistance(
        distanceKm: 200,
        travelTimeMin: 240,
      );

      expect(distance1, equals(distance2));
      expect(distance1.hashCode, equals(distance2.hashCode));
      expect(distance1, isNot(equals(distance3)));
    });

    test('toString should return readable format', () {
      const distance = DestinationDistance(distanceKm: 100, travelTimeMin: 120);

      expect(distance.toString(), contains('100 km'));
      expect(distance.toString(), contains('2 giờ'));
    });
  });
}
