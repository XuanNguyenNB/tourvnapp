import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for destination filter selection on Home Screen.
///
/// Story 8-7: Tracks which destination pill is selected for filtering.
/// Used by DestinationPillsRow and consumed by HomeFilterProvider (Story 8-9).
class DestinationFilterState {
  /// The ID of the currently selected destination, or null if none.
  final String? selectedDestinationId;

  /// The name of the currently selected destination, or null if none.
  final String? selectedDestinationName;

  /// Creates a DestinationFilterState.
  const DestinationFilterState({
    this.selectedDestinationId,
    this.selectedDestinationName,
  });

  /// Whether a destination is currently selected.
  bool get hasSelection => selectedDestinationId != null;

  /// Check if a specific destination ID is selected.
  bool isSelected(String destinationId) {
    return selectedDestinationId == destinationId;
  }

  /// Creates a copy with modified fields (immutability pattern).
  DestinationFilterState copyWith({
    String? selectedDestinationId,
    String? selectedDestinationName,
    bool clearSelection = false,
  }) {
    if (clearSelection) {
      return const DestinationFilterState();
    }
    return DestinationFilterState(
      selectedDestinationId:
          selectedDestinationId ?? this.selectedDestinationId,
      selectedDestinationName:
          selectedDestinationName ?? this.selectedDestinationName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DestinationFilterState &&
        other.selectedDestinationId == selectedDestinationId &&
        other.selectedDestinationName == selectedDestinationName;
  }

  @override
  int get hashCode =>
      selectedDestinationId.hashCode ^ selectedDestinationName.hashCode;

  @override
  String toString() {
    return 'DestinationFilterState('
        'selectedDestinationId: $selectedDestinationId, '
        'selectedDestinationName: $selectedDestinationName)';
  }
}

/// Notifier for managing destination filter state.
///
/// Provides methods to select, deselect, and toggle destinations.
class DestinationFilterNotifier extends Notifier<DestinationFilterState> {
  @override
  DestinationFilterState build() => const DestinationFilterState();

  /// Select a destination for filtering.
  void selectDestination(String id, String name) {
    state = state.copyWith(
      selectedDestinationId: id,
      selectedDestinationName: name,
    );
  }

  /// Clear the current selection.
  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }

  /// Toggle a destination: select if not selected, deselect if selected.
  void toggleDestination(String id, String name) {
    if (state.selectedDestinationId == id) {
      clearSelection();
    } else {
      selectDestination(id, name);
    }
  }
}

/// Provider for destination filter state.
///
/// Usage:
/// ```dart
/// final filterState = ref.watch(destinationFilterProvider);
/// final notifier = ref.read(destinationFilterProvider.notifier);
/// notifier.toggleDestination('da-nang', 'Đà Nẵng');
/// ```
final destinationFilterProvider =
    NotifierProvider<DestinationFilterNotifier, DestinationFilterState>(
      DestinationFilterNotifier.new,
    );

/// Convenience provider for just the selected destination ID.
///
/// More efficient for widgets that only need to know the selection.
final selectedDestinationIdProvider = Provider<String?>((ref) {
  return ref.watch(
    destinationFilterProvider.select((state) => state.selectedDestinationId),
  );
});

/// Convenience provider for just the selected destination name.
final selectedDestinationNameProvider = Provider<String?>((ref) {
  return ref.watch(
    destinationFilterProvider.select((state) => state.selectedDestinationName),
  );
});
