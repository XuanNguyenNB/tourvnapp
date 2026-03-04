import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/activity.dart';
import 'package:tour_vn/features/trip/presentation/widgets/activity_card.dart';

void main() {
  group('ActivityCard', () {
    // Test activity with all fields
    final testActivity = Activity(
      id: 'activity-1',
      locationId: 'loc-1',
      locationName: 'Đà Lạt Central Market',
      emoji: '🛒',
      imageUrl: 'https://example.com/image.jpg',
      timeSlot: 'morning',
      sortOrder: 0,
    );

    group('UI Rendering', () {
      testWidgets('renders activity name correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ActivityCard(activity: testActivity)),
          ),
        );

        expect(find.text('Đà Lạt Central Market'), findsOneWidget);
      });

      testWidgets('renders time slot chip for morning', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ActivityCard(activity: testActivity)),
          ),
        );

        // Morning slot should show "Sáng" with sun emoji
        expect(find.text('Sáng'), findsOneWidget);
        expect(find.text('🌅'), findsOneWidget);
      });

      testWidgets('renders time slot chip for afternoon', (tester) async {
        final afternoonActivity = Activity(
          id: 'activity-2',
          locationId: 'loc-2',
          locationName: 'Test Location',
          emoji: '🎯',
          timeSlot: 'afternoon',
          sortOrder: 1,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ActivityCard(activity: afternoonActivity)),
          ),
        );

        expect(find.text('Chiều'), findsOneWidget);
        expect(find.text('🌤️'), findsOneWidget);
      });

      testWidgets('renders time slot chip for evening', (tester) async {
        final eveningActivity = Activity(
          id: 'activity-3',
          locationId: 'loc-3',
          locationName: 'Night Market',
          emoji: '🌙',
          timeSlot: 'evening',
          sortOrder: 2,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ActivityCard(activity: eveningActivity)),
          ),
        );

        expect(find.text('Tối'), findsOneWidget);
        expect(find.text('🌙'), findsOneWidget);
      });
    });

    group('Interaction', () {
      testWidgets('calls onTap when tapped', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityCard(
                activity: testActivity,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(ActivityCard));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('calls onLongPress when long pressed', (tester) async {
        bool longPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityCard(
                activity: testActivity,
                onLongPress: () => longPressed = true,
              ),
            ),
          ),
        );

        await tester.longPress(find.byType(ActivityCard));
        await tester.pump();

        expect(longPressed, isTrue);
      });

      testWidgets('does not crash when callbacks are null', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ActivityCard(activity: testActivity)),
          ),
        );

        // Should not throw when tapped without callback
        await tester.tap(find.byType(ActivityCard));
        await tester.pump();
      });
    });

    group('Layout', () {
      testWidgets('has proper elevation shadow', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ActivityCard(activity: testActivity)),
          ),
        );

        final material = tester.widget<Material>(
          find
              .ancestor(
                of: find.byType(InkWell),
                matching: find.byType(Material),
              )
              .first,
        );

        expect(material.elevation, 2.0);
      });

      testWidgets('truncates long location names', (tester) async {
        final longNameActivity = Activity(
          id: 'activity-long',
          locationId: 'loc-long',
          locationName:
              'This is a very long location name that should be truncated with ellipsis overflow',
          emoji: '📍',
          timeSlot: 'morning',
          sortOrder: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                child: ActivityCard(activity: longNameActivity),
              ),
            ),
          ),
        );

        final text = tester.widget<Text>(
          find.text(longNameActivity.locationName),
        );

        expect(text.overflow, TextOverflow.ellipsis);
        expect(text.maxLines, 1);
      });
    });

    group('Duration Display', () {
      testWidgets('displays duration when provided', (tester) async {
        final activityWithDuration = Activity(
          id: 'activity-dur',
          locationId: 'loc-dur',
          locationName: 'Test Location',
          emoji: '☕',
          timeSlot: 'afternoon',
          sortOrder: 0,
          estimatedDuration: '1h30m',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ActivityCard(activity: activityWithDuration)),
          ),
        );

        // Should display formatted duration in Vietnamese
        expect(find.text('~1 giờ 30 phút'), findsOneWidget);
        expect(find.byIcon(Icons.schedule), findsOneWidget);
      });

      testWidgets('displays duration in hours only format', (tester) async {
        final activityWithDuration = Activity(
          id: 'activity-dur-2',
          locationId: 'loc-dur-2',
          locationName: 'Test Location 2',
          emoji: '🍜',
          timeSlot: 'noon',
          sortOrder: 1,
          estimatedDuration: '2h',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ActivityCard(activity: activityWithDuration)),
          ),
        );

        expect(find.text('~2 giờ'), findsOneWidget);
      });

      testWidgets('displays duration in minutes only format', (tester) async {
        final activityWithDuration = Activity(
          id: 'activity-dur-3',
          locationId: 'loc-dur-3',
          locationName: 'Test Location 3',
          emoji: '📸',
          timeSlot: 'morning',
          sortOrder: 2,
          estimatedDuration: '30m',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ActivityCard(activity: activityWithDuration)),
          ),
        );

        expect(find.text('~30 phút'), findsOneWidget);
      });

      testWidgets('does not display duration row when null', (tester) async {
        final activityWithoutDuration = Activity(
          id: 'activity-no-dur',
          locationId: 'loc-no-dur',
          locationName: 'No Duration Location',
          emoji: '🏖️',
          timeSlot: 'morning',
          sortOrder: 3,
          // estimatedDuration is null
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityCard(activity: activityWithoutDuration),
            ),
          ),
        );

        // Should NOT find clock icon
        expect(find.byIcon(Icons.schedule), findsNothing);
        // Should NOT find any duration text patterns
        expect(find.textContaining('giờ'), findsNothing);
        expect(find.textContaining('phút'), findsNothing);
      });
    });

    group('Destination Tag Display', () {
      testWidgets('displays destination tag when destinationName is provided', (
        tester,
      ) async {
        final activityWithDestination = Activity(
          id: 'activity-dest',
          locationId: 'loc-dest',
          locationName: 'Bà Nà Hills',
          emoji: '⛰️',
          timeSlot: 'morning',
          sortOrder: 0,
          destinationId: 'da-nang',
          destinationName: 'Đà Nẵng',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityCard(activity: activityWithDestination),
            ),
          ),
        );

        // Should display destination name with location pin emoji
        expect(find.text('📍'), findsOneWidget);
        expect(find.text('Đà Nẵng'), findsOneWidget);
      });

      testWidgets(
        'does not display destination tag when destinationName is null',
        (tester) async {
          final activityWithoutDestination = Activity(
            id: 'activity-no-dest',
            locationId: 'loc-no-dest',
            locationName: 'Legacy Location',
            emoji: '🏛️',
            timeSlot: 'afternoon',
            sortOrder: 1,
            // destinationName is null - legacy data
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ActivityCard(activity: activityWithoutDestination),
              ),
            ),
          );

          // Activity name should still render
          expect(find.text('Legacy Location'), findsOneWidget);
          // But destination pin emoji should NOT be present
          expect(find.text('📍'), findsNothing);
        },
      );

      testWidgets('destination tag uses muted styling', (tester) async {
        final activityWithDestination = Activity(
          id: 'activity-styled',
          locationId: 'loc-styled',
          locationName: 'My Khe Beach',
          emoji: '🏖️',
          timeSlot: 'afternoon',
          sortOrder: 0,
          destinationId: 'da-nang',
          destinationName: 'Đà Nẵng',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityCard(activity: activityWithDestination),
            ),
          ),
        );

        // Find the destination name text widget
        final textFinder = find.text('Đà Nẵng');
        expect(textFinder, findsOneWidget);

        // Verify it's a Text widget with appropriate styling
        final textWidget = tester.widget<Text>(textFinder);
        expect(textWidget.style?.fontSize, 12);
      });

      testWidgets('renders correctly with both destination and duration', (
        tester,
      ) async {
        final activityWithBoth = Activity(
          id: 'activity-both',
          locationId: 'loc-both',
          locationName: 'Marble Mountains',
          emoji: '🏔️',
          timeSlot: 'morning',
          sortOrder: 0,
          estimatedDuration: '2h',
          destinationId: 'da-nang',
          destinationName: 'Đà Nẵng',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ActivityCard(activity: activityWithBoth)),
          ),
        );

        // Activity name
        expect(find.text('Marble Mountains'), findsOneWidget);
        // Destination tag
        expect(find.text('📍'), findsOneWidget);
        expect(find.text('Đà Nẵng'), findsOneWidget);
        // Duration
        expect(find.text('~2 giờ'), findsOneWidget);
        expect(find.byIcon(Icons.schedule), findsOneWidget);
      });
    });
  });
}
