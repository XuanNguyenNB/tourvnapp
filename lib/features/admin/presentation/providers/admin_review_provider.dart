import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../review/data/repositories/review_repository.dart';
import '../../../review/domain/entities/review.dart';
import '../models/admin_list_state.dart';

const _kPageSize = 50;

class AdminReviewNotifier extends Notifier<AdminListState<Review>> {
  late final ReviewRepository _repository;

  @override
  AdminListState<Review> build() {
    _repository = ref.watch(reviewRepositoryProvider);
    Future.microtask(refresh);
    return const AdminListState<Review>(
      query: AdminListQuery(
        pageSize: _kPageSize,
        sortKey: 'createdAt',
        descending: true,
      ),
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(
      isInitialLoading: state.items.isEmpty,
      isRefreshing: state.items.isNotEmpty,
      isLoadingMore: false,
      hasMore: true,
      query: state.query.copyWith(clearCursor: true),
      selectedIds: const {},
      clearError: true,
    );
    await _load(reset: true);
  }

  Future<void> loadNextPage() => _load(reset: false);

  Future<void> _load({required bool reset}) async {
    final current = state;
    if (!reset && (current.isLoadingMore || !current.hasMore)) return;

    if (!reset) {
      state = current.copyWith(isLoadingMore: true, clearError: true);
    }

    try {
      final result = await _repository.fetchAdminReviews(
        limit: current.query.pageSize,
        startAfter: reset ? null : current.query.cursor,
        destinationId: current.query.filterValue('destinationId'),
        category: current.query.filterValue('category'),
        locationId: current.query.filterValue('locationId'),
        search: current.query.search,
      );

      state = current.copyWith(
        items: reset ? result.items : [...current.items, ...result.items],
        query: current.query.copyWith(
          cursor: result.lastDoc,
          clearCursor: reset && result.lastDoc == null,
        ),
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasMore: current.query.hasSearch ? false : result.lastDoc != null,
        clearError: true,
      );
    } catch (error) {
      state = current.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        errorMessage: error.toString(),
      );
    }
  }

  void updateSearch(String value) {
    state = state.copyWith(
      query: state.query.copyWith(search: value.trim(), clearCursor: true),
      selectedIds: const {},
      hasMore: true,
    );
    Future.microtask(refresh);
  }

  void updateFilter(String key, String? value) {
    final filters = Map<String, String?>.from(state.query.filters);
    if (value == null || value.trim().isEmpty) {
      filters.remove(key);
    } else {
      filters[key] = value;
    }
    state = state.copyWith(
      query: state.query.copyWith(filters: filters, clearCursor: true),
      selectedIds: const {},
      hasMore: true,
    );
    Future.microtask(refresh);
  }

  void clearFilters() {
    state = state.copyWith(
      query: state.query.copyWith(
        search: '',
        filters: const {},
        clearCursor: true,
      ),
      selectedIds: const {},
      hasMore: true,
    );
    Future.microtask(refresh);
  }

  void toggleSelection(String id) {
    final next = {...state.selectedIds};
    if (!next.add(id)) {
      next.remove(id);
    }
    state = state.copyWith(selectedIds: next);
  }

  void toggleSelectAllVisible() {
    final visibleIds = state.items.map((item) => item.id).toSet();
    final allSelected =
        visibleIds.isNotEmpty && state.selectedIds.containsAll(visibleIds);
    state = state.copyWith(selectedIds: allSelected ? const {} : visibleIds);
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: const {});
  }

  Future<void> addReview(Review review) async {
    await _repository.createReview(review);
    await refresh();
  }

  Future<void> updateReviewData(Review review) async {
    await _repository.updateReview(review);
    await refresh();
  }

  Future<void> deleteReviewData(String id) async {
    await _repository.deleteReview(id);
    await refresh();
  }

  Future<AdminBulkActionResult> deleteBatch(List<String> ids) async {
    if (ids.isEmpty) return AdminBulkActionResult.empty();

    try {
      await _repository.deleteReviewBatch(ids);
      await refresh();
      return AdminBulkActionResult(
        processed: ids.length,
        succeeded: ids.length,
        failed: 0,
      );
    } catch (error) {
      await refresh();
      return AdminBulkActionResult(
        processed: ids.length,
        succeeded: 0,
        failed: ids.length,
        errors: [error.toString()],
      );
    }
  }
}

final adminReviewProvider =
    NotifierProvider<AdminReviewNotifier, AdminListState<Review>>(() {
      return AdminReviewNotifier();
    });
