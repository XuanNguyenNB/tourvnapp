import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/profanity_filter_service.dart';
import '../../domain/entities/comment.dart';
import '../../data/repositories/comment_repository.dart';

/// State class for the comments of a specific review.
class CommentsState {
  final List<Comment> comments;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final bool hasMore;

  /// Set to true when a comment was flagged (to show user notification).
  final bool lastCommentFlagged;

  const CommentsState({
    this.comments = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.hasMore = true,
    this.lastCommentFlagged = false,
  });

  CommentsState copyWith({
    List<Comment>? comments,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool? hasMore,
    bool? lastCommentFlagged,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      lastCommentFlagged: lastCommentFlagged ?? false,
    );
  }
}

/// Notifier that manages comment state for a specific review.
///
/// Integrates [ProfanityFilterService] to automatically flag comments
/// containing profanity before saving to Firestore.
///
/// Provides: load, addComment, deleteComment
/// with optimistic updates for add operations.
class CommentsNotifier extends Notifier<CommentsState> {
  CommentsNotifier(this.reviewId);
  final String reviewId;

  static const _profanityFilter = ProfanityFilterService();

  @override
  CommentsState build() {
    // Auto-load comments when provider is first watched
    Future.microtask(() => loadComments());
    return const CommentsState(isLoading: true);
  }

  /// Load initial comments (only approved ones).
  Future<void> loadComments() async {
    state = state.copyWith(isLoading: true);
    try {
      final repository = ref.read(commentRepositoryProvider);
      final comments = await repository.getComments(reviewId);
      state = state.copyWith(
        comments: comments,
        isLoading: false,
        hasMore: comments.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add a new comment with profanity checking and optimistic update.
  ///
  /// Flow:
  /// 1. Check text through [ProfanityFilterService]
  /// 2. If clean → status = 'approved', show immediately with optimistic update
  /// 3. If flagged → status = 'flagged', save to Firestore but DON'T show
  ///    in the list. Set [lastCommentFlagged] = true so UI can show a SnackBar.
  Future<void> addComment({
    required String userId,
    required String userName,
    String? userAvatar,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final trimmedText = text.trim();

    // ── Step 1: Check for profanity ──
    final checkResult = _profanityFilter.check(trimmedText);

    final comment = Comment(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      reviewId: reviewId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      text: trimmedText,
      createdAt: DateTime.now(),
      status: checkResult.isFlagged ? 'flagged' : 'approved',
      flagReason: checkResult.isFlagged
          ? checkResult.matchedWords.join(', ')
          : null,
    );

    // ── Step 2: Handle based on moderation status ──
    if (checkResult.isFlagged) {
      // Flagged: save to Firestore but don't show in list
      state = state.copyWith(lastCommentFlagged: true);
      try {
        final repository = ref.read(commentRepositoryProvider);
        await repository.addComment(reviewId, comment);
      } catch (e) {
        state = state.copyWith(
          error: 'Không thể gửi bình luận: ${e.toString()}',
        );
      }
    } else {
      // Clean: optimistic update — show immediately
      state = state.copyWith(
        comments: [comment, ...state.comments],
        lastCommentFlagged: false,
      );

      try {
        final repository = ref.read(commentRepositoryProvider);
        final savedComment = await repository.addComment(reviewId, comment);

        // Replace optimistic comment with server-confirmed one
        final updatedComments = state.comments.map((c) {
          if (c.id == comment.id) return savedComment;
          return c;
        }).toList();

        state = state.copyWith(comments: updatedComments);
      } catch (e) {
        // Revert optimistic update on error
        state = state.copyWith(
          comments:
              state.comments.where((c) => c.id != comment.id).toList(),
          error: 'Không thể gửi bình luận: ${e.toString()}',
        );
      }
    }
  }

  /// Delete a comment with optimistic removal.
  Future<void> deleteComment(String commentId) async {
    // Optimistic: remove immediately
    final removedIndex =
        state.comments.indexWhere((c) => c.id == commentId);
    if (removedIndex == -1) return;

    final removedComment = state.comments[removedIndex];
    state = state.copyWith(
      comments: state.comments.where((c) => c.id != commentId).toList(),
    );

    try {
      final repository = ref.read(commentRepositoryProvider);
      await repository.deleteComment(
        reviewId,
        commentId,
        wasApproved: removedComment.isVisible,
      );
    } catch (e) {
      // Revert on error: re-insert at original position
      final restored = List<Comment>.from(state.comments);
      restored.insert(
        removedIndex.clamp(0, restored.length),
        removedComment,
      );
      state = state.copyWith(
        comments: restored,
        error: 'Không thể xóa bình luận',
      );
    }
  }
}

/// Family provider for comments of a specific review.
///
/// Usage: `ref.watch(commentsProvider('review-id'))`
final commentsProvider =
    NotifierProvider.family<CommentsNotifier, CommentsState, String>(
  (reviewId) => CommentsNotifier(reviewId),
);
