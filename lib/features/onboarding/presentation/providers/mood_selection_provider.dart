import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/features/onboarding/domain/entities/mood.dart';

/// State for mood selection during onboarding
///
/// Tracks which moods the user has selected.
/// Uses immutable Set pattern for state management.
class MoodSelectionState {
  const MoodSelectionState({this.selectedMoods = const {}});

  /// Set of currently selected moods
  final Set<Mood> selectedMoods;

  /// Whether at least one mood is selected
  bool get hasSelection => selectedMoods.isNotEmpty;

  /// Number of selected moods
  int get selectionCount => selectedMoods.length;

  /// Check if a specific mood is selected
  bool isSelected(Mood mood) => selectedMoods.contains(mood);

  /// Creates a copy with updated selected moods
  MoodSelectionState copyWith({Set<Mood>? selectedMoods}) {
    return MoodSelectionState(
      selectedMoods: selectedMoods ?? this.selectedMoods,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MoodSelectionState &&
        other.selectedMoods.length == selectedMoods.length &&
        other.selectedMoods.containsAll(selectedMoods);
  }

  @override
  int get hashCode => selectedMoods.hashCode;
}

/// Notifier for managing mood selection state
///
/// Provides methods to toggle mood selection during onboarding.
/// Uses Riverpod 3.x Notifier pattern for sync state management.
class MoodSelectionNotifier extends Notifier<MoodSelectionState> {
  @override
  MoodSelectionState build() => const MoodSelectionState();

  /// Toggle a mood's selection state
  ///
  /// If the mood is already selected, it will be deselected.
  /// If not selected, it will be added to the selection.
  void toggleMood(Mood mood) {
    final currentSet = Set<Mood>.from(state.selectedMoods);
    if (currentSet.contains(mood)) {
      currentSet.remove(mood);
    } else {
      currentSet.add(mood);
    }
    state = state.copyWith(selectedMoods: currentSet);
  }

  /// Select a mood (add to selection)
  void selectMood(Mood mood) {
    if (state.isSelected(mood)) return;
    final newSet = Set<Mood>.from(state.selectedMoods)..add(mood);
    state = state.copyWith(selectedMoods: newSet);
  }

  /// Deselect a mood (remove from selection)
  void deselectMood(Mood mood) {
    if (!state.isSelected(mood)) return;
    final newSet = Set<Mood>.from(state.selectedMoods)..remove(mood);
    state = state.copyWith(selectedMoods: newSet);
  }

  /// Clear all selected moods
  void clearSelection() {
    state = const MoodSelectionState();
  }
}

/// Provider for mood selection state
///
/// Usage:
/// ```dart
/// final selectedMoods = ref.watch(moodSelectionProvider).selectedMoods;
/// ref.read(moodSelectionProvider.notifier).toggleMood(Mood.healing);
/// ```
final moodSelectionProvider =
    NotifierProvider<MoodSelectionNotifier, MoodSelectionState>(
      MoodSelectionNotifier.new,
    );
