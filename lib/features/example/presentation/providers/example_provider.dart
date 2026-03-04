import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../domain/entities/example_item.dart';
import '../../data/repositories/example_repository.dart';

/// Repository provider - Dependency injection for ExampleRepository
///
/// Provider type: Plain Provider (immutable dependency)
/// Use case: Repositories, services, computed values
/// Pattern: [feature]RepositoryProvider
final exampleRepositoryProvider = Provider<ExampleRepository>((ref) {
  return ExampleRepository();
});

/// AsyncNotifier for managing example items state
///
/// This demonstrates the CORE Riverpod pattern for async state management:
/// - AsyncNotifier: Manages mutable async state
/// - build(): Initial data load (called automatically)
/// - Action methods: Modify state with AsyncValue.guard() for error handling
///
/// Pattern from architecture.md#Implementation-Patterns
class ExampleItemsNotifier extends AsyncNotifier<List<ExampleItem>> {
  @override
  Future<List<ExampleItem>> build() async {
    // Initial data load - called automatically when provider is first accessed
    // This is the equivalent of useEffect(() => {}, []) in React
    try {
      final repository = ref.read(exampleRepositoryProvider);
      return await repository.getItems();
    } on AppException {
      // Already wrapped in AppException - just rethrow
      rethrow;
    } catch (e) {
      // Wrap unexpected errors with AppException
      throw AppException(
        code: AppException.UNKNOWN_ERROR,
        message: AppException.getMessageForCode(AppException.UNKNOWN_ERROR),
        details: 'Error loading example items: $e',
      );
    }
  }

  /// Add new item to the list
  ///
  /// Pattern: AsyncValue.guard() wraps async operation
  /// - Sets state to loading automatically
  /// - Catches errors and wraps in AsyncError
  /// - Returns AsyncData on success
  Future<void> addItem(String name, String description) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(exampleRepositoryProvider);

      // Generate simple ID (in real app, Firestore auto-generates)
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final newItem = ExampleItem(id: id, name: name, description: description);

      await repository.addItem(newItem);

      // Refresh the list by calling build() again
      // Alternative: return [...current list, newItem] for optimistic update
      return build();
    });
  }

  /// Update existing item
  Future<void> updateItem(ExampleItem item) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(exampleRepositoryProvider);
      await repository.updateItem(item);
      return build(); // Refresh list
    });
  }

  /// Delete item from the list
  Future<void> deleteItem(String itemId) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(exampleRepositoryProvider);
      await repository.deleteItem(itemId);
      return build(); // Refresh list
    });
  }

  /// Toggle item completion status
  ///
  /// Demonstrates optimistic update pattern:
  /// 1. Update local state immediately (optimistic)
  /// 2. Make backend call
  /// 3. If it fails, AsyncValue.guard catches and shows error
  Future<void> toggleItem(String itemId) async {
    // Get current data (if available)
    if (!state.hasValue) return;
    final currentItems = state.value!;

    // Optimistic update - UI updates immediately
    final optimisticItems = currentItems.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();

    state = AsyncValue.data(optimisticItems);

    // Backend call - if fails, error state will replace optimistic update
    state = await AsyncValue.guard(() async {
      final repository = ref.read(exampleRepositoryProvider);
      await repository.toggleItem(itemId);
      return build(); // Confirm with fresh data
    });
  }
}

/// ExampleItems provider - Public API for accessing example items state
///
/// Provider type: AsyncNotifierProvider
/// Use case: Async CRUD operations with mutable state
/// Naming: [feature]Provider (as per architecture.md)
///
/// Usage in widgets:
/// ```dart
/// // Watch state
/// final itemsAsync = ref.watch(exampleItemsProvider);
///
/// // Call actions
/// ref.read(exampleItemsProvider.notifier).addItem('name', 'desc');
/// ```
final exampleItemsProvider =
    AsyncNotifierProvider<ExampleItemsNotifier, List<ExampleItem>>(() {
      return ExampleItemsNotifier();
    });
