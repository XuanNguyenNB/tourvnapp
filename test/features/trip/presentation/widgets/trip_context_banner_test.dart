import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/features/trip/domain/entities/trip.dart';
import 'package:tour_vn/features/trip/presentation/providers/active_trip_provider.dart';
import 'package:tour_vn/features/trip/presentation/widgets/trip_context_banner.dart';

void main() {
  group('TripContextBanner View', () {
    final testTrip = Trip(
      id: 'trip-1',
      userId: 'user-1',
      name: 'Ninh Binh Trip',
      destinationId: 'ninh-binh',
      destinationName: 'Ninh Bình',
      days: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testWidgets('shows banner when active trip is set', (tester) async {
      final container = ProviderContainer();
      container.read(activeTripProvider.notifier).setActiveTrip(testTrip);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: TripContextBanner())),
        ),
      );

      // Verify banner text is displayed
      expect(find.textContaining('Ninh Binh Trip'), findsOneWidget);
    });

    testWidgets('clicking Xong clears active trip provider', (tester) async {
      final container = ProviderContainer();
      container.read(activeTripProvider.notifier).setActiveTrip(testTrip);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: TripContextBanner())),
        ),
      );

      // Verify the banner is showing
      expect(find.textContaining('Ninh Binh Trip'), findsOneWidget);

      // Tap 'Xong'
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();

      // Check the provider's state was cleared
      expect(container.read(activeTripProvider), isNull);
    });
  });
}
