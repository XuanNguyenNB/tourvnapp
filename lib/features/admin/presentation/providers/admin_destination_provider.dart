import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../destination/data/repositories/destination_repository.dart';
import '../../../destination/domain/entities/destination.dart';
import '../../../destination/presentation/providers/destination_provider.dart';
import 'paginated_admin_provider.dart';

/// Page size for destination list pagination.
const _kPageSize = 100;

/// Paginated notifier for admin destination management.
class AdminDestinationNotifier extends Notifier<PaginatedState<Destination>> {
  late final DestinationRepository _repository;

  @override
  PaginatedState<Destination> build() {
    _repository = ref.watch(destinationRepositoryProvider);
    Future.microtask(() => loadNextPage());
    return const PaginatedState<Destination>();
  }

  /// Load the next page of destinations from Firestore.
  Future<void> loadNextPage() async {
    final current = state;
    if (current.isLoadingMore || !current.hasMore) return;

    state = current.copyWith(isLoadingMore: true);
    try {
      final result = await _repository.getDestinationsPaginated(
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
    state = const PaginatedState<Destination>();
    await loadNextPage();
  }

  Future<void> addDestination(Destination destination) async {
    try {
      await _repository.createDestination(destination);
      state = state.copyWith(items: [...state.items, destination]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateDestinationData(Destination destination) async {
    try {
      await _repository.updateDestination(destination);
      state = state.copyWith(
        items: state.items.map((d) {
          if (d.id == destination.id) {
            return destination.copyWith(
              postCount: d.postCount,
              engagementCount: d.engagementCount,
              locationCount: d.locationCount,
            );
          }
          return d;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteDestinationData(String id) async {
    try {
      await _repository.deleteDestination(id);
      await ImageUploadService.deleteDestinationHero(id);
      state = state.copyWith(
        items: state.items.where((d) => d.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteBatch(List<String> ids) async {
    try {
      await _repository.deleteDestinationBatch(ids);
      for (final id in ids) {
        await ImageUploadService.deleteDestinationHero(id);
      }
      final idSet = ids.toSet();
      state = state.copyWith(
        items: state.items.where((d) => !idSet.contains(d.id)).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final adminDestinationProvider =
    NotifierProvider<AdminDestinationNotifier, PaginatedState<Destination>>(() {
      return AdminDestinationNotifier();
    });
