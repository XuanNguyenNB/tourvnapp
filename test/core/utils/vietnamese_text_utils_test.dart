import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/core/utils/vietnamese_text_utils.dart';

void main() {
  group('VietnameseTextUtils', () {
    group('removeDiacritics', () {
      test('converts Vietnamese characters to non-diacritic equivalents', () {
        expect(
          VietnameseTextUtils.removeDiacritics('Đà Nẵng'),
          equals('da nang'),
        );
        expect(
          VietnameseTextUtils.removeDiacritics('Bà Nà Hills'),
          equals('ba na hills'),
        );
        expect(VietnameseTextUtils.removeDiacritics('Huế'), equals('hue'));
        expect(
          VietnameseTextUtils.removeDiacritics('Phú Quốc'),
          equals('phu quoc'),
        );
        expect(
          VietnameseTextUtils.removeDiacritics('Sài Gòn'),
          equals('sai gon'),
        );
      });

      test('preserves non-Vietnamese characters', () {
        expect(
          VietnameseTextUtils.removeDiacritics('Hello World'),
          equals('hello world'),
        );
        expect(
          VietnameseTextUtils.removeDiacritics('123 ABC'),
          equals('123 abc'),
        );
        expect(
          VietnameseTextUtils.removeDiacritics('Test!@#'),
          equals('test!@#'),
        );
      });

      test('handles empty string', () {
        expect(VietnameseTextUtils.removeDiacritics(''), equals(''));
      });

      test('handles mixed content', () {
        expect(
          VietnameseTextUtils.removeDiacritics('Golden Bridge tại Bà Nà'),
          equals('golden bridge tai ba na'),
        );
      });

      test('converts to lowercase', () {
        expect(
          VietnameseTextUtils.removeDiacritics('ĐÀ NẴNG'),
          equals('da nang'),
        );
      });
    });

    group('hasDiacritics', () {
      test('returns true for text with Vietnamese diacritics', () {
        expect(VietnameseTextUtils.hasDiacritics('Đà Nẵng'), isTrue);
        expect(VietnameseTextUtils.hasDiacritics('Bà Nà'), isTrue);
        expect(VietnameseTextUtils.hasDiacritics('Huế'), isTrue);
      });

      test('returns false for text without diacritics', () {
        expect(VietnameseTextUtils.hasDiacritics('Da Nang'), isFalse);
        expect(VietnameseTextUtils.hasDiacritics('Hello'), isFalse);
        expect(VietnameseTextUtils.hasDiacritics('123'), isFalse);
      });

      test('returns false for empty string', () {
        expect(VietnameseTextUtils.hasDiacritics(''), isFalse);
      });
    });

    group('generateSearchKeywords', () {
      test('generates keywords with and without diacritics', () {
        final keywords = VietnameseTextUtils.generateSearchKeywords('Đà Nẵng');

        expect(keywords, contains('đà nẵng'));
        expect(keywords, contains('da nang'));
        expect(keywords, contains('đà'));
        expect(keywords, contains('da'));
        expect(keywords, contains('nẵng'));
        expect(keywords, contains('nang'));
      });

      test('includes individual words with minimum length 2', () {
        final keywords = VietnameseTextUtils.generateSearchKeywords(
          'Bà Nà Hills',
        );

        expect(keywords, contains('bà nà hills'));
        expect(keywords, contains('ba na hills'));
        expect(keywords, contains('bà'));
        expect(keywords, contains('nà'));
        expect(keywords, contains('hills'));
      });

      test('excludes single character words', () {
        final keywords = VietnameseTextUtils.generateSearchKeywords(
          'Đà Nẵng A B',
        );

        // Single characters 'a' and 'b' should not be included
        expect(keywords.where((k) => k == 'a').length, equals(0));
        expect(keywords.where((k) => k == 'b').length, equals(0));
      });

      test('returns empty list for empty string', () {
        expect(VietnameseTextUtils.generateSearchKeywords(''), isEmpty);
      });

      test('handles whitespace correctly', () {
        final keywords = VietnameseTextUtils.generateSearchKeywords(
          '  Đà Nẵng  ',
        );

        expect(keywords, contains('đà nẵng'));
        expect(keywords, contains('da nang'));
      });

      test('returns unique keywords (no duplicates)', () {
        final keywords = VietnameseTextUtils.generateSearchKeywords(
          'Test Test',
        );

        // 'test' should only appear once
        final testCount = keywords.where((k) => k == 'test').length;
        expect(testCount, equals(1));
      });
    });

    group('matchesVietnamese', () {
      test('matches with diacritics', () {
        expect(VietnameseTextUtils.matchesVietnamese('Đà Nẵng', 'Đà'), isTrue);
        expect(
          VietnameseTextUtils.matchesVietnamese('Bà Nà Hills', 'Nà'),
          isTrue,
        );
      });

      test('matches without diacritics', () {
        expect(VietnameseTextUtils.matchesVietnamese('Đà Nẵng', 'da'), isTrue);
        expect(
          VietnameseTextUtils.matchesVietnamese('Đà Nẵng', 'nang'),
          isTrue,
        );
        expect(
          VietnameseTextUtils.matchesVietnamese('Bà Nà Hills', 'ba na'),
          isTrue,
        );
      });

      test('is case insensitive', () {
        expect(VietnameseTextUtils.matchesVietnamese('Đà Nẵng', 'ĐÀ'), isTrue);
        expect(VietnameseTextUtils.matchesVietnamese('Đà Nẵng', 'DA'), isTrue);
      });

      test('returns false for non-matching text', () {
        expect(
          VietnameseTextUtils.matchesVietnamese('Đà Nẵng', 'Hue'),
          isFalse,
        );
        expect(
          VietnameseTextUtils.matchesVietnamese('Bà Nà', 'Saigon'),
          isFalse,
        );
      });

      test('returns false for empty query', () {
        expect(VietnameseTextUtils.matchesVietnamese('Đà Nẵng', ''), isFalse);
      });

      test('handles whitespace in query', () {
        expect(
          VietnameseTextUtils.matchesVietnamese('Đà Nẵng', '  da  '),
          isTrue,
        );
      });
    });

    group('normalize', () {
      test('converts to lowercase and trims', () {
        expect(VietnameseTextUtils.normalize('  ĐÀ NẴNG  '), equals('đà nẵng'));
        expect(
          VietnameseTextUtils.normalize('Hello WORLD'),
          equals('hello world'),
        );
      });

      test('optionally removes diacritics', () {
        expect(
          VietnameseTextUtils.normalize('Đà Nẵng', removeDiacritics: true),
          equals('da nang'),
        );
        expect(
          VietnameseTextUtils.normalize('Đà Nẵng', removeDiacritics: false),
          equals('đà nẵng'),
        );
      });

      test('handles empty string', () {
        expect(VietnameseTextUtils.normalize(''), equals(''));
      });
    });
  });
}
