import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/onboarding/domain/entities/mood.dart';
import 'package:tour_vn/features/onboarding/presentation/providers/mood_selection_provider.dart';

void main() {
  group('MoodSelectionState', () {
    test('initial state has empty selection', () {
      const state = MoodSelectionState();
      expect(state.selectedMoods, isEmpty);
      expect(state.hasSelection, isFalse);
      expect(state.selectionCount, equals(0));
    });

    test('isSelected returns true for selected mood', () {
      final state = MoodSelectionState(
        selectedMoods: {Mood.healing, Mood.foodie},
      );
      expect(state.isSelected(Mood.healing), isTrue);
      expect(state.isSelected(Mood.foodie), isTrue);
      expect(state.isSelected(Mood.adventure), isFalse);
    });

    test('hasSelection returns true when moods are selected', () {
      final state = MoodSelectionState(selectedMoods: {Mood.party});
      expect(state.hasSelection, isTrue);
      expect(state.selectionCount, equals(1));
    });

    test('copyWith creates new instance with updated moods', () {
      const original = MoodSelectionState();
      final updated = original.copyWith(selectedMoods: {Mood.healing});

      expect(original.selectedMoods, isEmpty);
      expect(updated.selectedMoods, contains(Mood.healing));
    });

    test('equality works correctly', () {
      final state1 = MoodSelectionState(
        selectedMoods: {Mood.healing, Mood.foodie},
      );
      final state2 = MoodSelectionState(
        selectedMoods: {Mood.foodie, Mood.healing},
      );
      final state3 = MoodSelectionState(selectedMoods: {Mood.adventure});

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });
  });

  group('MoodSelectionNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty', () {
      final state = container.read(moodSelectionProvider);
      expect(state.selectedMoods, isEmpty);
      expect(state.hasSelection, isFalse);
    });

    test('toggleMood adds mood when not selected', () {
      final notifier = container.read(moodSelectionProvider.notifier);

      notifier.toggleMood(Mood.healing);

      final state = container.read(moodSelectionProvider);
      expect(state.selectedMoods, contains(Mood.healing));
      expect(state.selectionCount, equals(1));
    });

    test('toggleMood removes mood when already selected', () {
      final notifier = container.read(moodSelectionProvider.notifier);

      // Add then remove
      notifier.toggleMood(Mood.adventure);
      notifier.toggleMood(Mood.adventure);

      final state = container.read(moodSelectionProvider);
      expect(state.selectedMoods, isNot(contains(Mood.adventure)));
      expect(state.selectionCount, equals(0));
    });

    test('toggleMood supports multiple selections', () {
      final notifier = container.read(moodSelectionProvider.notifier);

      notifier.toggleMood(Mood.healing);
      notifier.toggleMood(Mood.foodie);
      notifier.toggleMood(Mood.photography);

      final state = container.read(moodSelectionProvider);
      expect(state.selectionCount, equals(3));
      expect(state.isSelected(Mood.healing), isTrue);
      expect(state.isSelected(Mood.foodie), isTrue);
      expect(state.isSelected(Mood.photography), isTrue);
    });

    test('selectMood adds mood to selection', () {
      final notifier = container.read(moodSelectionProvider.notifier);

      notifier.selectMood(Mood.party);

      final state = container.read(moodSelectionProvider);
      expect(state.isSelected(Mood.party), isTrue);
    });

    test('selectMood does nothing if already selected', () {
      final notifier = container.read(moodSelectionProvider.notifier);

      notifier.selectMood(Mood.healing);
      notifier.selectMood(Mood.healing); // Should not add duplicate

      final state = container.read(moodSelectionProvider);
      expect(state.selectionCount, equals(1));
    });

    test('deselectMood removes mood from selection', () {
      final notifier = container.read(moodSelectionProvider.notifier);

      notifier.toggleMood(Mood.foodie);
      notifier.deselectMood(Mood.foodie);

      final state = container.read(moodSelectionProvider);
      expect(state.isSelected(Mood.foodie), isFalse);
    });

    test('deselectMood does nothing if not selected', () {
      final notifier = container.read(moodSelectionProvider.notifier);

      notifier.deselectMood(Mood.adventure); // Not selected

      final state = container.read(moodSelectionProvider);
      expect(state.selectedMoods, isEmpty);
    });

    test('clearSelection removes all selected moods', () {
      final notifier = container.read(moodSelectionProvider.notifier);

      // Add some moods
      notifier.toggleMood(Mood.healing);
      notifier.toggleMood(Mood.foodie);
      notifier.toggleMood(Mood.party);

      // Clear all
      notifier.clearSelection();

      final state = container.read(moodSelectionProvider);
      expect(state.selectedMoods, isEmpty);
      expect(state.hasSelection, isFalse);
    });
  });

  group('Mood enum', () {
    test('all moods have correct labels', () {
      expect(Mood.healing.label, equals('Chữa lành'));
      expect(Mood.adventure.label, equals('Phiêu lưu'));
      expect(Mood.foodie.label, equals('Ẩm thực'));
      expect(Mood.photography.label, equals('Chụp ảnh'));
      expect(Mood.party.label, equals('Vui chơi'));
    });

    test('all moods have emojis', () {
      expect(Mood.healing.emoji, equals('🧘'));
      expect(Mood.adventure.emoji, equals('🏔️'));
      expect(Mood.foodie.emoji, equals('🍜'));
      expect(Mood.photography.emoji, equals('📸'));
      expect(Mood.party.emoji, equals('🎉'));
    });

    test('Mood.all returns all 5 moods', () {
      expect(Mood.all.length, equals(5));
      expect(
        Mood.all,
        containsAll([
          Mood.healing,
          Mood.adventure,
          Mood.foodie,
          Mood.photography,
          Mood.party,
        ]),
      );
    });

    test('fromId returns correct mood', () {
      expect(Mood.fromId('healing'), equals(Mood.healing));
      expect(Mood.fromId('adventure'), equals(Mood.adventure));
      expect(Mood.fromId('foodie'), equals(Mood.foodie));
      expect(Mood.fromId('photography'), equals(Mood.photography));
      expect(Mood.fromId('party'), equals(Mood.party));
    });

    test('fromId returns null for invalid id', () {
      expect(Mood.fromId('invalid'), isNull);
      expect(Mood.fromId(''), isNull);
    });

    test('id returns lowercase enum name', () {
      expect(Mood.healing.id, equals('healing'));
      expect(Mood.adventure.id, equals('adventure'));
    });
  });
}
