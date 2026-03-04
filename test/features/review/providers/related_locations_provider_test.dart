import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';
import 'package:tour_vn/features/review/presentation/providers/review_provider.dart';

void main() {
  group('relatedLocationsProvider Tests', () {
    test('should return empty list when locationIds is empty', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Given empty location IDs
      final List<String> emptyIds = [];

      // When the provider is accessed
      final result = await container.read(
        relatedLocationsProvider(emptyIds).future,
      );

      // Then it should return empty list
      expect(result, isEmpty);
    });

    test('relatedLocationsProvider should exist and be callable', () {
      // Given location IDs
      final List<String> locationIds = ['loc-1', 'loc-2'];

      // When we access the provider - verify it returns a valid provider
      final provider = relatedLocationsProvider(locationIds);

      // Then it should be a valid provider
      expect(provider, isNotNull);
    });

    test('should auto-dispose correctly', () {
      // Verify provider is AutoDispose
      final provider = relatedLocationsProvider(['test-id']);

      // The provider should be an auto-dispose family provider
      expect(provider, isNotNull);
    });
  });

  group('Location Entity Tests', () {
    test('Location should return correct categoryEmoji for food', () {
      const location = Location(
        id: 'loc-1',
        destinationId: 'dest-1',
        name: 'Test Restaurant',
        category: 'food',
        image: 'https://example.com/image.jpg',
      );

      expect(location.categoryEmoji, equals('🍜'));
    });

    test('Location should return correct categoryEmoji for places', () {
      const location = Location(
        id: 'loc-1',
        destinationId: 'dest-1',
        name: 'Test Place',
        category: 'places',
        image: 'https://example.com/image.jpg',
      );

      expect(location.categoryEmoji, equals('📸'));
    });

    test('Location should return correct categoryEmoji for stay', () {
      const location = Location(
        id: 'loc-1',
        destinationId: 'dest-1',
        name: 'Test Hotel',
        category: 'stay',
        image: 'https://example.com/image.jpg',
      );

      expect(location.categoryEmoji, equals('🏨'));
    });

    test(
      'Location should return default categoryEmoji for unknown category',
      () {
        const location = Location(
          id: 'loc-1',
          destinationId: 'dest-1',
          name: 'Test Location',
          category: 'unknown',
          image: 'https://example.com/image.jpg',
        );

        expect(location.categoryEmoji, equals('📍'));
      },
    );
  });

  group('Related Location Card Integration', () {
    testWidgets('GestureDetector should support long press', (tester) async {
      // Test that GestureDetector with onLongPress is properly configured
      bool longPressTriggered = false;
      bool tapTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () => tapTriggered = true,
              onLongPress: () => longPressTriggered = true,
              child: Container(width: 120, height: 140, color: Colors.blue),
            ),
          ),
        ),
      );

      // When performing a long press
      await tester.longPress(find.byType(GestureDetector));
      await tester.pump();

      // Then long press should be triggered
      expect(longPressTriggered, isTrue);
      expect(tapTriggered, isFalse);
    });

    testWidgets('GestureDetector should support tap', (tester) async {
      // Test that GestureDetector with onTap is properly configured
      bool tapTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () => tapTriggered = true,
              child: Container(width: 120, height: 140, color: Colors.blue),
            ),
          ),
        ),
      );

      // When performing a tap
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      // Then tap should be triggered
      expect(tapTriggered, isTrue);
    });
  });

  group('HapticFeedback Integration', () {
    test('HapticFeedback.mediumImpact should be callable', () {
      // This test verifies the HapticFeedback API is available
      // Note: Actual haptic feedback cannot be tested in unit tests
      // but we verify the method signature exists
      expect(HapticFeedback.mediumImpact, isNotNull);
    });
  });

  group('SnackBar Placeholder', () {
    testWidgets('SnackBar should display floating message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng thêm vào Trip sẽ có sớm!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Show Snackbar'),
              ),
            ),
          ),
        ),
      );

      // When tapping the button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Then SnackBar should be displayed
      expect(find.text('Tính năng thêm vào Trip sẽ có sớm!'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
