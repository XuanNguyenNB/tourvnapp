import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../destination/data/repositories/category_repository.dart';
import '../../../destination/domain/entities/category.dart';

/// Repository provider
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

/// Admin notifier for full CRUD on categories
class AdminCategoryNotifier extends AsyncNotifier<List<Category>> {
  late CategoryRepository _repository;

  @override
  Future<List<Category>> build() async {
    _repository = ref.watch(categoryRepositoryProvider);
    return _repository.getAllCategories();
  }

  Future<void> addCategory(Category category) async {
    final currentList = state.value ?? [];
    state = const AsyncValue.loading();
    try {
      await _repository.createCategory(category);
      // Optimistic: append to local list instead of refetching all
      state = AsyncValue.data([...currentList, category]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateCategoryData(Category category) async {
    final currentList = state.value ?? [];
    state = const AsyncValue.loading();
    try {
      await _repository.updateCategory(category);
      // Optimistic: replace item in local list
      state = AsyncValue.data(
        currentList.map((c) => c.id == category.id ? category : c).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteCategoryData(String id) async {
    final currentList = state.value ?? [];
    state = const AsyncValue.loading();
    try {
      await _repository.deleteCategory(id);
      // Optimistic: remove from local list
      state = AsyncValue.data(currentList.where((c) => c.id != id).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final adminCategoryProvider =
    AsyncNotifierProvider<AdminCategoryNotifier, List<Category>>(() {
      return AdminCategoryNotifier();
    });

/// Provider for active categories only (used by form dropdowns and filters)
final activeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getActiveCategories();
});

/// Convenience: Map of category ID → Category for fast lookups
final categoryMapProvider = FutureProvider<Map<String, Category>>((ref) async {
  final categories = await ref.watch(activeCategoriesProvider.future);
  return {for (final c in categories) c.id: c};
});
