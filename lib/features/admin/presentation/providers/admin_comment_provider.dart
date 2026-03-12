import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../review/domain/entities/comment.dart';
import '../../../review/data/repositories/comment_repository.dart';

/// State for admin comment moderation.
class AdminCommentState {
  final List<Comment> comments;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String statusFilter; // 'all', 'flagged', 'approved', 'rejected'

  const AdminCommentState({
    this.comments = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.statusFilter = 'flagged',
  });

  AdminCommentState copyWith({
    List<Comment>? comments,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? statusFilter,
  }) {
    return AdminCommentState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

/// Notifier for managing comments in admin dashboard.
///
/// Uses Riverpod 3.0+ Notifier pattern (same as CommentsNotifier).
class AdminCommentNotifier extends Notifier<AdminCommentState> {
  late CommentRepository _repository;

  @override
  AdminCommentState build() {
    _repository = ref.read(commentRepositoryProvider);
    Future.microtask(() => loadComments());
    return const AdminCommentState(isLoading: true);
  }

  /// Load comments based on current filter.
  Future<void> loadComments() async {
    state = state.copyWith(isLoading: true);

    try {
      final status =
          state.statusFilter == 'all' ? null : state.statusFilter;
      final comments = await _repository.getAllComments(
        status: status,
        limit: 50,
      );
      state = state.copyWith(
        comments: comments,
        isLoading: false,
        hasMore: comments.length >= 50,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Change the status filter and reload.
  void setFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
    loadComments();
  }

  /// Approve a flagged comment.
  Future<void> approveComment(Comment comment) async {
    try {
      await _repository.updateCommentStatus(
        reviewId: comment.reviewId,
        commentId: comment.id,
        status: 'approved',
        moderatedBy: 'admin',
      );
      state = state.copyWith(
        comments: state.comments.map((c) {
          if (c.id == comment.id) {
            return c.copyWith(
              status: 'approved',
              moderatedAt: DateTime.now(),
              moderatedBy: 'admin',
            );
          }
          return c;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Không thể duyệt bình luận: $e');
    }
  }

  /// Reject a flagged comment.
  Future<void> rejectComment(Comment comment) async {
    try {
      await _repository.updateCommentStatus(
        reviewId: comment.reviewId,
        commentId: comment.id,
        status: 'rejected',
        moderatedBy: 'admin',
      );
      state = state.copyWith(
        comments: state.comments.map((c) {
          if (c.id == comment.id) {
            return c.copyWith(
              status: 'rejected',
              moderatedAt: DateTime.now(),
              moderatedBy: 'admin',
            );
          }
          return c;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Không thể từ chối bình luận: $e');
    }
  }

  /// Permanently delete a comment.
  Future<void> deleteComment(Comment comment) async {
    try {
      await _repository.deleteComment(
        comment.reviewId,
        comment.id,
        wasApproved: comment.isVisible,
      );
      state = state.copyWith(
        comments: state.comments.where((c) => c.id != comment.id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Không thể xóa bình luận: $e');
    }
  }

  /// Batch approve multiple comments.
  Future<void> approveBatch(List<Comment> comments) async {
    for (final comment in comments) {
      await approveComment(comment);
    }
  }

  /// Batch delete multiple comments.
  Future<void> deleteBatch(List<Comment> comments) async {
    for (final comment in comments) {
      await deleteComment(comment);
    }
  }
}

/// Provider for admin comment management.
final adminCommentProvider =
    NotifierProvider<AdminCommentNotifier, AdminCommentState>(
  AdminCommentNotifier.new,
);
