import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/features/review/presentation/widgets/animated_heart_button.dart';

void main() {
  group('AnimatedHeartButton Widget', () {
    Widget createTestWidget({
      String reviewId = 'test-review',
      int initialLikeCount = 10,
      bool initiallyLiked = false,
      bool showCount = true,
      double iconSize = 24,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AnimatedHeartButton(
              reviewId: reviewId,
              initialLikeCount: initialLikeCount,
              initiallyLiked: initiallyLiked,
              showCount: showCount,
              iconSize: iconSize,
            ),
          ),
        ),
      );
    }

    testWidgets('should render with initial state', (tester) async {
      await tester.pumpWidget(
        createTestWidget(initialLikeCount: 10, initiallyLiked: false),
      );

      // Find heart icon
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);

      // Find count text
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('should show filled heart when initially liked', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(initialLikeCount: 10, initiallyLiked: true),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('should hide count when showCount is false', (tester) async {
      await tester.pumpWidget(
        createTestWidget(initialLikeCount: 10, showCount: false),
      );

      expect(find.text('10'), findsNothing);
    });

    testWidgets('should format large counts correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(initialLikeCount: 1500));

      expect(find.text('1.5k'), findsOneWidget);
    });

    testWidgets('should format exact thousands correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(initialLikeCount: 1000));

      expect(find.text('1.0k'), findsOneWidget);
    });

    testWidgets('should use custom icon size', (tester) async {
      await tester.pumpWidget(createTestWidget(iconSize: 32));

      final icon = tester.widget<Icon>(find.byIcon(Icons.favorite_border));
      expect(icon.size, 32);
    });

    testWidgets('should be tappable', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Widget should contain a GestureDetector
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('should have AnimatedSwitcher for icon transition', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });

    testWidgets('should have animation capability', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Widget should contain Row with icon and text
      expect(find.byType(Row), findsWidgets);

      // Check that heart icon exists
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });
  });
}
