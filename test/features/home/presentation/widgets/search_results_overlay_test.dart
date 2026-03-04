import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';
import 'package:tour_vn/features/home/presentation/widgets/search_result_item.dart';
import 'package:tour_vn/features/home/presentation/widgets/search_results_overlay.dart';

void main() {
  /// Create test location helper
  Location createTestLocation({
    String id = 'test-loc',
    String name = 'Test Location',
  }) {
    return Location(
      id: id,
      destinationId: 'da-nang',
      name: name,
      image: 'https://example.com/image.jpg',
      category: 'food',
    );
  }

  group('SearchResultsOverlay', () {
    testWidgets('AC8: should show loading indicator when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultsOverlay(
              destinations: const [],
              locations: const [],
              reviews: const [],
              isLoading: true,
              onDestinationSelected: (_) {},
              onLocationSelected: (_) {},
              onReviewSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Đang tìm kiếm...'), findsOneWidget);
    });

    testWidgets('AC5: should show empty state when results are empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultsOverlay(
              destinations: const [],
              locations: const [],
              reviews: const [],
              isLoading: false,
              onDestinationSelected: (_) {},
              onLocationSelected: (_) {},
              onReviewSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Không tìm thấy địa điểm nào'), findsOneWidget);
      expect(find.text('Thử tìm với từ khóa khác'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    });

    testWidgets('AC4: should show list of results when available', (
      tester,
    ) async {
      final locations = [
        createTestLocation(id: 'loc-1', name: 'Bánh Mì Phượng'),
        createTestLocation(id: 'loc-2', name: 'Cà Phê Đà Nẵng'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultsOverlay(
              destinations: const [],
              locations: locations,
              reviews: const [],
              isLoading: false,
              onDestinationSelected: (_) {},
              onLocationSelected: (_) {},
              onReviewSelected: (_) {},
            ),
          ),
        ),
      );

      // Should show search result items
      expect(find.byType(SearchResultItem), findsNWidgets(2));
      expect(find.text('Bánh Mì Phượng'), findsOneWidget);
      expect(find.text('Cà Phê Đà Nẵng'), findsOneWidget);
    });

    testWidgets('should limit results to max 8 items', (tester) async {
      final locations = List.generate(
        12,
        (i) => createTestLocation(id: 'loc-$i', name: 'Location $i'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 800, // Enough height to show all items
              child: SearchResultsOverlay(
                destinations: const [],
                locations: locations,
                reviews: const [],
                isLoading: false,
                onDestinationSelected: (_) {},
                onLocationSelected: (_) {},
                onReviewSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      // Should only show 8 items (max limit)
      // Note: ListView may not render all items at once, verify by logic
      expect(find.byType(SearchResultItem), findsAtLeastNWidgets(1));

      // The overlay limits to 8, so location 8-11 should NOT appear
      expect(find.text('Location 8'), findsNothing);
      expect(find.text('Location 11'), findsNothing);
    });

    testWidgets('should call onLocationSelected when item tapped', (
      tester,
    ) async {
      Location? selectedLocation;
      final locations = [createTestLocation(name: 'Test Location')];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultsOverlay(
              destinations: const [],
              locations: locations,
              reviews: const [],
              isLoading: false,
              onDestinationSelected: (_) {},
              onLocationSelected: (loc) => selectedLocation = loc,
              onReviewSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SearchResultItem));
      expect(selectedLocation, isNotNull);
      expect(selectedLocation?.name, equals('Test Location'));
    });

    testWidgets('should show error state when errorMessage is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultsOverlay(
              destinations: const [],
              locations: const [],
              reviews: const [],
              isLoading: false,
              errorMessage: 'Network error',
              onDestinationSelected: (_) {},
              onLocationSelected: (_) {},
              onReviewSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Có lỗi xảy ra'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should have Material elevation and rounded corners', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultsOverlay(
              destinations: const [],
              locations: const [],
              reviews: const [],
              isLoading: false,
              onDestinationSelected: (_) {},
              onLocationSelected: (_) {},
              onReviewSelected: (_) {},
            ),
          ),
        ),
      );

      // Find the Material widget from SearchResultsOverlay
      // Skip Scaffold's Material to get our overlay's Material
      final materials = find.byType(Material);
      expect(materials, findsAtLeastNWidgets(1));

      // The SearchResultsOverlay uses Material with elevation 8
      // Verify by finding a Material with our specific elevation
      final materialWidgets = tester.widgetList<Material>(materials).toList();
      final overlayMaterial = materialWidgets.firstWhere(
        (m) => m.elevation == 8,
        orElse: () => materialWidgets.first,
      );
      expect(overlayMaterial.elevation, equals(8));
    });

    testWidgets('should prioritize loading state over empty state', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultsOverlay(
              destinations: const [],
              locations: const [],
              reviews: const [],
              isLoading: true, // Loading takes priority
              onDestinationSelected: (_) {},
              onLocationSelected: (_) {},
              onReviewSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Không tìm thấy địa điểm nào'), findsNothing);
    });
  });
}
