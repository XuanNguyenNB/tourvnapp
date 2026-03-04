import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/home/domain/utils/destination_emoji_helper.dart';

void main() {
  group('DestinationEmojiHelper', () {
    group('getEmoji', () {
      test('returns beach emoji for da-nang', () {
        expect(DestinationEmojiHelper.getEmoji('da-nang'), '🏖️');
      });

      test('returns lantern emoji for hoi-an', () {
        expect(DestinationEmojiHelper.getEmoji('hoi-an'), '🏮');
      });

      test('returns mountain emoji for da-lat', () {
        expect(DestinationEmojiHelper.getEmoji('da-lat'), '🏔️');
      });

      test('returns temple emoji for hue', () {
        expect(DestinationEmojiHelper.getEmoji('hue'), '🏛️');
      });

      test('returns wave emoji for nha-trang', () {
        expect(DestinationEmojiHelper.getEmoji('nha-trang'), '🌊');
      });

      test('returns island emoji for phu-quoc', () {
        expect(DestinationEmojiHelper.getEmoji('phu-quoc'), '🏝️');
      });

      test('returns default emoji for unknown destination', () {
        expect(
          DestinationEmojiHelper.getEmoji('unknown-destination'),
          DestinationEmojiHelper.defaultEmoji,
        );
      });

      test('handles case insensitivity', () {
        expect(DestinationEmojiHelper.getEmoji('DA-NANG'), '🏖️');
        expect(DestinationEmojiHelper.getEmoji('Da-Nang'), '🏖️');
      });

      test('trims whitespace from destination ID', () {
        expect(DestinationEmojiHelper.getEmoji('  da-nang  '), '🏖️');
      });

      test('returns city emoji for sai-gon and ho-chi-minh', () {
        expect(DestinationEmojiHelper.getEmoji('sai-gon'), '🌆');
        expect(DestinationEmojiHelper.getEmoji('ho-chi-minh'), '🌆');
      });

      test('returns empty string destination returns default', () {
        expect(
          DestinationEmojiHelper.getEmoji(''),
          DestinationEmojiHelper.defaultEmoji,
        );
      });
    });

    group('formatPillText', () {
      test('combines emoji and name correctly', () {
        final result = DestinationEmojiHelper.formatPillText(
          'da-nang',
          'Đà Nẵng',
        );
        expect(result, '🏖️ Đà Nẵng');
      });

      test('uses default emoji for unknown destination', () {
        final result = DestinationEmojiHelper.formatPillText(
          'unknown',
          'Unknown City',
        );
        expect(result, '📍 Unknown City');
      });

      test('preserves Vietnamese diacritics in name', () {
        final result = DestinationEmojiHelper.formatPillText(
          'da-lat',
          'Đà Lạt',
        );
        expect(result, '🏔️ Đà Lạt');
      });

      test('formats correctly with special characters', () {
        final result = DestinationEmojiHelper.formatPillText('hue', 'Huế');
        expect(result, '🏛️ Huế');
      });
    });

    group('hasCustomEmoji', () {
      test('returns true for known destinations', () {
        expect(DestinationEmojiHelper.hasCustomEmoji('da-nang'), true);
        expect(DestinationEmojiHelper.hasCustomEmoji('hoi-an'), true);
      });

      test('returns false for unknown destinations', () {
        expect(DestinationEmojiHelper.hasCustomEmoji('unknown'), false);
      });

      test('handles case insensitivity', () {
        expect(DestinationEmojiHelper.hasCustomEmoji('DA-NANG'), true);
      });
    });

    group('knownDestinationIds', () {
      test('returns list with known destinations', () {
        final ids = DestinationEmojiHelper.knownDestinationIds;
        expect(ids, contains('da-nang'));
        expect(ids, contains('hoi-an'));
        expect(ids, contains('da-lat'));
      });

      test('does not include unknown destinations', () {
        final ids = DestinationEmojiHelper.knownDestinationIds;
        expect(ids, isNot(contains('unknown')));
      });
    });

    group('defaultEmoji', () {
      test('is a location pin emoji', () {
        expect(DestinationEmojiHelper.defaultEmoji, '📍');
      });
    });
  });
}
