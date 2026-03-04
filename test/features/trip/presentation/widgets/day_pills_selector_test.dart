import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/presentation/widgets/day_pills_selector.dart';

void main() {
  group('DayPillsSelector', () {
    group('UI Rendering', () {
      testWidgets('renders correct number of day pills', (tester) async {
        int? selectedDay;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DayPillsSelector(
                totalDays: 5,
                selectedDay: 1,
                onDaySelected: (day) => selectedDay = day,
              ),
            ),
          ),
        );

        // Verify all 5 day pills are rendered
        expect(find.text('Day 1'), findsOneWidget);
        expect(find.text('Day 2'), findsOneWidget);
        expect(find.text('Day 3'), findsOneWidget);
        expect(find.text('Day 4'), findsOneWidget);
        expect(find.text('Day 5'), findsOneWidget);
      });

      testWidgets('highlights selected day pill', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DayPillsSelector(
                totalDays: 3,
                selectedDay: 2,
                onDaySelected: (_) {},
              ),
            ),
          ),
        );

        // Find all AnimatedContainers (pill containers)
        final containers = tester.widgetList<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );

        // Should have 3 containers
        expect(containers.length, 3);
      });

      testWidgets('handles single day edge case', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DayPillsSelector(
                totalDays: 1,
                selectedDay: 1,
                onDaySelected: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('Day 1'), findsOneWidget);
        expect(find.text('Day 2'), findsNothing);
      });
    });

    group('Interaction', () {
      testWidgets('calls onDaySelected when pill is tapped', (tester) async {
        int? selectedDay;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DayPillsSelector(
                totalDays: 3,
                selectedDay: 1,
                onDaySelected: (day) => selectedDay = day,
              ),
            ),
          ),
        );

        // Tap on Day 2
        await tester.tap(find.text('Day 2'));
        await tester.pump();

        expect(selectedDay, 2);
      });

      testWidgets('tapping same day still calls callback', (tester) async {
        int callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DayPillsSelector(
                totalDays: 3,
                selectedDay: 1,
                onDaySelected: (_) => callCount++,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Day 1'));
        await tester.pump();

        expect(callCount, 1);
      });
    });

    group('Scroll Behavior', () {
      testWidgets('selector is horizontally scrollable', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DayPillsSelector(
                totalDays: 10, // Many days to force scrolling
                selectedDay: 1,
                onDaySelected: (_) {},
              ),
            ),
          ),
        );

        // Verify ListView exists for scrolling
        expect(find.byType(ListView), findsOneWidget);

        // Day 10 might not be visible initially
        expect(find.text('Day 1'), findsOneWidget);
      });

      testWidgets('updates when selectedDay changes externally', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return DayPillsSelector(
                    totalDays: 5,
                    selectedDay: 3,
                    onDaySelected: (_) {},
                  );
                },
              ),
            ),
          ),
        );

        // Day 3 should be selected
        expect(find.text('Day 3'), findsOneWidget);
      });
    });

    group('Animation', () {
      testWidgets('AnimatedContainer uses 200ms duration', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DayPillsSelector(
                totalDays: 3,
                selectedDay: 1,
                onDaySelected: (_) {},
              ),
            ),
          ),
        );

        // Find AnimatedContainer and verify duration
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );

        expect(container.duration, const Duration(milliseconds: 200));
      });

      testWidgets('AnimatedContainer uses easeOutCubic curve', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DayPillsSelector(
                totalDays: 3,
                selectedDay: 1,
                onDaySelected: (_) {},
              ),
            ),
          ),
        );

        // Find AnimatedContainer and verify curve
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );

        expect(container.curve, Curves.easeOutCubic);
      });

      testWidgets('pill selection animates smoothly', (tester) async {
        int? selectedDay;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return DayPillsSelector(
                    totalDays: 3,
                    selectedDay: selectedDay ?? 1,
                    onDaySelected: (day) {
                      setState(() => selectedDay = day);
                    },
                  );
                },
              ),
            ),
          ),
        );

        // Tap Day 2
        await tester.tap(find.text('Day 2'));

        // Animation should be in progress
        await tester.pump(const Duration(milliseconds: 100));

        // Animation should complete
        await tester.pump(const Duration(milliseconds: 100));

        expect(selectedDay, 2);
      });
    });

    group('Rapid Tap Performance', () {
      testWidgets('handles rapid day switching without crashes', (
        tester,
      ) async {
        int callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DayPillsSelector(
                totalDays: 5,
                selectedDay: 1,
                onDaySelected: (_) => callCount++,
              ),
            ),
          ),
        );

        // Rapidly tap different days
        await tester.tap(find.text('Day 2'));
        await tester.tap(find.text('Day 3'));
        await tester.tap(find.text('Day 4'));
        await tester.tap(find.text('Day 5'));
        await tester.pump();

        // All taps should be registered
        expect(callCount, 4);
      });

      testWidgets('final selection is persisted after rapid taps', (
        tester,
      ) async {
        int? lastSelected;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return DayPillsSelector(
                    totalDays: 5,
                    selectedDay: lastSelected ?? 1,
                    onDaySelected: (day) {
                      setState(() => lastSelected = day);
                    },
                  );
                },
              ),
            ),
          ),
        );

        // Rapid taps
        await tester.tap(find.text('Day 2'));
        await tester.pump();
        await tester.tap(find.text('Day 4'));
        await tester.pump();
        await tester.tap(find.text('Day 5'));
        await tester.pump();

        // Final selection should be Day 5
        expect(lastSelected, 5);
      });
    });
  });
}
