import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../review/data/repositories/review_repository.dart';
import '../../../review/domain/entities/review.dart';
import 'paginated_admin_provider.dart';

/// Page size for review list pagination.
const _kPageSize = 100;

/// Paginated notifier for admin review management.
class AdminReviewNotifier extends Notifier<PaginatedState<Review>> {
  late final ReviewRepository _repository;

  @override
  PaginatedState<Review> build() {
    _repository = ref.watch(reviewRepositoryProvider);
    Future.microtask(() => loadNextPage());
    return const PaginatedState<Review>();
  }

  /// Load the next page of reviews from Firestore.
  Future<void> loadNextPage() async {
    final current = state;
    if (current.isLoadingMore || !current.hasMore) return;

    state = current.copyWith(isLoadingMore: true);
    try {
      final result = await _repository.getReviewsPaginated(
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
    state = const PaginatedState<Review>();
    await loadNextPage();
  }

  Future<void> addReview(Review review) async {
    try {
      await _repository.createReview(review);
      state = state.copyWith(items: [...state.items, review]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateReviewData(Review review) async {
    try {
      await _repository.updateReview(review);
      state = state.copyWith(
        items: state.items.map((r) => r.id == review.id ? review : r).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteReviewData(String id) async {
    try {
      await _repository.deleteReview(id);
      state = state.copyWith(
        items: state.items.where((r) => r.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteBatch(List<String> ids) async {
    try {
      await _repository.deleteReviewBatch(ids);
      final idSet = ids.toSet();
      state = state.copyWith(
        items: state.items.where((r) => !idSet.contains(r.id)).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final adminReviewProvider =
    NotifierProvider<AdminReviewNotifier, PaginatedState<Review>>(() {
      return AdminReviewNotifier();
    });
