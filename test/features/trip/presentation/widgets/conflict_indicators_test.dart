import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/presentation/widgets/conflict_indicators.dart';

void main() {
  group('MultiDestinationBadge', () {
    testWidgets('displays full badge with text in default mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MultiDestinationBadge())),
      );

      // Should display the warning emoji
      expect(find.text('⚠️'), findsOneWidget);
      // Should display the text
      expect(find.text('Đa điểm đến'), findsOneWidget);
    });

    testWidgets('displays compact badge without text when compact=true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MultiDestinationBadge(compact: true)),
        ),
      );

      // Should display the warning emoji
      expect(find.text('⚠️'), findsOneWidget);
      // Should NOT display the text
      expect(find.text('Đa điểm đến'), findsNothing);
    });
  });

  group('TravelTimeWarning', () {
    testWidgets('displays travel time and destination', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TravelTimeWarning(
              fromDestination: 'Hà Nội',
              travelTimeMinutes: 45,
            ),
          ),
        ),
      );

      // Should display the warning emoji
      expect(find.text('⚠️'), findsOneWidget);
      // Should contain formatted travel time
      expect(find.textContaining('45p'), findsOneWidget);
      // Should contain destination
      expect(find.textContaining('Hà Nội'), findsOneWidget);
    });

    testWidgets('formats hours correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TravelTimeWarning(
              fromDestination: 'Đà Nẵng',
              travelTimeMinutes: 120,
            ),
          ),
        ),
      );

      // 120 minutes should be displayed as "2h"
      expect(find.textContaining('2h'), findsOneWidget);
      expect(find.textContaining('Đà Nẵng'), findsOneWidget);
    });

    testWidgets('formats hours and minutes correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TravelTimeWarning(
              fromDestination: 'Đà Lạt',
              travelTimeMinutes: 90,
            ),
          ),
        ),
      );

      // 90 minutes should be displayed as "1h30p"
      expect(find.textContaining('1h30p'), findsOneWidget);
    });
  });

  group('OptimizationSuggestionBanner', () {
    testWidgets('displays suggestion text with activity name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizationSuggestionBanner(
              activityName: 'Chùa Một Cột',
              suggestedDayNumber: 2,
            ),
          ),
        ),
      );

      // Should display suggestion with activity name and day
      expect(find.textContaining('Chùa Một Cột'), findsOneWidget);
      expect(find.textContaining('Ngày 2'), findsOneWidget);
      expect(find.text('💡'), findsOneWidget);
    });

    testWidgets('displays generic text when no suggested day', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizationSuggestionBanner(
              activityName: 'Some Activity',
              suggestedDayNumber: null,
            ),
          ),
        ),
      );

      // Should display generic suggestion
      expect(find.textContaining('tối ưu di chuyển'), findsOneWidget);
    });

    testWidgets('can be dismissed', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizationSuggestionBanner(
              activityName: 'Activity',
              suggestedDayNumber: 2,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      // Find and tap the close icon
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(dismissed, isTrue);
    });

    testWidgets('disappears after dismissing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizationSuggestionBanner(
              activityName: 'Activity',
              suggestedDayNumber: 2,
            ),
          ),
        ),
      );

      // Banner should be visible initially
      expect(find.textContaining('Activity'), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Banner should be gone
      expect(find.textContaining('Activity'), findsNothing);
    });

    testWidgets('disappears when "Để nguyên" is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizationSuggestionBanner(
              activityName: 'Activity',
              suggestedDayNumber: 2,
            ),
          ),
        ),
      );

      // Tap "Để nguyên" button
      await tester.tap(find.text('Để nguyên'));
      await tester.pump();

      // Banner should be gone
      expect(find.textContaining('Activity'), findsNothing);
    });

    testWidgets('shows optimize button when callback provided', (tester) async {
      bool optimized = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizationSuggestionBanner(
              activityName: 'Activity',
              suggestedDayNumber: 2,
              onOptimize: () => optimized = true,
            ),
          ),
        ),
      );

      // Optimize button should be visible
      expect(find.text('Tối ưu lịch trình'), findsOneWidget);

      // Tap it
      await tester.tap(find.text('Tối ưu lịch trình'));
      await tester.pump();

      expect(optimized, isTrue);
    });

    testWidgets('hides optimize button when no callback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizationSuggestionBanner(
              activityName: 'Activity',
              suggestedDayNumber: 2,
              onOptimize: null,
            ),
          ),
        ),
      );

      // Optimize button should NOT be visible
      expect(find.text('Tối ưu lịch trình'), findsNothing);
    });
  });
}
