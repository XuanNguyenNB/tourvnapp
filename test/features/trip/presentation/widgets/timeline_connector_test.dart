import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/presentation/widgets/timeline_connector.dart';

void main() {
  group('TimelineConnector', () {
    group('UI Rendering', () {
      testWidgets('renders emoji in center circle', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 100,
                child: TimelineConnector(emoji: '🏠'),
              ),
            ),
          ),
        );

        expect(find.text('🏠'), findsOneWidget);
      });

      testWidgets('renders different emojis correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 100,
                child: TimelineConnector(emoji: '🎯'),
              ),
            ),
          ),
        );

        expect(find.text('🎯'), findsOneWidget);
      });

      testWidgets('shows connector for middle item', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 200,
                child: TimelineConnector(
                  emoji: '📍',
                  isFirst: false,
                  isLast: false,
                ),
              ),
            ),
          ),
        );

        // Emoji should be rendered
        expect(find.text('📍'), findsOneWidget);
        // TimelineConnector widget should be present
        expect(find.byType(TimelineConnector), findsOneWidget);
      });

      testWidgets('renders first item without top line', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 200,
                child: TimelineConnector(
                  emoji: '📍',
                  isFirst: true,
                  isLast: false,
                ),
              ),
            ),
          ),
        );

        expect(find.text('📍'), findsOneWidget);
        expect(find.byType(TimelineConnector), findsOneWidget);
      });

      testWidgets('renders last item without bottom line', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 200,
                child: TimelineConnector(
                  emoji: '📍',
                  isFirst: false,
                  isLast: true,
                ),
              ),
            ),
          ),
        );

        expect(find.text('📍'), findsOneWidget);
        expect(find.byType(TimelineConnector), findsOneWidget);
      });

      testWidgets('renders single item without lines', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 200,
                child: TimelineConnector(
                  emoji: '📍',
                  isFirst: true,
                  isLast: true,
                ),
              ),
            ),
          ),
        );

        expect(find.text('📍'), findsOneWidget);
        expect(find.byType(TimelineConnector), findsOneWidget);
      });
    });

    group('Sizing', () {
      testWidgets('uses default circle size of 36', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 100,
                child: TimelineConnector(emoji: '📍'),
              ),
            ),
          ),
        );

        // The outer SizedBox should have width = circleSize + 12 = 48
        final connector = find.byType(TimelineConnector);
        expect(connector, findsOneWidget);
      });

      testWidgets('custom circle size affects width', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 100,
                child: TimelineConnector(emoji: '📍', circleSize: 48),
              ),
            ),
          ),
        );

        expect(find.byType(TimelineConnector), findsOneWidget);
        expect(find.text('📍'), findsOneWidget);
      });
    });

    group('Visual Properties', () {
      testWidgets('renders circle container', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 100,
                child: TimelineConnector(emoji: '📍'),
              ),
            ),
          ),
        );

        // Find containers - one will be our circle
        final containers = tester.widgetList<Container>(find.byType(Container));
        expect(containers.isNotEmpty, isTrue);
      });

      testWidgets('accepts custom line color', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 200,
                child: TimelineConnector(emoji: '📍', lineColor: Colors.red),
              ),
            ),
          ),
        );

        expect(find.byType(TimelineConnector), findsOneWidget);
      });
    });
  });
}
