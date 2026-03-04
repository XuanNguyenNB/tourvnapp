import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/home/presentation/providers/destination_filter_provider.dart';

void main() {
  group('DestinationFilterState', () {
    test('initial state has no selection', () {
      const state = DestinationFilterState();

      expect(state.selectedDestinationId, isNull);
      expect(state.selectedDestinationName, isNull);
      expect(state.hasSelection, isFalse);
    });

    test('hasSelection returns true when destination is selected', () {
      const state = DestinationFilterState(
        selectedDestinationId: 'da-nang',
        selectedDestinationName: 'Đà Nẵng',
      );

      expect(state.hasSelection, isTrue);
    });

    test('isSelected returns true for matching destination ID', () {
      const state = DestinationFilterState(
        selectedDestinationId: 'da-nang',
        selectedDestinationName: 'Đà Nẵng',
      );

      expect(state.isSelected('da-nang'), isTrue);
      expect(state.isSelected('hoi-an'), isFalse);
    });

    test('copyWith updates fields correctly', () {
      const state = DestinationFilterState();

      final updated = state.copyWith(
        selectedDestinationId: 'da-nang',
        selectedDestinationName: 'Đà Nẵng',
      );

      expect(updated.selectedDestinationId, 'da-nang');
      expect(updated.selectedDestinationName, 'Đà Nẵng');
    });

    test('copyWith with clearSelection returns empty state', () {
      const state = DestinationFilterState(
        selectedDestinationId: 'da-nang',
        selectedDestinationName: 'Đà Nẵng',
      );

      final cleared = state.copyWith(clearSelection: true);

      expect(cleared.selectedDestinationId, isNull);
      expect(cleared.selectedDestinationName, isNull);
      expect(cleared.hasSelection, isFalse);
    });

    test('equality works correctly', () {
      const state1 = DestinationFilterState(
        selectedDestinationId: 'da-nang',
        selectedDestinationName: 'Đà Nẵng',
      );
      const state2 = DestinationFilterState(
        selectedDestinationId: 'da-nang',
        selectedDestinationName: 'Đà Nẵng',
      );
      const state3 = DestinationFilterState(
        selectedDestinationId: 'hoi-an',
        selectedDestinationName: 'Hội An',
      );

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('toString provides debug info', () {
      const state = DestinationFilterState(
        selectedDestinationId: 'da-nang',
        selectedDestinationName: 'Đà Nẵng',
      );

      expect(state.toString(), contains('da-nang'));
      expect(state.toString(), contains('Đà Nẵng'));
    });
  });

  group('DestinationFilterNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty', () {
      final state = container.read(destinationFilterProvider);

      expect(state.hasSelection, isFalse);
      expect(state.selectedDestinationId, isNull);
    });

    test('selectDestination updates state', () {
      final notifier = container.read(destinationFilterProvider.notifier);

      notifier.selectDestination('da-nang', 'Đà Nẵng');

      final state = container.read(destinationFilterProvider);
      expect(state.selectedDestinationId, 'da-nang');
      expect(state.selectedDestinationName, 'Đà Nẵng');
    });

    test('clearSelection clears state', () {
      final notifier = container.read(destinationFilterProvider.notifier);

      // First select
      notifier.selectDestination('da-nang', 'Đà Nẵng');
      expect(container.read(destinationFilterProvider).hasSelection, isTrue);

      // Then clear
      notifier.clearSelection();
      expect(container.read(destinationFilterProvider).hasSelection, isFalse);
    });

    test('toggleDestination selects when not selected', () {
      final notifier = container.read(destinationFilterProvider.notifier);

      notifier.toggleDestination('da-nang', 'Đà Nẵng');

      final state = container.read(destinationFilterProvider);
      expect(state.selectedDestinationId, 'da-nang');
    });

    test('toggleDestination deselects when already selected', () {
      final notifier = container.read(destinationFilterProvider.notifier);

      // First toggle to select
      notifier.toggleDestination('da-nang', 'Đà Nẵng');
      expect(
        container.read(destinationFilterProvider).selectedDestinationId,
        'da-nang',
      );

      // Second toggle to deselect
      notifier.toggleDestination('da-nang', 'Đà Nẵng');
      expect(container.read(destinationFilterProvider).hasSelection, isFalse);
    });

    test('toggleDestination switches from one destination to another', () {
      final notifier = container.read(destinationFilterProvider.notifier);

      // Select first destination
      notifier.toggleDestination('da-nang', 'Đà Nẵng');
      expect(
        container.read(destinationFilterProvider).selectedDestinationId,
        'da-nang',
      );

      // Toggle different destination (should switch, not deselect)
      notifier.toggleDestination('hoi-an', 'Hội An');
      expect(
        container.read(destinationFilterProvider).selectedDestinationId,
        'hoi-an',
      );
      expect(
        container.read(destinationFilterProvider).selectedDestinationName,
        'Hội An',
      );
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

    test('selectedDestinationIdProvider returns ID', () {
      final notifier = container.read(destinationFilterProvider.notifier);
      notifier.selectDestination('da-nang', 'Đà Nẵng');

      final id = container.read(selectedDestinationIdProvider);
      expect(id, 'da-nang');
    });

    test('selectedDestinationIdProvider returns null when no selection', () {
      final id = container.read(selectedDestinationIdProvider);
      expect(id, isNull);
    });

    test('selectedDestinationNameProvider returns name', () {
      final notifier = container.read(destinationFilterProvider.notifier);
      notifier.selectDestination('da-nang', 'Đà Nẵng');

      final name = container.read(selectedDestinationNameProvider);
      expect(name, 'Đà Nẵng');
    });
  });
}
