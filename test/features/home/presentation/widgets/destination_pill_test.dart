import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/home/presentation/widgets/destination_pill.dart';

void main() {
  group('DestinationPill', () {
    testWidgets('renders destination name with emoji', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DestinationPill(
              destinationId: 'da-nang',
              destinationName: 'Đà Nẵng',
            ),
          ),
        ),
      );

      // Should show emoji + name
      expect(find.text('🏖️ Đà Nẵng'), findsOneWidget);
    });

    testWidgets('shows default emoji for unknown destination', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DestinationPill(
              destinationId: 'unknown-place',
              destinationName: 'Unknown Place',
            ),
          ),
        ),
      );

      expect(find.text('📍 Unknown Place'), findsOneWidget);
    });

    testWidgets('has unselected styling by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DestinationPill(
              destinationId: 'da-nang',
              destinationName: 'Đà Nẵng',
              isSelected: false,
            ),
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      final decoration = container.decoration as BoxDecoration;

      // Unselected: white background, border
      expect(decoration.color, Colors.white);
      expect(decoration.border, isNotNull);
    });

    testWidgets('has selected styling when isSelected is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DestinationPill(
              destinationId: 'da-nang',
              destinationName: 'Đà Nẵng',
              isSelected: true,
            ),
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      final decoration = container.decoration as BoxDecoration;

      // Selected: purple background, shadow, no border
      expect(decoration.color, const Color(0xFF8B5CF6));
      expect(decoration.border, isNull);
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.length, 1);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DestinationPill(
              destinationId: 'da-nang',
              destinationName: 'Đà Nẵng',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DestinationPill));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not crash when onTap is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DestinationPill(
              destinationId: 'da-nang',
              destinationName: 'Đà Nẵng',
              onTap: null,
            ),
          ),
        ),
      );

      // Should not throw when tapped with null callback
      await tester.tap(find.byType(DestinationPill));
      await tester.pump();
    });

    testWidgets('text style changes based on selection state', (tester) async {
      // Test unselected text color
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DestinationPill(
              destinationId: 'da-nang',
              destinationName: 'Đà Nẵng',
              isSelected: false,
            ),
          ),
        ),
      );

      final unselectedText = tester.widget<Text>(find.byType(Text));
      expect(unselectedText.style?.color, const Color(0xFF64748B));
      expect(unselectedText.style?.fontWeight, FontWeight.w500);

      // Test selected text color
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DestinationPill(
              destinationId: 'da-nang',
              destinationName: 'Đà Nẵng',
              isSelected: true,
            ),
          ),
        ),
      );

      final selectedText = tester.widget<Text>(find.byType(Text));
      expect(selectedText.style?.color, Colors.white);
      expect(selectedText.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('has correct border radius (18px)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DestinationPill(
              destinationId: 'da-nang',
              destinationName: 'Đà Nẵng',
            ),
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(18));
    });

    testWidgets('animates container on state change', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DestinationPill(
              destinationId: 'da-nang',
              destinationName: 'Đà Nẵng',
              isSelected: false,
            ),
          ),
        ),
      );

      // AnimatedContainer should exist
      expect(find.byType(AnimatedContainer), findsOneWidget);

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      // Should have animation duration
      expect(container.duration, const Duration(milliseconds: 200));
    });
  });
}
