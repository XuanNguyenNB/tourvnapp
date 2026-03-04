import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';

void main() {
  group('Location Entity GPS Fields', () {
    test('should create location with GPS coordinates', () {
      const location = Location(
        id: 'test-1',
        destinationId: 'da-nang',
        name: 'Test Location',
        image: 'https://example.com/image.jpg',
        category: 'food',
        latitude: 16.0544,
        longitude: 108.2022,
      );

      expect(location.latitude, equals(16.0544));
      expect(location.longitude, equals(108.2022));
    });

    test('should create location without GPS coordinates (null)', () {
      const location = Location(
        id: 'test-2',
        destinationId: 'da-nang',
        name: 'Test Location',
        image: 'https://example.com/image.jpg',
        category: 'food',
      );

      expect(location.latitude, isNull);
      expect(location.longitude, isNull);
    });

    group('hasCoordinates getter', () {
      test('should return true when both lat and lng are present', () {
        const location = Location(
          id: 'test-3',
          destinationId: 'da-nang',
          name: 'Test Location',
          image: 'https://example.com/image.jpg',
          category: 'food',
          latitude: 16.0544,
          longitude: 108.2022,
        );

        expect(location.hasCoordinates, isTrue);
      });

      test('should return false when latitude is null', () {
        const location = Location(
          id: 'test-4',
          destinationId: 'da-nang',
          name: 'Test Location',
          image: 'https://example.com/image.jpg',
          category: 'food',
          latitude: null,
          longitude: 108.2022,
        );

        expect(location.hasCoordinates, isFalse);
      });

      test('should return false when longitude is null', () {
        const location = Location(
          id: 'test-5',
          destinationId: 'da-nang',
          name: 'Test Location',
          image: 'https://example.com/image.jpg',
          category: 'food',
          latitude: 16.0544,
          longitude: null,
        );

        expect(location.hasCoordinates, isFalse);
      });

      test('should return false when both are null', () {
        const location = Location(
          id: 'test-6',
          destinationId: 'da-nang',
          name: 'Test Location',
          image: 'https://example.com/image.jpg',
          category: 'food',
        );

        expect(location.hasCoordinates, isFalse);
      });
    });

    group('copyWith', () {
      test('should copy with new GPS coordinates', () {
        const original = Location(
          id: 'test-7',
          destinationId: 'da-nang',
          name: 'Test Location',
          image: 'https://example.com/image.jpg',
          category: 'food',
        );

        final updated = original.copyWith(
          latitude: 16.0544,
          longitude: 108.2022,
        );

        expect(updated.latitude, equals(16.0544));
        expect(updated.longitude, equals(108.2022));
        expect(updated.id, equals(original.id));
        expect(updated.name, equals(original.name));
      });

      test('should preserve GPS coordinates if not overwritten', () {
        const original = Location(
          id: 'test-8',
          destinationId: 'da-nang',
          name: 'Test Location',
          image: 'https://example.com/image.jpg',
          category: 'food',
          latitude: 16.0544,
          longitude: 108.2022,
        );

        final updated = original.copyWith(name: 'Updated Name');

        expect(updated.latitude, equals(16.0544));
        expect(updated.longitude, equals(108.2022));
        expect(updated.name, equals('Updated Name'));
      });
    });

    group('fromJson', () {
      test('should parse GPS coordinates from JSON', () {
        final json = {
          'id': 'test-9',
          'destinationId': 'da-nang',
          'name': 'Test Location',
          'image': 'https://example.com/image.jpg',
          'category': 'food',
          'latitude': 16.0544,
          'longitude': 108.2022,
        };

        final location = Location.fromJson(json);

        expect(location.latitude, equals(16.0544));
        expect(location.longitude, equals(108.2022));
      });

      test('should handle missing GPS coordinates in JSON', () {
        final json = {
          'id': 'test-10',
          'destinationId': 'da-nang',
          'name': 'Test Location',
          'image': 'https://example.com/image.jpg',
          'category': 'food',
        };

        final location = Location.fromJson(json);

        expect(location.latitude, isNull);
        expect(location.longitude, isNull);
      });

      test('should handle integer GPS coordinates from Firestore', () {
        final json = {
          'id': 'test-11',
          'destinationId': 'da-nang',
          'name': 'Test Location',
          'image': 'https://example.com/image.jpg',
          'category': 'food',
          'latitude': 16, // Integer instead of double
          'longitude': 108,
        };

        final location = Location.fromJson(json);

        expect(location.latitude, equals(16.0));
        expect(location.longitude, equals(108.0));
      });
    });

    group('toJson', () {
      test('should include GPS coordinates in JSON', () {
        const location = Location(
          id: 'test-12',
          destinationId: 'da-nang',
          name: 'Test Location',
          image: 'https://example.com/image.jpg',
          category: 'food',
          latitude: 16.0544,
          longitude: 108.2022,
        );

        final json = location.toJson();

        expect(json['latitude'], equals(16.0544));
        expect(json['longitude'], equals(108.2022));
      });

      test('should include null GPS coordinates in JSON', () {
        const location = Location(
          id: 'test-13',
          destinationId: 'da-nang',
          name: 'Test Location',
          image: 'https://example.com/image.jpg',
          category: 'food',
        );

        final json = location.toJson();

        expect(json.containsKey('latitude'), isTrue);
        expect(json.containsKey('longitude'), isTrue);
        expect(json['latitude'], isNull);
        expect(json['longitude'], isNull);
      });
    });
  });
}
