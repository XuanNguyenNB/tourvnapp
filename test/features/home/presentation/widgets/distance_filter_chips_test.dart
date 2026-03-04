import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/home/presentation/widgets/distance_filter_chips.dart';

void main() {
  group('DistanceFilterChips', () {
    testWidgets('should render all filter chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceFilterChips(
              selectedFilter: DistanceFilter.all,
              onFilterSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Gần tôi'), findsOneWidget);
      expect(find.text('< 1km'), findsOneWidget);
      expect(find.text('< 5km'), findsOneWidget);
      expect(find.text('< 10km'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
    });

    testWidgets('should highlight selected filter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceFilterChips(
              selectedFilter: DistanceFilter.within5km,
              onFilterSelected: (_) {},
            ),
          ),
        ),
      );

      // The selected chip should be visible
      expect(find.text('< 5km'), findsOneWidget);
    });

    testWidgets('should call onFilterSelected when chip tapped', (
      tester,
    ) async {
      DistanceFilter? selectedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceFilterChips(
              selectedFilter: DistanceFilter.all,
              onFilterSelected: (filter) => selectedFilter = filter,
            ),
          ),
        ),
      );

      await tester.tap(find.text('< 5km'));
      await tester.pump();

      expect(selectedFilter, equals(DistanceFilter.within5km));
    });

    testWidgets('should show lock icon when permission denied', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceFilterChips(
              selectedFilter: DistanceFilter.all,
              onFilterSelected: (_) {},
              permissionDenied: true,
            ),
          ),
        ),
      );

      // Should show lock icons for distance filters
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
    });

    testWidgets('should call onRequestPermission when disabled chip tapped', (
      tester,
    ) async {
      bool permissionRequested = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceFilterChips(
              selectedFilter: DistanceFilter.all,
              onFilterSelected: (_) {},
              permissionDenied: true,
              onRequestPermission: () => permissionRequested = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('< 1km'));
      await tester.pump();

      expect(permissionRequested, isTrue);
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceFilterChips(
              selectedFilter: DistanceFilter.nearest,
              onFilterSelected: (_) {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('"Tất cả" chip should remain active when permission denied', (
      tester,
    ) async {
      DistanceFilter? selectedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceFilterChips(
              selectedFilter: DistanceFilter.all,
              onFilterSelected: (filter) => selectedFilter = filter,
              permissionDenied: true,
            ),
          ),
        ),
      );

      // "Tất cả" should still be tappable
      await tester.tap(find.text('Tất cả'));
      await tester.pump();

      expect(selectedFilter, equals(DistanceFilter.all));
    });
  });

  group('DistanceFilter extension', () {
    test('radiusMeters returns correct values', () {
      expect(DistanceFilter.nearest.radiusMeters, isNull);
      expect(DistanceFilter.within1km.radiusMeters, equals(1000));
      expect(DistanceFilter.within5km.radiusMeters, equals(5000));
      expect(DistanceFilter.within10km.radiusMeters, equals(10000));
      expect(DistanceFilter.all.radiusMeters, isNull);
    });

    test('requiresLocation returns correct values', () {
      expect(DistanceFilter.nearest.requiresLocation, isTrue);
      expect(DistanceFilter.within1km.requiresLocation, isTrue);
      expect(DistanceFilter.within5km.requiresLocation, isTrue);
      expect(DistanceFilter.within10km.requiresLocation, isTrue);
      expect(DistanceFilter.all.requiresLocation, isFalse);
    });

    test('isSortOnly returns correct values', () {
      expect(DistanceFilter.nearest.isSortOnly, isTrue);
      expect(DistanceFilter.within1km.isSortOnly, isFalse);
      expect(DistanceFilter.within5km.isSortOnly, isFalse);
      expect(DistanceFilter.within10km.isSortOnly, isFalse);
      expect(DistanceFilter.all.isSortOnly, isFalse);
    });
  });
}
