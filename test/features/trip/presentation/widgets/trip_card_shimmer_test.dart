import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/core/widgets/shimmer_placeholder.dart';
import 'package:tour_vn/features/trip/presentation/widgets/trip_card_shimmer.dart';

void main() {
  group('TripCardShimmer', () {
    testWidgets('renders shimmer placeholders', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TripCardShimmer())),
      );

      // Should have multiple shimmer placeholders
      expect(find.byType(ShimmerPlaceholder), findsWidgets);
    });

    testWidgets('has correct structure with container', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TripCardShimmer())),
      );

      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Column), findsWidgets);
    });
  });

  group('TripCardsShimmerList', () {
    testWidgets('displays shimmer cards in ListView', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 800, // Provide enough height to render items
              child: TripCardsShimmerList(itemCount: 3),
            ),
          ),
        ),
      );

      // Should show at least some TripCardShimmer widgets
      expect(find.byType(TripCardShimmer), findsWidgets);
    });

    testWidgets('is scrollable with ListView', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TripCardsShimmerList())),
      );

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('uses default item count of 3', (WidgetTester tester) async {
      const widget = TripCardsShimmerList();
      expect(widget.itemCount, equals(3));
    });
  });
}
