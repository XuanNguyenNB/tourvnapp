import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/home/domain/utils/category_filter_helper.dart';
import 'package:tour_vn/features/home/presentation/providers/category_filter_provider.dart';
import 'package:tour_vn/features/home/presentation/widgets/category_chip.dart';
import 'package:tour_vn/features/home/presentation/widgets/category_chips_row.dart';

void main() {
  group('CategoryChipsRow', () {
    group('Rendering', () {
      testWidgets('renders all four category chips', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: CategoryChipsRow())),
          ),
        );

        // Should render all 4 categories
        expect(find.byType(CategoryChip), findsNWidgets(4));
        expect(find.text('🍜 Ăn uống'), findsOneWidget);
        expect(find.text('☕ Cafe'), findsOneWidget);
        expect(find.text('📸 Địa điểm'), findsOneWidget);
        expect(find.text('🏨 Lưu trú'), findsOneWidget);
      });

      testWidgets('renders categories in correct order', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: CategoryChipsRow())),
          ),
        );

        final chips = tester
            .widgetList<CategoryChip>(find.byType(CategoryChip))
            .toList();

        expect(chips.length, 4);
        expect(chips[0].categoryId, 'food');
        expect(chips[1].categoryId, 'cafe');
        expect(chips[2].categoryId, 'places');
        expect(chips[3].categoryId, 'stay');
      });

      testWidgets('has fixed height of 40', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: CategoryChipsRow())),
          ),
        );

        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.height, 40.0);
      });

      testWidgets('has horizontal padding of 16px', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: CategoryChipsRow())),
          ),
        );

        final scrollView = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );
        expect(
          scrollView.padding,
          const EdgeInsets.symmetric(horizontal: 16.0),
        );
      });

      testWidgets('uses BouncingScrollPhysics', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: CategoryChipsRow())),
          ),
        );

        final scrollView = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );
        expect(scrollView.physics, isA<BouncingScrollPhysics>());
      });

      testWidgets('has 8px spacing between chips', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: CategoryChipsRow())),
          ),
        );

        // Check padding on chips (all but last should have right padding)
        final paddings = tester
            .widgetList<Padding>(find.byType(Padding))
            .toList();

        // The chips are wrapped in Padding, find ones with right: 8
        final chipPaddings = paddings
            .where(
              (p) =>
                  p.padding is EdgeInsets &&
                  (p.padding as EdgeInsets).right == 8.0,
            )
            .toList();

        // First 3 chips should have right padding of 8
        expect(chipPaddings.length, 3);
      });

      testWidgets('scrolls horizontally', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 200, // Narrow to force scrolling
                  child: CategoryChipsRow(),
                ),
              ),
            ),
          ),
        );

        final scrollView = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );

        expect(scrollView.scrollDirection, Axis.horizontal);
      });
    });

    group('Selection', () {
      testWidgets('all chips start unselected', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: CategoryChipsRow())),
          ),
        );

        final chips = tester
            .widgetList<CategoryChip>(find.byType(CategoryChip))
            .toList();

        for (final chip in chips) {
          expect(chip.isSelected, isFalse);
        }
      });

      testWidgets('tapping chip selects it', (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: CategoryChipsRow())),
          ),
        );

        // Tap food chip
        await tester.tap(find.text('🍜 Ăn uống'));
        await tester.pump();

        // Verify food is selected
        final chips = tester
            .widgetList<CategoryChip>(find.byType(CategoryChip))
            .toList();
        expect(chips[0].isSelected, isTrue); // food
        expect(chips[1].isSelected, isFalse); // cafe
        expect(chips[2].isSelected, isFalse); // places
        expect(chips[3].isSelected, isFalse); // stay
      });

      testWidgets('tapping selected chip deselects it', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: CategoryChipsRow())),
          ),
        );

        // Select food
        await tester.tap(find.text('🍜 Ăn uống'));
        await tester.pump();

        // Verify selected
        var chips = tester
            .widgetList<CategoryChip>(find.byType(CategoryChip))
            .toList();
        expect(chips[0].isSelected, isTrue);

        // Tap again to deselect
        await tester.tap(find.text('🍜 Ăn uống'));
        await tester.pump();

        // Verify deselected
        chips = tester
            .widgetList<CategoryChip>(find.byType(CategoryChip))
            .toList();
        expect(chips[0].isSelected, isFalse);
      });

      testWidgets('selecting different chip changes selection (exclusive)', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: CategoryChipsRow())),
          ),
        );

        // Select food
        await tester.tap(find.text('🍜 Ăn uống'));
        await tester.pump();

        var chips = tester
            .widgetList<CategoryChip>(find.byType(CategoryChip))
            .toList();
        expect(chips[0].isSelected, isTrue); // food selected
        expect(chips[1].isSelected, isFalse);

        // Now select cafe
        await tester.tap(find.text('☕ Cafe'));
        await tester.pump();

        chips = tester
            .widgetList<CategoryChip>(find.byType(CategoryChip))
            .toList();
        expect(chips[0].isSelected, isFalse); // food now deselected
        expect(chips[1].isSelected, isTrue); // cafe now selected
      });
    });

    group('Provider Integration', () {
      testWidgets('updates CategoryFilterProvider on selection', (
        WidgetTester tester,
      ) async {
        late WidgetRef capturedRef;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    capturedRef = ref;
                    return const CategoryChipsRow();
                  },
                ),
              ),
            ),
          ),
        );

        // Initial state: no selection
        var state = capturedRef.read(categoryFilterProvider);
        expect(state.hasSelection, isFalse);

        // Tap food chip
        await tester.tap(find.text('🍜 Ăn uống'));
        await tester.pump();

        // Provider should be updated
        state = capturedRef.read(categoryFilterProvider);
        expect(state.hasSelection, isTrue);
        expect(state.selectedCategoryId, 'food');
        expect(state.selectedCategoryName, 'Ăn uống');
      });

      testWidgets('reflects initial provider state', (
        WidgetTester tester,
      ) async {
        // Pre-select a category
        final container = ProviderContainer();
        container
            .read(categoryFilterProvider.notifier)
            .selectCategory('cafe', 'Cafe');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: Scaffold(body: CategoryChipsRow())),
          ),
        );

        // Cafe should be pre-selected
        final chips = tester
            .widgetList<CategoryChip>(find.byType(CategoryChip))
            .toList();
        expect(chips[0].isSelected, isFalse); // food
        expect(chips[1].isSelected, isTrue); // cafe - pre-selected
        expect(chips[2].isSelected, isFalse); // places
        expect(chips[3].isSelected, isFalse); // stay

        container.dispose();
      });
    });

    group('CategoryFilterHelper Integration', () {
      test('provides correct categories data', () {
        final categories = CategoryFilterHelper.categories;

        expect(categories.length, 4);
        expect(categories[0].id, 'food');
        expect(categories[0].name, 'Ăn uống');
        expect(categories[0].emoji, '🍜');

        expect(categories[1].id, 'cafe');
        expect(categories[1].name, 'Cafe');
        expect(categories[1].emoji, '☕');

        expect(categories[2].id, 'places');
        expect(categories[2].name, 'Địa điểm');
        expect(categories[2].emoji, '📸');

        expect(categories[3].id, 'stay');
        expect(categories[3].name, 'Lưu trú');
        expect(categories[3].emoji, '🏨');
      });
    });
  });
}
