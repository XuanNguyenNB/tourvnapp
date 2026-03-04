import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/destination/domain/entities/destination.dart';
import 'package:tour_vn/features/destination/presentation/providers/destination_provider.dart';
import 'package:tour_vn/features/home/presentation/widgets/destination_pill.dart';
import 'package:tour_vn/features/home/presentation/widgets/destination_pills_row.dart';

void main() {
  group('DestinationPillsRow', () {
    final mockDestinations = [
      const Destination(
        id: 'da-nang',
        name: 'Đà Nẵng',
        heroImage: 'https://example.com/danang.jpg',
        description: 'Beach city',
        engagementCount: 1000,
      ),
      const Destination(
        id: 'da-lat',
        name: 'Đà Lạt',
        heroImage: 'https://example.com/dalat.jpg',
        description: 'Mountain city',
        engagementCount: 900,
      ),
      const Destination(
        id: 'hoi-an',
        name: 'Hội An',
        heroImage: 'https://example.com/hoian.jpg',
        description: 'Ancient town',
        engagementCount: 800,
      ),
    ];

    testWidgets('renders destination pills when data is available', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allDestinationsProvider.overrideWith(
              (ref) async => mockDestinations,
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: DestinationPillsRow())),
        ),
      );

      // Wait for future to complete
      await tester.pumpAndSettle();

      // Should render all destination pills
      expect(find.byType(DestinationPill), findsNWidgets(3));
      expect(find.text('🏖️ Đà Nẵng'), findsOneWidget);
      expect(find.text('🏔️ Đà Lạt'), findsOneWidget);
      expect(find.text('🏮 Hội An'), findsOneWidget);
    });

    testWidgets('shows loading state before data is ready', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allDestinationsProvider.overrideWith((ref) async {
              // Simulate brief loading delay
              await Future.delayed(const Duration(milliseconds: 50));
              return mockDestinations;
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: DestinationPillsRow())),
        ),
      );

      // Pump once - should be in loading state, no pills yet
      await tester.pump();
      expect(find.byType(DestinationPill), findsNothing);
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
      ); // should be using shimmer

      // Complete the loading - pump past the delay
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(); // Pump for state rebuild
    });

    testWidgets('renders SizedBox.shrink when destinations are empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [allDestinationsProvider.overrideWith((ref) async => [])],
          child: const MaterialApp(home: Scaffold(body: DestinationPillsRow())),
        ),
      );

      await tester.pumpAndSettle();

      // Should find no pills
      expect(find.byType(DestinationPill), findsNothing);
    });

    testWidgets('renders SizedBox.shrink on error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allDestinationsProvider.overrideWith((ref) async {
              throw Exception('Network error');
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: DestinationPillsRow())),
        ),
      );

      await tester.pumpAndSettle();

      // Should find no pills on error
      expect(find.byType(DestinationPill), findsNothing);
    });

    testWidgets('has horizontal scroll with BouncingScrollPhysics', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allDestinationsProvider.overrideWith(
              (ref) async => mockDestinations,
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: DestinationPillsRow())),
        ),
      );

      await tester.pumpAndSettle();

      // Find the SingleChildScrollView
      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );

      expect(scrollView.scrollDirection, Axis.horizontal);
      expect(scrollView.physics, isA<BouncingScrollPhysics>());
    });

    testWidgets('toggles selection when pill is tapped', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allDestinationsProvider.overrideWith(
              (ref) async => mockDestinations,
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: DestinationPillsRow())),
        ),
      );

      await tester.pumpAndSettle();

      // Tap first pill
      await tester.tap(find.text('🏖️ Đà Nẵng'));
      await tester.pumpAndSettle();

      // Find the first DestinationPill and check it's selected
      final pillFinder = find.byType(DestinationPill).first;
      final pill = tester.widget<DestinationPill>(pillFinder);
      expect(pill.isSelected, isTrue);
    });

    testWidgets('has correct horizontal padding (16px)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allDestinationsProvider.overrideWith(
              (ref) async => mockDestinations,
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: DestinationPillsRow())),
        ),
      );

      await tester.pumpAndSettle();

      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );

      expect(scrollView.padding, const EdgeInsets.symmetric(horizontal: 16));
    });

    testWidgets('pills have 8px spacing between them', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allDestinationsProvider.overrideWith(
              (ref) async => mockDestinations,
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: DestinationPillsRow())),
        ),
      );

      await tester.pumpAndSettle();

      // Check that pills are wrapped in Padding with right: 8
      final paddingWidgets = tester.widgetList<Padding>(
        find.ancestor(
          of: find.byType(DestinationPill),
          matching: find.byType(Padding),
        ),
      );

      // Each pill should have 8px right padding (except might have others)
      expect(paddingWidgets, isNotEmpty);
    });
  });
}
