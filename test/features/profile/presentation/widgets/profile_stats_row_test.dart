import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/profile/domain/entities/user_stats.dart';
import 'package:tour_vn/features/profile/presentation/widgets/profile_stats_row.dart';

void main() {
  group('ProfileStatsRow', () {
    testWidgets('should display three stat cards', (tester) async {
      const stats = UserStats(tripCount: 5, savesCount: 10, reviewsCount: 3);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ProfileStatsRow(stats: stats)),
        ),
      );

      // Verify 3 stat values are displayed
      expect(find.text('5'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Verify labels
      expect(find.text('Trips'), findsOneWidget);
      expect(find.text('Saves'), findsOneWidget);
      expect(find.text('Reviews'), findsOneWidget);
    });

    testWidgets('should display formatted large numbers', (tester) async {
      const stats = UserStats(
        tripCount: 1500,
        savesCount: 2300,
        reviewsCount: 50,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ProfileStatsRow(stats: stats)),
        ),
      );

      expect(find.text('1.5k'), findsOneWidget);
      expect(find.text('2.3k'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('should display zero stats correctly', (tester) async {
      final stats = UserStats.empty();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProfileStatsRow(stats: stats)),
        ),
      );

      expect(find.text('0'), findsNWidgets(3));
    });

    testWidgets('should have icons for each stat', (tester) async {
      const stats = UserStats(tripCount: 1, savesCount: 2, reviewsCount: 3);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ProfileStatsRow(stats: stats)),
        ),
      );

      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
      expect(find.byIcon(Icons.rate_review_outlined), findsOneWidget);
    });
  });
}
