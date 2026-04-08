import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../review/data/repositories/comment_repository.dart';
import '../../../review/domain/entities/comment.dart';
import '../models/admin_list_state.dart';

const _kPageSize = 50;

class AdminCommentNotifier extends Notifier<AdminListState<Comment>> {
  late final CommentRepository _repository;

  @override
  AdminListState<Comment> build() {
    _repository = ref.read(commentRepositoryProvider);
    Future.microtask(refresh);
    return const AdminListState<Comment>(
      query: AdminListQuery(
        pageSize: _kPageSize,
        sortKey: 'createdAt',
        descending: true,
        filters: {'status': 'flagged'},
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
      final result = await _repository.fetchAdminComments(
        status: _normalizedStatusFilter(current.query.filterValue('status')),
        limit: current.query.pageSize,
        startAfter: reset ? null : current.query.cursor,
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
        hasMore: result.lastDoc != null,
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

  void updateStatusFilter(String filter) {
    final filters = Map<String, String?>.from(state.query.filters)
      ..['status'] = filter;
    state = state.copyWith(
      query: state.query.copyWith(filters: filters, clearCursor: true),
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

  Future<void> approveComment(Comment comment) async {
    await _repository.updateCommentStatus(
      reviewId: comment.reviewId,
      commentId: comment.id,
      status: 'approved',
      moderatedBy: _moderatorName(),
    );
    _applyUpdatedComment(
      comment.copyWith(
        status: 'approved',
        moderatedAt: DateTime.now(),
        moderatedBy: _moderatorName(),
      ),
    );
  }

  Future<void> rejectComment(Comment comment) async {
    await _repository.updateCommentStatus(
      reviewId: comment.reviewId,
      commentId: comment.id,
      status: 'rejected',
      moderatedBy: _moderatorName(),
    );
    _applyUpdatedComment(
      comment.copyWith(
        status: 'rejected',
        moderatedAt: DateTime.now(),
        moderatedBy: _moderatorName(),
      ),
    );
  }

  Future<void> deleteComment(Comment comment) async {
    await _repository.deleteComment(
      comment.reviewId,
      comment.id,
      wasApproved: comment.isVisible,
    );
    state = state.copyWith(
      items: state.items.where((item) => item.id != comment.id).toList(),
      selectedIds: {...state.selectedIds}..remove(comment.id),
    );
  }

  Future<AdminBulkActionResult> approveBatch(List<Comment> comments) {
    return _runBatch(comments, approveComment);
  }

  Future<AdminBulkActionResult> rejectBatch(List<Comment> comments) {
    return _runBatch(comments, rejectComment);
  }

  Future<AdminBulkActionResult> deleteBatch(List<Comment> comments) {
    return _runBatch(comments, deleteComment);
  }

  Future<AdminBulkActionResult> _runBatch(
    List<Comment> comments,
    Future<void> Function(Comment comment) action,
  ) async {
    if (comments.isEmpty) return AdminBulkActionResult.empty();

    var succeeded = 0;
    final errors = <String>[];

    for (final comment in comments) {
      try {
        await action(comment);
        succeeded++;
      } catch (error) {
        errors.add('${comment.userName}: $error');
      }
    }

    return AdminBulkActionResult(
      processed: comments.length,
      succeeded: succeeded,
      failed: comments.length - succeeded,
      errors: errors,
    );
  }

  String _moderatorName() {
    final session = ref.read(appSessionProvider).asData?.value;
    final user = session?.user;
    return user?.displayName ?? user?.email ?? user?.uid ?? 'Quản trị viên';
  }

  String? _normalizedStatusFilter(String? value) {
    if (value == null || value == 'all') return null;
    return value;
  }

  void _applyUpdatedComment(Comment updated) {
    final currentFilter = state.query.filterValue('status');
    final shouldKeep =
        currentFilter == null ||
        currentFilter == 'all' ||
        currentFilter == updated.status;

    state = state.copyWith(
      items: shouldKeep
          ? state.items
                .map((item) => item.id == updated.id ? updated : item)
                .toList()
          : state.items.where((item) => item.id != updated.id).toList(),
      selectedIds: {...state.selectedIds}..remove(updated.id),
    );
  }
}

final adminCommentProvider =
    NotifierProvider<AdminCommentNotifier, AdminListState<Comment>>(
      AdminCommentNotifier.new,
    );
