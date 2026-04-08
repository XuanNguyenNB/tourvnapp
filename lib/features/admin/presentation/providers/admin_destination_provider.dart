import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../destination/data/repositories/destination_repository.dart';
import '../../../destination/domain/entities/destination.dart';
import '../../../destination/presentation/providers/destination_provider.dart';
import '../models/admin_list_state.dart';

const _kPageSize = 100;

class AdminDestinationNotifier extends Notifier<AdminListState<Destination>> {
  late final DestinationRepository _repository;

  @override
  AdminListState<Destination> build() {
    _repository = ref.watch(destinationRepositoryProvider);
    Future.microtask(refresh);
    return const AdminListState<Destination>(
      query: AdminListQuery(
        pageSize: _kPageSize,
        sortKey: 'name',
        descending: false,
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
      final result = await _repository.fetchAdminDestinations(
        limit: current.query.pageSize,
        startAfter: reset ? null : current.query.cursor,
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

  Future<void> addDestination(Destination destination) async {
    await _repository.createDestination(destination);
    await refresh();
  }

  Future<void> updateDestinationData(Destination destination) async {
    await _repository.updateDestination(destination);
    await refresh();
  }

  Future<void> deleteDestinationData(String id) async {
    await _repository.deleteDestination(id);
    await refresh();
  }

  Future<AdminBulkActionResult> deleteBatch(List<String> ids) async {
    if (ids.isEmpty) return AdminBulkActionResult.empty();

    final errors = <String>[];
    try {
      await _repository.deleteDestinationBatch(ids);
    } catch (error) {
      errors.add(error.toString());
    }

    await refresh();
    return AdminBulkActionResult(
      processed: ids.length,
      succeeded: errors.isEmpty ? ids.length : 0,
      failed: errors.isEmpty ? 0 : ids.length,
      errors: errors,
    );
  }
}

final adminDestinationProvider =
    NotifierProvider<AdminDestinationNotifier, AdminListState<Destination>>(() {
      return AdminDestinationNotifier();
    });
