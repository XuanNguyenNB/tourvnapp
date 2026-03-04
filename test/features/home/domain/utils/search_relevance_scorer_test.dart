import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';
import 'package:tour_vn/features/home/domain/utils/search_relevance_scorer.dart';

void main() {
  group('SearchRelevanceScorer', () {
    // Test data
    late Location exactMatchLocation;
    late Location startsWithLocation;
    late Location containsLocation;
    late Location destinationMatchLocation;
    late Location keywordMatchLocation;
    late Location noMatchLocation;

    setUp(() {
      exactMatchLocation = const Location(
        id: '1',
        destinationId: 'da-nang',
        name: 'Bà Nà Hills',
        image: 'image1.jpg',
        category: 'places',
        viewCount: 100,
      );

      startsWithLocation = const Location(
        id: '2',
        destinationId: 'da-nang',
        name: 'Bà Nà Hills Resort',
        image: 'image2.jpg',
        category: 'stay',
        viewCount: 50,
      );

      containsLocation = const Location(
        id: '3',
        destinationId: 'da-nang',
        name: 'Golden Bridge at Bà Nà',
        image: 'image3.jpg',
        category: 'places',
        viewCount: 200,
      );

      destinationMatchLocation = const Location(
        id: '4',
        destinationId: 'da-nang',
        destinationName: 'Đà Nẵng',
        name: 'Cầu Rồng',
        image: 'image4.jpg',
        category: 'places',
        viewCount: 150,
      );

      keywordMatchLocation = const Location(
        id: '5',
        destinationId: 'da-nang',
        name: 'Phố Cổ',
        image: 'image5.jpg',
        category: 'places',
        viewCount: 80,
        searchKeywords: ['bà nà', 'cable car', 'french village'],
      );

      noMatchLocation = const Location(
        id: '6',
        destinationId: 'da-lat',
        name: 'Núi Lang Biang',
        image: 'image6.jpg',
        category: 'places',
        viewCount: 75,
      );
    });

    group('calculateScore', () {
      test('returns 100 for exact name match (case-insensitive)', () {
        expect(
          SearchRelevanceScorer.calculateScore(
            exactMatchLocation,
            'Bà Nà Hills',
          ),
          equals(100),
        );
        expect(
          SearchRelevanceScorer.calculateScore(
            exactMatchLocation,
            'bà nà hills',
          ),
          equals(100),
        );
        expect(
          SearchRelevanceScorer.calculateScore(
            exactMatchLocation,
            'BÀ NÀ HILLS',
          ),
          equals(100),
        );
      });

      test('returns 80 for name starts with query', () {
        expect(
          SearchRelevanceScorer.calculateScore(startsWithLocation, 'Bà Nà'),
          equals(80),
        );
        expect(
          SearchRelevanceScorer.calculateScore(startsWithLocation, 'bà'),
          equals(80),
        );
      });

      test('returns 60 for name contains query', () {
        expect(
          SearchRelevanceScorer.calculateScore(containsLocation, 'Bà Nà'),
          equals(60),
        );
        expect(
          SearchRelevanceScorer.calculateScore(containsLocation, 'Golden'),
          equals(80), // Starts with, so 80
        );
        expect(
          SearchRelevanceScorer.calculateScore(containsLocation, 'Bridge'),
          equals(60), // Contains, so 60
        );
      });

      test('returns 40 for destination name match', () {
        expect(
          SearchRelevanceScorer.calculateScore(
            destinationMatchLocation,
            'Đà Nẵng',
          ),
          equals(40),
        );
        expect(
          SearchRelevanceScorer.calculateScore(
            destinationMatchLocation,
            'đà nẵng',
          ),
          equals(40),
        );
      });

      test('returns 20 for search keywords match', () {
        expect(
          SearchRelevanceScorer.calculateScore(
            keywordMatchLocation,
            'cable car',
          ),
          equals(20),
        );
        expect(
          SearchRelevanceScorer.calculateScore(keywordMatchLocation, 'french'),
          equals(20),
        );
      });

      test('returns 0 for no match', () {
        expect(
          SearchRelevanceScorer.calculateScore(noMatchLocation, 'Bà Nà'),
          equals(0),
        );
        expect(
          SearchRelevanceScorer.calculateScore(noMatchLocation, 'random query'),
          equals(0),
        );
      });

      test('returns 0 for empty query', () {
        expect(
          SearchRelevanceScorer.calculateScore(exactMatchLocation, ''),
          equals(0),
        );
      });

      test('handles whitespace in query', () {
        expect(
          SearchRelevanceScorer.calculateScore(
            exactMatchLocation,
            '  Bà Nà Hills  ',
          ),
          equals(100),
        );
      });
    });

    group('sortByRelevance', () {
      test('sorts locations by relevance score descending', () {
        final locations = [
          noMatchLocation,
          keywordMatchLocation,
          exactMatchLocation,
          containsLocation,
        ];

        final sorted = SearchRelevanceScorer.sortByRelevance(
          locations,
          'Bà Nà',
        );

        // Exact match should be first, keyword match last (among matching)
        expect(sorted.first.id, equals('1')); // exactMatchLocation - score 100
        expect(sorted[1].id, equals('3')); // containsLocation - score 60
        expect(sorted[2].id, equals('5')); // keywordMatchLocation - score 20
        expect(sorted.last.id, equals('6')); // noMatchLocation - score 0
      });

      test('uses viewCount as secondary sort for equal scores', () {
        final location1 = const Location(
          id: 'a',
          destinationId: 'test',
          name: 'Test Place A',
          image: 'img.jpg',
          category: 'places',
          viewCount: 100,
        );
        final location2 = const Location(
          id: 'b',
          destinationId: 'test',
          name: 'Test Place B',
          image: 'img.jpg',
          category: 'places',
          viewCount: 200, // Higher viewCount
        );

        final locations = [location1, location2];
        final sorted = SearchRelevanceScorer.sortByRelevance(locations, 'Test');

        // Both have same relevance (starts with), so higher viewCount first
        expect(sorted.first.id, equals('b'));
        expect(sorted.last.id, equals('a'));
      });

      test('returns empty list for empty query', () {
        final locations = [exactMatchLocation, containsLocation];
        final sorted = SearchRelevanceScorer.sortByRelevance(locations, '');

        expect(sorted, equals(locations)); // Returns original list
      });

      test('returns original list for empty locations', () {
        final sorted = SearchRelevanceScorer.sortByRelevance([], 'test');

        expect(sorted, isEmpty);
      });
    });

    group('filterAndSort', () {
      test('filters out non-matching locations', () {
        final locations = [
          exactMatchLocation,
          noMatchLocation,
          containsLocation,
        ];

        final result = SearchRelevanceScorer.filterAndSort(locations, 'Bà Nà');

        expect(result.length, equals(2));
        expect(
          result.any((l) => l.id == '6'),
          isFalse,
        ); // noMatchLocation filtered
      });

      test('returns sorted matching locations', () {
        final locations = [
          containsLocation,
          exactMatchLocation,
          keywordMatchLocation,
        ];

        final result = SearchRelevanceScorer.filterAndSort(locations, 'Bà Nà');

        expect(result.first.id, equals('1')); // Exact match first
        expect(result[1].id, equals('3')); // Contains second
        expect(result.last.id, equals('5')); // Keyword match last
      });

      test('returns empty list for empty query', () {
        final locations = [exactMatchLocation];
        final result = SearchRelevanceScorer.filterAndSort(locations, '');

        expect(result, isEmpty);
      });

      test('returns empty list when no matches', () {
        final locations = [noMatchLocation];
        final result = SearchRelevanceScorer.filterAndSort(locations, 'xyz');

        expect(result, isEmpty);
      });
    });
  });
}
