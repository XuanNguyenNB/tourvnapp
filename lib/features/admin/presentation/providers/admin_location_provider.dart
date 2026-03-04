import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../destination/data/repositories/destination_repository.dart';
import '../../../destination/domain/entities/location.dart';
import '../../../destination/presentation/providers/destination_provider.dart';
import 'paginated_admin_provider.dart';

/// Page size for location list pagination.
const _kPageSize = 20;

/// Paginated notifier for admin location management.
///
/// Loads locations in pages of [_kPageSize] using Firestore cursor-based
/// pagination, reducing initial load time and memory usage on web.
class AdminLocationNotifier extends Notifier<PaginatedState<Location>> {
  late final DestinationRepository _repository;
  bool _hasFixedData = false;

  @override
  PaginatedState<Location> build() {
    _repository = ref.watch(destinationRepositoryProvider);
    _hasFixedData = false;
    // Kick off first page load
    Future.microtask(() => loadNextPage());
    return const PaginatedState<Location>();
  }

  /// Load the next page of locations from Firestore.
  Future<void> loadNextPage() async {
    final current = state;
    if (current.isLoadingMore || !current.hasMore) return;

    state = current.copyWith(isLoadingMore: true);
    try {
      // One-time data fix on first load
      if (!_hasFixedData) {
        await _repository.fixInconsistentDestinationIds();
        _hasFixedData = true;
      }

      final result = await _repository.getLocationsPaginated(
        limit: _kPageSize,
        startAfter: current.lastDoc,
      );
      state = current.copyWith(
        items: [...current.items, ...result.items],
        lastDoc: result.lastDoc,
        hasMore: result.items.length >= _kPageSize,
        isLoadingMore: false,
        isInitialLoading: false,
      );
    } catch (e) {
      state = current.copyWith(
        isLoadingMore: false,
        error: e.toString(),
        isInitialLoading: false,
      );
    }
  }

  /// Refresh: clear everything and reload from first page.
  Future<void> refresh() async {
    state = const PaginatedState<Location>();
    await loadNextPage();
  }

  /// Add a location optimistically.
  Future<void> addLocation(Location location) async {
    try {
      await _repository.createLocation(location);
      state = state.copyWith(items: [...state.items, location]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Update a location optimistically.
  Future<void> updateLocationData(Location location) async {
    try {
      await _repository.updateLocation(location);
      state = state.copyWith(
        items: state.items
            .map((l) => l.id == location.id ? location : l)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Delete a single location optimistically.
  Future<void> deleteLocationData(String id) async {
    try {
      await _repository.deleteLocation(id);
      state = state.copyWith(
        items: state.items.where((l) => l.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Delete multiple locations optimistically.
  Future<void> deleteBatch(List<String> ids) async {
    try {
      await _repository.deleteLocationBatch(ids);
      final idSet = ids.toSet();
      state = state.copyWith(
        items: state.items.where((l) => !idSet.contains(l.id)).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final adminLocationProvider =
    NotifierProvider<AdminLocationNotifier, PaginatedState<Location>>(() {
      return AdminLocationNotifier();
    });

/// Notifier to manage the selected destination filter
class SelectedDestinationFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? destinationId) {
    state = destinationId;
  }
}

final selectedDestinationFilterProvider =
    NotifierProvider<SelectedDestinationFilterNotifier, String?>(() {
      return SelectedDestinationFilterNotifier();
    });
