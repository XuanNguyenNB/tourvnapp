import '../../../../core/exceptions/app_exception.dart';
import '../../domain/entities/example_item.dart';

/// Example repository demonstrating data layer patterns
///
/// In real implementation, this would interact with:
/// - Cloud Firestore for persistent storage
/// - Local cache for offline support
/// - API endpoints for external data
///
/// For this example, we use in-memory mock data to demonstrate
/// AsyncNotifier provider patterns without Firebase dependencies
class ExampleRepository {
  // Simulate network delay
  static const _networkDelay = Duration(milliseconds: 800);

  // Mock in-memory data store
  final List<ExampleItem> _items = [
    const ExampleItem(
      id: '1',
      name: 'Learn Riverpod AsyncNotifier',
      description: 'Understand how to manage async state with Riverpod 3.2.0',
      isCompleted: true,
    ),
    const ExampleItem(
      id: '2',
      name: 'Implement ConsumerWidget',
      description: 'Create reactive UI that responds to provider state changes',
      isCompleted: false,
    ),
    const ExampleItem(
      id: '3',
      name: 'Handle Loading & Error States',
      description: 'Use .when() method to handle all AsyncValue states',
      isCompleted: false,
    ),
  ];

  /// Fetch all items (simulates Firestore query)
  Future<List<ExampleItem>> getItems() async {
    await Future.delayed(_networkDelay);
    // Return a copy to prevent external modification
    return List.unmodifiable(_items);
  }

  /// Add new item (simulates Firestore add)
  Future<void> addItem(ExampleItem item) async {
    await Future.delayed(_networkDelay);
    _items.add(item);
  }

  /// Update existing item (simulates Firestore update)
  Future<void> updateItem(ExampleItem item) async {
    await Future.delayed(_networkDelay);
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
    } else {
      throw AppException(
        code: 'ITEM_NOT_FOUND',
        message: 'Không tìm thấy mục',
        details: 'Example item ${item.id} not found for update',
      );
    }
  }

  /// Delete item (simulates Firestore delete)
  Future<void> deleteItem(String itemId) async {
    await Future.delayed(_networkDelay);
    final initialLength = _items.length;
    _items.removeWhere((item) => item.id == itemId);
    if (_items.length == initialLength) {
      throw AppException(
        code: 'ITEM_NOT_FOUND',
        message: 'Không tìm thấy mục',
        details: 'Example item $itemId not found for deletion',
      );
    }
  }

  /// Toggle item completion status
  Future<void> toggleItem(String itemId) async {
    await Future.delayed(_networkDelay);
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        isCompleted: !_items[index].isCompleted,
      );
    } else {
      throw AppException(
        code: 'ITEM_NOT_FOUND',
        message: 'Không tìm thấy mục',
        details: 'Example item $itemId not found for toggle',
      );
    }
  }
}
