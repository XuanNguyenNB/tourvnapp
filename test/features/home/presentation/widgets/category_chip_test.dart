import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/home/presentation/widgets/category_chip.dart';

void main() {
  group('CategoryChip', () {
    group('Rendering', () {
      testWidgets('renders with emoji and category name', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CategoryChip(categoryId: 'food', categoryName: 'Ăn uống'),
            ),
          ),
        );

        // Should display emoji + name
        expect(find.text('🍜 Ăn uống'), findsOneWidget);
      });

      testWidgets('renders unselected state correctly', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CategoryChip(
                categoryId: 'food',
                categoryName: 'Ăn uống',
                isSelected: false,
              ),
            ),
          ),
        );

        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        final decoration = container.decoration as BoxDecoration;

        // Unselected: white background with border
        expect(decoration.color, Colors.white);
        expect(decoration.border, isNotNull);
        expect(decoration.boxShadow, isNull);
      });

      testWidgets('renders selected state correctly', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CategoryChip(
                categoryId: 'food',
                categoryName: 'Ăn uống',
                isSelected: true,
              ),
            ),
          ),
        );

        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        final decoration = container.decoration as BoxDecoration;

        // Selected: purple background with shadow, no border
        expect(decoration.color, const Color(0xFF8B5CF6));
        expect(decoration.border, isNull);
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.length, 1);
      });

      testWidgets('text has 13px font size', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CategoryChip(categoryId: 'cafe', categoryName: 'Cafe'),
            ),
          ),
        );

        final textWidget = tester.widget<Text>(find.text('☕ Cafe'));
        expect(textWidget.style?.fontSize, 13.0);
      });

      testWidgets('selected text is white with w600 weight', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CategoryChip(
                categoryId: 'food',
                categoryName: 'Ăn uống',
                isSelected: true,
              ),
            ),
          ),
        );

        final textWidget = tester.widget<Text>(find.text('🍜 Ăn uống'));
        expect(textWidget.style?.color, Colors.white);
        expect(textWidget.style?.fontWeight, FontWeight.w600);
      });

      testWidgets('unselected text is gray with w500 weight', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CategoryChip(
                categoryId: 'food',
                categoryName: 'Ăn uống',
                isSelected: false,
              ),
            ),
          ),
        );

        final textWidget = tester.widget<Text>(find.text('🍜 Ăn uống'));
        expect(textWidget.style?.color, const Color(0xFF64748B));
        expect(textWidget.style?.fontWeight, FontWeight.w500);
      });

      testWidgets('has 18px border radius', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CategoryChip(categoryId: 'food', categoryName: 'Ăn uống'),
            ),
          ),
        );

        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(18));
      });
    });

    group('Interactions', () {
      testWidgets('onTap callback is called when tapped', (
        WidgetTester tester,
      ) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CategoryChip(
                categoryId: 'food',
                categoryName: 'Ăn uống',
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(CategoryChip));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('tapping triggers haptic feedback', (
        WidgetTester tester,
      ) async {
        final List<MethodCall> calls = [];

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            calls.add(methodCall);
            return null;
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CategoryChip(
                categoryId: 'food',
                categoryName: 'Ăn uống',
                onTap: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.byType(CategoryChip));
        await tester.pump();

        // Verify HapticFeedback.lightImpact() was called
        expect(
          calls.any(
            (c) =>
                c.method == 'HapticFeedback.vibrate' &&
                c.arguments == 'HapticFeedbackType.lightImpact',
          ),
          isTrue,
        );
      });

      testWidgets('handles null onTap without crashing', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CategoryChip(
                categoryId: 'food',
                categoryName: 'Ăn uống',
                onTap: null,
              ),
            ),
          ),
        );

        // Should not throw
        await tester.tap(find.byType(CategoryChip));
        await tester.pump();
      });
    });

    group('All Categories', () {
      testWidgets('renders food category', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CategoryChip(categoryId: 'food', categoryName: 'Ăn uống'),
            ),
          ),
        );

        expect(find.text('🍜 Ăn uống'), findsOneWidget);
      });

      testWidgets('renders cafe category', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CategoryChip(categoryId: 'cafe', categoryName: 'Cafe'),
            ),
          ),
        );

        expect(find.text('☕ Cafe'), findsOneWidget);
      });

      testWidgets('renders places category', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CategoryChip(
                categoryId: 'places',
                categoryName: 'Địa điểm',
              ),
            ),
          ),
        );

        expect(find.text('📸 Địa điểm'), findsOneWidget);
      });

      testWidgets('renders stay category', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CategoryChip(categoryId: 'stay', categoryName: 'Lưu trú'),
            ),
          ),
        );

        expect(find.text('🏨 Lưu trú'), findsOneWidget);
      });

      testWidgets('renders unknown category with default emoji', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CategoryChip(
                categoryId: 'unknown',
                categoryName: 'Unknown',
              ),
            ),
          ),
        );

        expect(find.text('📍 Khác'), findsOneWidget);
      });
    });
  });
}
