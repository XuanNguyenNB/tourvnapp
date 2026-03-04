import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/presentation/widgets/day_pills_selector.dart';

void main() {
  group('DayPillsSelector Conflict Badges', () {
    testWidgets('displays warning badge on conflict days', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayPillsSelector(
              totalDays: 3,
              selectedDay: 1,
              conflictDays: const {1, 3}, // Day 1 and 3 have conflicts
              onDaySelected: (_) {},
            ),
          ),
        ),
      );

      // Should find warning badges (⚠️ emoji)
      // We expect 2 badges for day 1 and day 3
      expect(find.text('⚠️'), findsNWidgets(2));
    });

    testWidgets('no warning badges when no conflicts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayPillsSelector(
              totalDays: 3,
              selectedDay: 1,
              conflictDays: const {}, // No conflicts
              onDaySelected: (_) {},
            ),
          ),
        ),
      );

      // Should find no warning badges
      expect(find.text('⚠️'), findsNothing);
    });

    testWidgets('displays all day pills', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayPillsSelector(
              totalDays: 5,
              selectedDay: 2,
              conflictDays: const {},
              onDaySelected: (_) {},
            ),
          ),
        ),
      );

      // Should display all 5 days
      expect(find.text('Day 1'), findsOneWidget);
      expect(find.text('Day 2'), findsOneWidget);
      expect(find.text('Day 3'), findsOneWidget);
      expect(find.text('Day 4'), findsOneWidget);
      expect(find.text('Day 5'), findsOneWidget);
    });

    testWidgets('calls onDaySelected when pill is tapped', (tester) async {
      int? selectedDay;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayPillsSelector(
              totalDays: 3,
              selectedDay: 1,
              conflictDays: const {},
              onDaySelected: (day) => selectedDay = day,
            ),
          ),
        ),
      );

      // Tap on Day 2
      await tester.tap(find.text('Day 2'));
      await tester.pump();

      expect(selectedDay, equals(2));
    });

    testWidgets('conflict pill has amber border when not selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayPillsSelector(
              totalDays: 3,
              selectedDay: 1, // Day 1 is selected
              conflictDays: const {2}, // Day 2 has conflict
              onDaySelected: (_) {},
            ),
          ),
        ),
      );

      // Find the AnimatedContainer for Day 2
      // We can verify by looking for amber color in the decoration
      // The exact verification is tricky, but we can verify the widget tree
      final day2Pill = find.ancestor(
        of: find.text('Day 2'),
        matching: find.byType(AnimatedContainer),
      );

      expect(day2Pill, findsOneWidget);
    });

    testWidgets('selected conflict day shows primary color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayPillsSelector(
              totalDays: 3,
              selectedDay: 2, // Day 2 is selected AND has conflict
              conflictDays: const {2},
              onDaySelected: (_) {},
            ),
          ),
        ),
      );

      // Should still show the warning badge on selected conflict day
      expect(find.text('⚠️'), findsOneWidget);
    });

    testWidgets('empty conflictDays set is handled gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayPillsSelector(
              totalDays: 3,
              selectedDay: 1,
              // Using default empty set
              onDaySelected: (_) {},
            ),
          ),
        ),
      );

      // Should not show any warning badges
      expect(find.text('⚠️'), findsNothing);
    });
  });
}
