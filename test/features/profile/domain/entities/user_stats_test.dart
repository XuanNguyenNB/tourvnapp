import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/profile/domain/entities/user_stats.dart';

void main() {
  group('UserStats', () {
    test('should create UserStats with required parameters', () {
      const stats = UserStats(tripCount: 5, savesCount: 10, reviewsCount: 3);

      expect(stats.tripCount, equals(5));
      expect(stats.savesCount, equals(10));
      expect(stats.reviewsCount, equals(3));
    });

    test('factory empty() should create stats with all zeros', () {
      final stats = UserStats.empty();

      expect(stats.tripCount, equals(0));
      expect(stats.savesCount, equals(0));
      expect(stats.reviewsCount, equals(0));
    });

    group('formattedCount', () {
      test('should return number as string for counts under 1000', () {
        const stats = UserStats(
          tripCount: 999,
          savesCount: 42,
          reviewsCount: 0,
        );

        expect(stats.formattedTripCount, equals('999'));
        expect(stats.formattedSavesCount, equals('42'));
        expect(stats.formattedReviewsCount, equals('0'));
      });

      test('should format counts >= 1000 as "X.Xk"', () {
        const stats = UserStats(
          tripCount: 1000,
          savesCount: 1500,
          reviewsCount: 12345,
        );

        expect(stats.formattedTripCount, equals('1.0k'));
        expect(stats.formattedSavesCount, equals('1.5k'));
        expect(stats.formattedReviewsCount, equals('12.3k'));
      });

      test('should format counts >= 1000000 as "X.XM"', () {
        const stats = UserStats(
          tripCount: 1000000,
          savesCount: 2500000,
          reviewsCount: 100,
        );

        expect(stats.formattedTripCount, equals('1.0M'));
        expect(stats.formattedSavesCount, equals('2.5M'));
        expect(stats.formattedReviewsCount, equals('100'));
      });
    });

    test('copyWith should create a copy with updated values', () {
      const original = UserStats(tripCount: 5, savesCount: 10, reviewsCount: 3);

      final updated = original.copyWith(tripCount: 10);

      expect(updated.tripCount, equals(10));
      expect(updated.savesCount, equals(10)); // unchanged
      expect(updated.reviewsCount, equals(3)); // unchanged
    });

    test('equality should work correctly', () {
      const stats1 = UserStats(tripCount: 5, savesCount: 10, reviewsCount: 3);
      const stats2 = UserStats(tripCount: 5, savesCount: 10, reviewsCount: 3);
      const stats3 = UserStats(tripCount: 6, savesCount: 10, reviewsCount: 3);

      expect(stats1, equals(stats2));
      expect(stats1, isNot(equals(stats3)));
    });

    test('toString should return meaningful representation', () {
      const stats = UserStats(tripCount: 5, savesCount: 10, reviewsCount: 3);
      expect(stats.toString(), contains('trips: 5'));
      expect(stats.toString(), contains('saves: 10'));
      expect(stats.toString(), contains('reviews: 3'));
    });
  });
}
