import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';
import 'package:tour_vn/features/home/presentation/widgets/search_result_item.dart';

void main() {
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
    testWidgets('renders location name with bold 16px text', (tester) async {
      final location = createTestLocation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(location: location, onTap: () {}),
          ),
        ),
      );

      final nameText = find.text('Bánh Mì Phượng');
      expect(nameText, findsOneWidget);

      final text = tester.widget<Text>(nameText);
      expect(text.style?.fontSize, equals(16));
      expect(text.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('renders destination and category as subtitle', (tester) async {
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

      expect(find.textContaining('Đà Nẵng'), findsOneWidget);
      expect(find.textContaining('•'), findsOneWidget);
      expect(find.textContaining('🍜'), findsWidgets);
    });

    testWidgets('displays correct emoji for category', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(
              location: createTestLocation(category: 'stay'),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('🏨'), findsWidgets);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(
              location: createTestLocation(),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('shows chevron icon on the right', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(
              location: createTestLocation(),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('uses destination slug when destinationName is null', (
      tester,
    ) async {
      final location = createTestLocation(destinationName: null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(location: location, onTap: () {}),
          ),
        ),
      );

      expect(find.textContaining('da-nang'), findsOneWidget);
    });
  });
}
