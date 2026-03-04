import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/home/presentation/providers/category_filter_provider.dart';

void main() {
  group('CategoryFilterState', () {
    group('Initial State', () {
      test('default state has no selection', () {
        const state = CategoryFilterState();

        expect(state.selectedCategoryId, isNull);
        expect(state.selectedCategoryName, isNull);
        expect(state.hasSelection, isFalse);
      });
    });

    group('hasSelection', () {
      test('returns false when no category is selected', () {
        const state = CategoryFilterState();
        expect(state.hasSelection, isFalse);
      });

      test('returns true when a category is selected', () {
        const state = CategoryFilterState(
          selectedCategoryId: 'food',
          selectedCategoryName: 'Ăn uống',
        );
        expect(state.hasSelection, isTrue);
      });
    });

    group('isSelected', () {
      test('returns true for matching category ID', () {
        const state = CategoryFilterState(
          selectedCategoryId: 'food',
          selectedCategoryName: 'Ăn uống',
        );
        expect(state.isSelected('food'), isTrue);
      });

      test('returns false for non-matching category ID', () {
        const state = CategoryFilterState(
          selectedCategoryId: 'food',
          selectedCategoryName: 'Ăn uống',
        );
        expect(state.isSelected('cafe'), isFalse);
      });

      test('returns false when no selection', () {
        const state = CategoryFilterState();
        expect(state.isSelected('food'), isFalse);
      });
    });

    group('copyWith', () {
      test('creates new state with updated category ID', () {
        const state = CategoryFilterState();
        final updated = state.copyWith(
          selectedCategoryId: 'food',
          selectedCategoryName: 'Ăn uống',
        );

        expect(updated.selectedCategoryId, 'food');
        expect(updated.selectedCategoryName, 'Ăn uống');
      });

      test('preserves existing values when not overridden', () {
        const state = CategoryFilterState(
          selectedCategoryId: 'food',
          selectedCategoryName: 'Ăn uống',
        );
        final updated = state.copyWith();

        expect(updated.selectedCategoryId, 'food');
        expect(updated.selectedCategoryName, 'Ăn uống');
      });

      test('clears selection when clearSelection is true', () {
        const state = CategoryFilterState(
          selectedCategoryId: 'food',
          selectedCategoryName: 'Ăn uống',
        );
        final updated = state.copyWith(clearSelection: true);

        expect(updated.selectedCategoryId, isNull);
        expect(updated.selectedCategoryName, isNull);
        expect(updated.hasSelection, isFalse);
      });
    });

    group('Equality', () {
      test('equal states are equal', () {
        const state1 = CategoryFilterState(
          selectedCategoryId: 'food',
          selectedCategoryName: 'Ăn uống',
        );
        const state2 = CategoryFilterState(
          selectedCategoryId: 'food',
          selectedCategoryName: 'Ăn uống',
        );

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('different states are not equal', () {
        const state1 = CategoryFilterState(
          selectedCategoryId: 'food',
          selectedCategoryName: 'Ăn uống',
        );
        const state2 = CategoryFilterState(
          selectedCategoryId: 'cafe',
          selectedCategoryName: 'Cafe',
        );

        expect(state1, isNot(equals(state2)));
      });

      test('empty states are equal', () {
        const state1 = CategoryFilterState();
        const state2 = CategoryFilterState();

        expect(state1, equals(state2));
      });
    });

    group('toString', () {
      test('provides meaningful string representation', () {
        const state = CategoryFilterState(
          selectedCategoryId: 'food',
          selectedCategoryName: 'Ăn uống',
        );

        expect(state.toString(), contains('CategoryFilterState'));
        expect(state.toString(), contains('food'));
        expect(state.toString(), contains('Ăn uống'));
      });
    });
  });

  group('CategoryFilterNotifier', () {
    late ProviderContainer container;
    late CategoryFilterNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(categoryFilterProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('Initial State', () {
      test('starts with no selection', () {
        final state = container.read(categoryFilterProvider);

        expect(state.hasSelection, isFalse);
        expect(state.selectedCategoryId, isNull);
        expect(state.selectedCategoryName, isNull);
      });
    });

    group('selectCategory', () {
      test('updates state with selected category', () {
        notifier.selectCategory('food', 'Ăn uống');

        final state = container.read(categoryFilterProvider);
        expect(state.selectedCategoryId, 'food');
        expect(state.selectedCategoryName, 'Ăn uống');
        expect(state.hasSelection, isTrue);
      });

      test('replaces previous selection (single selection mode)', () {
        notifier.selectCategory('food', 'Ăn uống');
        notifier.selectCategory('cafe', 'Cafe');

        final state = container.read(categoryFilterProvider);
        expect(state.selectedCategoryId, 'cafe');
        expect(state.selectedCategoryName, 'Cafe');
      });
    });

    group('clearSelection', () {
      test('clears current selection', () {
        notifier.selectCategory('food', 'Ăn uống');
        notifier.clearSelection();

        final state = container.read(categoryFilterProvider);
        expect(state.hasSelection, isFalse);
        expect(state.selectedCategoryId, isNull);
      });

      test('no-op when already cleared', () {
        notifier.clearSelection();

        final state = container.read(categoryFilterProvider);
        expect(state.hasSelection, isFalse);
      });
    });

    group('toggleCategory', () {
      test('selects category when not selected', () {
        notifier.toggleCategory('food', 'Ăn uống');

        final state = container.read(categoryFilterProvider);
        expect(state.selectedCategoryId, 'food');
        expect(state.hasSelection, isTrue);
      });

      test('deselects category when already selected', () {
        notifier.toggleCategory('food', 'Ăn uống');
        notifier.toggleCategory('food', 'Ăn uống');

        final state = container.read(categoryFilterProvider);
        expect(state.hasSelection, isFalse);
        expect(state.selectedCategoryId, isNull);
      });

      test('switches to different category', () {
        notifier.toggleCategory('food', 'Ăn uống');
        notifier.toggleCategory('cafe', 'Cafe');

        final state = container.read(categoryFilterProvider);
        expect(state.selectedCategoryId, 'cafe');
        expect(state.selectedCategoryName, 'Cafe');
      });

      test('toggle sequence: select -> switch -> deselect', () {
        // Select food
        notifier.toggleCategory('food', 'Ăn uống');
        expect(
          container.read(categoryFilterProvider).selectedCategoryId,
          'food',
        );

        // Switch to cafe
        notifier.toggleCategory('cafe', 'Cafe');
        expect(
          container.read(categoryFilterProvider).selectedCategoryId,
          'cafe',
        );

        // Deselect cafe
        notifier.toggleCategory('cafe', 'Cafe');
        expect(container.read(categoryFilterProvider).hasSelection, isFalse);
      });
    });
  });

  group('categoryFilterProvider', () {
    test('is a NotifierProvider', () {
      expect(
        categoryFilterProvider,
        isA<NotifierProvider<CategoryFilterNotifier, CategoryFilterState>>(),
      );
    });

    test('can be watched and read', () {
      final container = ProviderContainer();

      // Watch initial state
      final state = container.read(categoryFilterProvider);
      expect(state.hasSelection, isFalse);

      // Modify and read again
      container
          .read(categoryFilterProvider.notifier)
          .selectCategory('food', 'Ăn uống');
      final updatedState = container.read(categoryFilterProvider);
      expect(updatedState.selectedCategoryId, 'food');

      container.dispose();
    });
  });

  group('Convenience Providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('selectedCategoryIdProvider', () {
      test('returns null when no selection', () {
        final id = container.read(selectedCategoryIdProvider);
        expect(id, isNull);
      });

      test('returns selected category ID', () {
        container
            .read(categoryFilterProvider.notifier)
            .selectCategory('food', 'Ăn uống');

        final id = container.read(selectedCategoryIdProvider);
        expect(id, 'food');
      });

      test('updates when selection changes', () {
        container
            .read(categoryFilterProvider.notifier)
            .selectCategory('food', 'Ăn uống');
        expect(container.read(selectedCategoryIdProvider), 'food');

        container
            .read(categoryFilterProvider.notifier)
            .selectCategory('cafe', 'Cafe');
        expect(container.read(selectedCategoryIdProvider), 'cafe');
      });
    });

    group('selectedCategoryNameProvider', () {
      test('returns null when no selection', () {
        final name = container.read(selectedCategoryNameProvider);
        expect(name, isNull);
      });

      test('returns selected category name', () {
        container
            .read(categoryFilterProvider.notifier)
            .selectCategory('food', 'Ăn uống');

        final name = container.read(selectedCategoryNameProvider);
        expect(name, 'Ăn uống');
      });

      test('updates when selection changes', () {
        container
            .read(categoryFilterProvider.notifier)
            .selectCategory('food', 'Ăn uống');
        expect(container.read(selectedCategoryNameProvider), 'Ăn uống');

        container
            .read(categoryFilterProvider.notifier)
            .selectCategory('cafe', 'Cafe');
        expect(container.read(selectedCategoryNameProvider), 'Cafe');
      });
    });
  });
}
