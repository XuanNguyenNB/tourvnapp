/// Example domain entity demonstrating Riverpod state management patterns
///
/// This is a simple immutable entity used to showcase AsyncNotifier provider
/// pattern. In real features, entities would represent business objects like
/// Trip, Destination, Review, etc.
class ExampleItem {
  const ExampleItem({
    required this.id,
    required this.name,
    required this.description,
    this.isCompleted = false,
  });

  final String id;
  final String name;
  final String description;
  final bool isCompleted;

  /// Create a copy of this item with updated fields
  ///
  /// Immutability pattern - never mutate state directly
  ExampleItem copyWith({
    String? id,
    String? name,
    String? description,
    bool? isCompleted,
  }) {
    return ExampleItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExampleItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ExampleItem(id: $id, name: $name, description: $description, isCompleted: $isCompleted)';
}
