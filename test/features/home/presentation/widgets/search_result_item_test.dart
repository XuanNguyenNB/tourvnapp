import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';
import 'package:tour_vn/features/home/presentation/widgets/search_result_item.dart';

void main() {
  /// Test location for all tests
  Location createTestLocation({
    String id = 'test-loc',
    String destinationId = 'da-nang',
    String name = 'Bánh Mì Phượng',
    String category = 'food',
    String? destinationName,
  }) {
    return Location(
      id: id,
      destinationId: destinationId,
      destinationName: destinationName,
      name: name,
      image: 'https://example.com/image.jpg',
      category: category,
    );
  }

  group('SearchResultItem', () {
    testWidgets('AC4: should render location name with bold 16px text', (
      tester,
    ) async {
      final location = createTestLocation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(location: location, onTap: () {}),
          ),
        ),
      );

      // Find the location name text
      final nameText = find.text('Bánh Mì Phượng');
      expect(nameText, findsOneWidget);

      // Verify text style
      final text = tester.widget<Text>(nameText);
      expect(text.style?.fontSize, equals(16));
      expect(text.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('AC4: should render destination • category as subtitle', (
      tester,
    ) async {
      final location = createTestLocation(
        destinationName: 'Đà Nẵng',
        category: 'food',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(location: location, onTap: () {}),
          ),
        ),
      );

      // Subtitle should contain destination, bullet, and category with emoji
      expect(find.textContaining('Đà Nẵng'), findsOneWidget);
      expect(find.textContaining('•'), findsOneWidget);
      expect(
        find.textContaining('🍜'),
        findsWidgets,
      ); // Emoji appears in both icon and subtitle
    });

    testWidgets('should display correct emoji for food category', (
      tester,
    ) async {
      final location = createTestLocation(category: 'food');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(location: location, onTap: () {}),
          ),
        ),
      );

      // Food emoji container should exist
      expect(find.textContaining('🍜'), findsWidgets);
    });

    testWidgets('should display correct emoji for stay category', (
      tester,
    ) async {
      final location = createTestLocation(category: 'stay');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(location: location, onTap: () {}),
          ),
        ),
      );

      expect(find.textContaining('🏨'), findsWidgets);
    });

    testWidgets('should display correct emoji for places category', (
      tester,
    ) async {
      final location = createTestLocation(category: 'places');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(location: location, onTap: () {}),
          ),
        ),
      );

      expect(find.textContaining('📍'), findsWidgets);
    });

    testWidgets('AC4: should have 64px height', (tester) async {
      final location = createTestLocation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(location: location, onTap: () {}),
          ),
        ),
      );

      // Find the container
      final container = find.byType(Container).first;
      final widget = tester.widget<Container>(container);
      expect(widget.constraints?.maxHeight, equals(64));
    });

    testWidgets('AC6: should call onTap when tapped', (tester) async {
      bool tapped = false;
      final location = createTestLocation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(
              location: location,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('should show chevron icon on the right', (tester) async {
      final location = createTestLocation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(location: location, onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('should handle null destinationName with fallback', (
      tester,
    ) async {
      final location = createTestLocation(
        destinationId: 'da-nang',
        destinationName: null, // Will use fallback from Location entity
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(location: location, onTap: () {}),
          ),
        ),
      );

      // Should use the resolved destination name
      expect(find.textContaining('Đà Nẵng'), findsOneWidget);
    });
  });
}
