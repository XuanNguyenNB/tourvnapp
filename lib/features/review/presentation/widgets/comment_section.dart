import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/comment.dart';
import '../providers/comment_provider.dart';

/// Comment section widget for displaying and posting comments on a review.
///
/// Includes:
/// - Comment list with avatars, names, and relative timestamps
/// - Input bar at the bottom for posting new comments
/// - Optimistic update support
class CommentSection extends ConsumerStatefulWidget {
  final String reviewId;

  const CommentSection({super.key, required this.reviewId});

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(commentsProvider(widget.reviewId));

    // Listen for flagged comments to show moderation notification
    ref.listen<CommentsState>(
      commentsProvider(widget.reviewId),
      (prev, next) {
        if (next.lastCommentFlagged && !(prev?.lastCommentFlagged ?? false)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bình luận của bạn đang được xét duyệt trước khi hiển thị.',
                      ),
                    ),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFFF59E0B),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      },
    );


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.chat_bubble_outline, size: 20, color: Color(0xFF8B5CF6)),
            const SizedBox(width: 8),
            Text(
              'Bình luận',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            if (commentsState.comments.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${commentsState.comments.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Comment input bar
        _buildInputBar(context),
        const SizedBox(height: 16),

        // Comments list
        if (commentsState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (commentsState.comments.isEmpty)
          _buildEmptyState()
        else
          ...commentsState.comments.map(
            (comment) => _CommentTile(
              comment: comment,
              onDelete: _canDelete(comment)
                  ? () => _deleteComment(comment.id)
                  : null,
            ),
          ),

        // Error message
        if (commentsState.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              commentsState.error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: 'Viết bình luận...',
                hintStyle: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(fontSize: 14),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _submitComment,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Text('💬', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            'Chưa có bình luận nào',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hãy là người đầu tiên bình luận!',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  void _submitComment() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng đăng nhập để bình luận'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Đăng nhập',
            textColor: Colors.white,
            onPressed: () {
              context.pushNamed(AppRoutes.login);
            },
          ),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    ref.read(commentsProvider(widget.reviewId).notifier).addComment(
          userId: user.uid,
          userName: user.displayName ?? 'Người dùng',
          userAvatar: user.photoURL,
          text: text,
        );
    _textController.clear();
    _focusNode.unfocus();
  }

  void _deleteComment(String commentId) {
    HapticFeedback.lightImpact();
    ref.read(commentsProvider(widget.reviewId).notifier).deleteComment(commentId);
  }

  bool _canDelete(Comment comment) {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.uid == comment.userId;
  }
}

/// Individual comment tile widget.
class _CommentTile extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onDelete;

  const _CommentTile({required this.comment, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFEDE9FE),
            backgroundImage: comment.userAvatar != null
                ? NetworkImage(comment.userAvatar!)
                : null,
            child: comment.userAvatar == null
                ? Text(
                    comment.userName.isNotEmpty
                        ? comment.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B5CF6),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.formattedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const Spacer(),
                    if (onDelete != null)
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
