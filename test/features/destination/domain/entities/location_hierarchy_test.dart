import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';

void main() {
  group('Location Entity - Tags and SearchKeywords', () {
    test(
      'should create Location with empty tags and searchKeywords by default',
      () {
        // Arrange & Act
        const location = Location(
          id: 'test-id',
          destinationId: 'da-nang',
          name: 'Test Location',
          image: 'https://example.com/image.jpg',
          category: 'food',
        );

        // Assert
        expect(location.tags, isEmpty);
        expect(location.searchKeywords, isEmpty);
      },
    );

    test('should create Location with provided tags and searchKeywords', () {
      // Arrange & Act
      const location = Location(
        id: 'test-id',
        destinationId: 'da-nang',
        name: 'Romantic Restaurant',
        image: 'https://example.com/image.jpg',
        category: 'food',
        tags: ['romantic', 'luxury'],
        searchKeywords: ['nha hang', 'restaurant', 'lang man'],
      );

      // Assert
      expect(location.tags, ['romantic', 'luxury']);
      expect(location.searchKeywords, ['nha hang', 'restaurant', 'lang man']);
    });

    test('fromJson should parse tags and searchKeywords correctly', () {
      // Arrange
      final json = {
        'id': 'test-id',
        'destinationId': 'da-nang',
        'name': 'Test Location',
        'image': 'https://example.com/image.jpg',
        'category': 'food',
        'tags': ['romantic', 'instagram-worthy'],
        'searchKeywords': ['keyword1', 'keyword2'],
      };

      // Act
      final location = Location.fromJson(json);

      // Assert
      expect(location.tags, ['romantic', 'instagram-worthy']);
      expect(location.searchKeywords, ['keyword1', 'keyword2']);
    });

    test(
      'fromJson should handle missing tags and searchKeywords (backward compatibility)',
      () {
        // Arrange
        final json = {
          'id': 'test-id',
          'destinationId': 'da-nang',
          'name': 'Test Location',
          'image': 'https://example.com/image.jpg',
          'category': 'food',
          // No tags or searchKeywords fields
        };

        // Act
        final location = Location.fromJson(json);

        // Assert
        expect(location.tags, isEmpty);
        expect(location.searchKeywords, isEmpty);
      },
    );

    test('fromJson should handle null tags and searchKeywords', () {
      // Arrange
      final json = {
        'id': 'test-id',
        'destinationId': 'da-nang',
        'name': 'Test Location',
        'image': 'https://example.com/image.jpg',
        'category': 'food',
        'tags': null,
        'searchKeywords': null,
      };

      // Act
      final location = Location.fromJson(json);

      // Assert
      expect(location.tags, isEmpty);
      expect(location.searchKeywords, isEmpty);
    });

    test('fromJson should handle missing optional destination fields', () {
      // Arrange
      final json = {
        'id': 'test-id',
        'destinationId': 'da-nang',
        // 'destinationName' is missing
        'name': 'Test Location',
        'image': 'https://example.com/image.jpg',
        'category': 'food',
      };

      // Act
      final location = Location.fromJson(json);

      // Assert
      expect(location.destinationName, isNull);
    });

    test('fromJson should handle null destination fields', () {
      // Arrange
      final json = {
        'id': 'test-id',
        'destinationId': 'da-nang',
        'destinationName': null,
        'name': 'Test Location',
        'image': 'https://example.com/image.jpg',
        'category': 'food',
      };

      // Act
      final location = Location.fromJson(json);

      // Assert
      expect(location.destinationName, isNull);
    });

    test('toJson should serialize tags and searchKeywords', () {
      // Arrange
      const location = Location(
        id: 'test-id',
        destinationId: 'da-nang',
        name: 'Test Location',
        image: 'https://example.com/image.jpg',
        category: 'food',
        tags: ['romantic', 'family-friendly'],
        searchKeywords: ['test', 'keywords'],
      );

      // Act
      final json = location.toJson();

      // Assert
      expect(json['tags'], ['romantic', 'family-friendly']);
      expect(json['searchKeywords'], ['test', 'keywords']);
    });

    test('toJson should serialize empty lists for tags and searchKeywords', () {
      // Arrange
      const location = Location(
        id: 'test-id',
        destinationId: 'da-nang',
        name: 'Test Location',
        image: 'https://example.com/image.jpg',
        category: 'food',
      );

      // Act
      final json = location.toJson();

      // Assert
      expect(json['tags'], isEmpty);
      expect(json['searchKeywords'], isEmpty);
    });

    test('copyWith should update tags and searchKeywords', () {
      // Arrange
      const original = Location(
        id: 'test-id',
        destinationId: 'da-nang',
        name: 'Test Location',
        image: 'https://example.com/image.jpg',
        category: 'food',
        tags: ['romantic'],
        searchKeywords: ['old'],
      );

      // Act
      final updated = original.copyWith(
        tags: ['adventure', 'luxury'],
        searchKeywords: ['new', 'keywords'],
      );

      // Assert
      expect(updated.tags, ['adventure', 'luxury']);
      expect(updated.searchKeywords, ['new', 'keywords']);
      expect(updated.id, original.id); // Other fields unchanged
    });

    test('copyWith should preserve original values when not specified', () {
      // Arrange
      const original = Location(
        id: 'test-id',
        destinationId: 'da-nang',
        name: 'Test Location',
        image: 'https://example.com/image.jpg',
        category: 'food',
        tags: ['romantic'],
        searchKeywords: ['keyword'],
      );

      // Act
      final updated = original.copyWith(name: 'New Name');

      // Assert
      expect(updated.tags, ['romantic']);
      expect(updated.searchKeywords, ['keyword']);
    });

    group('formattedTags getter', () {
      test('should format known tags with emojis', () {
        // Arrange
        const location = Location(
          id: 'test-id',
          destinationId: 'da-nang',
          name: 'Test Location',
          image: 'https://example.com/image.jpg',
          category: 'food',
          tags: ['romantic', 'family-friendly', 'luxury'],
        );

        // Act
        final formatted = location.formattedTags;

        // Assert
        expect(formatted, contains('❤️ romantic'));
        expect(formatted, contains('👨\u200d👩\u200d👧 family-friendly'));
        expect(formatted, contains('✨ luxury'));
      });

      test('should use default emoji for unknown tags', () {
        // Arrange
        const location = Location(
          id: 'test-id',
          destinationId: 'da-nang',
          name: 'Test Location',
          image: 'https://example.com/image.jpg',
          category: 'food',
          tags: ['unknown-tag'],
        );

        // Act
        final formatted = location.formattedTags;

        // Assert
        expect(formatted, contains('🏷️ unknown-tag'));
      });

      test('should return empty list for empty tags', () {
        // Arrange
        const location = Location(
          id: 'test-id',
          destinationId: 'da-nang',
          name: 'Test Location',
          image: 'https://example.com/image.jpg',
          category: 'food',
        );

        // Act
        final formatted = location.formattedTags;

        // Assert
        expect(formatted, isEmpty);
      });

      test('should handle case-insensitive tag matching', () {
        // Arrange
        const location = Location(
          id: 'test-id',
          destinationId: 'da-nang',
          name: 'Test Location',
          image: 'https://example.com/image.jpg',
          category: 'food',
          tags: ['ROMANTIC', 'Luxury'],
        );

        // Act
        final formatted = location.formattedTags;

        // Assert
        expect(formatted, contains('❤️ ROMANTIC'));
        expect(formatted, contains('✨ Luxury'));
      });
    });

    group('matchesSearch method', () {
      test('should match by location name', () {
        // Arrange
        const location = Location(
          id: 'test-id',
          destinationId: 'da-nang',
          name: 'Bánh Mì Phượng',
          image: 'https://example.com/image.jpg',
          category: 'food',
        );

        // Act & Assert
        expect(location.matchesSearch('bánh'), isTrue);
        expect(location.matchesSearch('phượng'), isTrue);
        expect(location.matchesSearch('BÁNH MÌ'), isTrue); // case-insensitive
      });

      test('should match by destination name', () {
        // Arrange
        const location = Location(
          id: 'test-id',
          destinationId: 'da-nang',
          destinationName: 'Đà Nẵng',
          name: 'Test Location',
          image: 'https://example.com/image.jpg',
          category: 'food',
        );

        // Act & Assert
        expect(location.matchesSearch('đà nẵng'), isTrue);
        expect(location.matchesSearch('nẵng'), isTrue);
      });

      test('should match by search keywords', () {
        // Arrange
        const location = Location(
          id: 'test-id',
          destinationId: 'da-nang',
          name: 'Test Location',
          image: 'https://example.com/image.jpg',
          category: 'food',
          searchKeywords: ['banh mi', 'sandwich', 'phuong'],
        );

        // Act & Assert
        expect(location.matchesSearch('banh'), isTrue);
        expect(location.matchesSearch('sandwich'), isTrue);
        expect(location.matchesSearch('phuong'), isTrue);
      });

      test('should not match if query not found', () {
        // Arrange
        const location = Location(
          id: 'test-id',
          destinationId: 'da-nang',
          name: 'Bánh Mì',
          image: 'https://example.com/image.jpg',
          category: 'food',
          searchKeywords: ['sandwich'],
        );

        // Act & Assert
        expect(location.matchesSearch('phở'), isFalse);
        expect(location.matchesSearch('pizza'), isFalse);
      });

      test('should handle null destination name', () {
        // Arrange
        const location = Location(
          id: 'test-id',
          destinationId: 'da-nang',
          destinationName: null,
          name: 'Test Location',
          image: 'https://example.com/image.jpg',
          category: 'food',
        );

        // Act & Assert
        expect(location.matchesSearch('nẵng'), isFalse);
        expect(() => location.matchesSearch('test'), returnsNormally);
      });

      test('should match across multiple fields', () {
        // Arrange
        const location = Location(
          id: 'test-id',
          destinationId: 'da-nang',
          destinationName: 'Đà Nẵng',
          name: 'Bánh Mì Phượng',
          image: 'https://example.com/image.jpg',
          category: 'food',
          searchKeywords: ['sandwich', 'hoi an'],
        );

        // Act & Assert
        expect(location.matchesSearch('bánh'), isTrue); // name
        expect(location.matchesSearch('nẵng'), isTrue); // destination
        expect(location.matchesSearch('sandwich'), isTrue); // keywords
      });
    });
  });
}
