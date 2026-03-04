import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for destination selection during onboarding.
class DestinationSelectionState {
  final Set<String> selectedIds;

  const DestinationSelectionState({this.selectedIds = const {}});

  bool isSelected(String id) => selectedIds.contains(id);
  int get count => selectedIds.length;
  bool get hasSelection => selectedIds.isNotEmpty;
}

/// Notifier for managing destination selection during onboarding.
class DestinationSelectionNotifier extends Notifier<DestinationSelectionState> {
  @override
  DestinationSelectionState build() => const DestinationSelectionState();

  void toggle(String destinationId) {
    final current = Set<String>.from(state.selectedIds);
    if (current.contains(destinationId)) {
      current.remove(destinationId);
    } else {
      current.add(destinationId);
    }
    state = DestinationSelectionState(selectedIds: current);
  }

  void clear() {
    state = const DestinationSelectionState();
  }
}

final destinationSelectionProvider =
    NotifierProvider<DestinationSelectionNotifier, DestinationSelectionState>(
      DestinationSelectionNotifier.new,
    );
