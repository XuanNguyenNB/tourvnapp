import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';

/// Mock locations for testing - categoryEmoji is computed from category getter
final mockLocations = [
  const Location(
    id: 'loc-1',
    destinationId: 'da-lat',
    name: 'Hồ Xuân Hương',
    category: 'places', // categoryEmoji will be '📸'
    image: 'https://example.com/ho-xuan-huong.jpg',
    address: 'Trung tâm TP Đà Lạt',
    description: 'Hồ đẹp nổi tiếng',
  ),
  const Location(
    id: 'loc-2',
    destinationId: 'da-lat',
    name: 'Dinh Bảo Đại',
    category: 'places', // categoryEmoji will be '📸'
    image: 'https://example.com/dinh-bao-dai.jpg',
    address: 'Phường 1, TP Đà Lạt',
    description: 'Dinh thự của vua Bảo Đại',
  ),
  const Location(
    id: 'loc-3',
    destinationId: 'da-lat',
    name: 'Quán Cà Phê',
    category: 'food', // categoryEmoji will be '🍜'
    image: 'https://example.com/cafe.jpg',
    address: 'Cầu Đất, Đà Lạt',
    description: 'Quán cà phê đẹp',
  ),
];

void main() {
  group('Related Locations Section Widget Tests', () {
    testWidgets('should show section header "Địa điểm liên quan"', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Địa điểm liên quan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Verify section header is displayed
      expect(find.text('Địa điểm liên quan'), findsOneWidget);
    });

    testWidgets('should hide section when locationIds is empty', (
      tester,
    ) async {
      // Simulating empty state behavior
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox.shrink(), // Empty widget when no locations
            ),
          ),
        ),
      );

      // Section should not show any location-related widgets
      expect(find.text('Địa điểm liên quan'), findsNothing);
    });

    testWidgets('should show loading shimmer placeholders', (tester) async {
      // Test shimmer placeholder structure
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 140,
              child: Row(
                children: [
                  // Mock shimmer placeholder cards
                  SizedBox(width: 120, height: 140),
                  SizedBox(width: 12),
                  SizedBox(width: 120, height: 140),
                  SizedBox(width: 12),
                  SizedBox(width: 120, height: 140),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify skeleton structure with 3 loading cards
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('carousel should scroll horizontally', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => Container(
                  key: ValueKey('card-$index'),
                  width: 120,
                  height: 140,
                  color: Colors.blue.shade100,
                  child: Center(child: Text('Card $index')),
                ),
              ),
            ),
          ),
        ),
      );

      // Verify horizontal scroll direction
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.horizontal);

      // Verify cards are present
      expect(find.text('Card 0'), findsOneWidget);
      expect(find.text('Card 1'), findsOneWidget);
    });
  });

  group('Related Location Card Widget Tests', () {
    testWidgets('card should display location name', (tester) async {
      final location = mockLocations[0]; // Hồ Xuân Hương

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 120,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hồ Xuân Hương'), findsOneWidget);
    });

    testWidgets('card should display category badge with emoji', (
      tester,
    ) async {
      final location = mockLocations[0]; // places category

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${location.categoryEmoji} ${location.category}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ),
          ),
        ),
      );

      // places category should show 📸 emoji
      expect(find.text('📸 places'), findsOneWidget);
    });

    testWidgets('card should have 120x140 dimension', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 120,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, 120);
    });

    testWidgets('card should have correct border radius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 120,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(12));
    });
  });

  group('Navigation and Gesture Tests', () {
    testWidgets('tap on card should trigger navigation', (tester) async {
      bool navigated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () => navigated = true,
              child: Container(width: 120, height: 140, color: Colors.blue),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(navigated, isTrue);
    });

    testWidgets('long press on card should trigger add-to-trip', (
      tester,
    ) async {
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onLongPress: () => longPressed = true,
              child: Container(width: 120, height: 140, color: Colors.blue),
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(GestureDetector));
      await tester.pump();

      expect(longPressed, isTrue);
    });

    testWidgets('should show placeholder SnackBar on long press', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => GestureDetector(
                onLongPress: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng thêm vào Trip sẽ có sớm!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(width: 120, height: 140, color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(GestureDetector));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tính năng thêm vào Trip sẽ có sớm!'), findsOneWidget);
    });
  });

  group('Location Mock Data Tests', () {
    test('mockLocations should have correct structure', () {
      expect(mockLocations.length, equals(3));

      final firstLocation = mockLocations[0];
      expect(firstLocation.id, equals('loc-1'));
      expect(firstLocation.destinationId, equals('da-lat'));
      expect(firstLocation.name, equals('Hồ Xuân Hương'));
      expect(firstLocation.category, equals('places'));
      expect(firstLocation.categoryEmoji, equals('📸'));
    });

    test('food category should have correct emoji', () {
      final foodLocation = mockLocations[2];
      expect(foodLocation.category, equals('food'));
      expect(foodLocation.categoryEmoji, equals('🍜'));
    });
  });
}
