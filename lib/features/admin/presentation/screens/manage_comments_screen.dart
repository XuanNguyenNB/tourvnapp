import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../review/domain/entities/comment.dart';
import '../providers/admin_comment_provider.dart';
import '../widgets/admin_batch_action_bar.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_error_state.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_page_header.dart';

class ManageCommentsScreen extends ConsumerStatefulWidget {
  const ManageCommentsScreen({super.key});

  @override
  ConsumerState<ManageCommentsScreen> createState() =>
      _ManageCommentsScreenState();
}

class _ManageCommentsScreenState extends ConsumerState<ManageCommentsScreen> {
  final _scrollController = ScrollController();

  static const _statusLabels = {
    'flagged': 'Chờ duyệt',
    'approved': 'Đã duyệt',
    'rejected': 'Đã từ chối',
    'all': 'Tất cả',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminCommentProvider.notifier).loadNextPage();
    }
  }

  Future<void> _confirmDelete(Comment comment) async {
    final confirmed = await AdminConfirmDialog.show(
      context,
      title: 'Xóa bình luận?',
      message: 'Bạn có chắc muốn xóa bình luận của "${comment.userName}"?',
      confirmLabel: 'Xóa',
    );

    if (!confirmed || !mounted) return;

    await ref.read(adminCommentProvider.notifier).deleteComment(comment);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa bình luận')));
  }

  Future<void> _runBatchApprove(List<Comment> comments) async {
    final result = await ref
        .read(adminCommentProvider.notifier)
        .approveBatch(comments);
    if (!mounted) return;
    ref.read(adminCommentProvider.notifier).clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.hasErrors
              ? 'Đã duyệt ${result.succeeded}/${result.processed} bình luận'
              : 'Đã duyệt ${result.succeeded} bình luận',
        ),
      ),
    );
  }

  Future<void> _runBatchDelete(List<Comment> comments) async {
    final confirmed = await AdminConfirmDialog.show(
      context,
      title: 'Xóa hàng loạt?',
      message: 'Bạn có chắc muốn xóa ${comments.length} bình luận đã chọn?',
      confirmLabel: 'Xóa',
    );

    if (!confirmed || !mounted) return;

    final result = await ref
        .read(adminCommentProvider.notifier)
        .deleteBatch(comments);
    if (!mounted) return;
    ref.read(adminCommentProvider.notifier).clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.hasErrors
              ? 'Đã xóa ${result.succeeded}/${result.processed} bình luận'
              : 'Đã xóa ${result.succeeded} bình luận',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminCommentProvider);
    final currentFilter = state.query.filterValue('status') ?? 'flagged';
    final selectedComments = state.items
        .where((comment) => state.selectedIds.contains(comment.id))
        .toList();
    final allSelected =
        state.items.isNotEmpty &&
        state.selectedIds.length == state.items.length &&
        state.selectedIds.containsAll(state.items.map((item) => item.id));

    if (state.isInitialLoading && state.items.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.hasError && state.items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AdminErrorState(
          message: state.errorMessage ?? 'Không thể tải danh sách bình luận',
          onRetry: () => ref.read(adminCommentProvider.notifier).refresh(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            AdminPageHeader(
              title: 'Quản lý Bình luận',
              subtitle:
                  '${state.items.length}${state.hasMore ? '+' : ''} bình luận ở trạng thái "${_statusLabels[currentFilter]}"',
              actions: [
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(adminCommentProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Làm mới'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminFilterBar(
              hasActiveFilters: currentFilter != 'flagged',
              onClearFilters: () => ref
                  .read(adminCommentProvider.notifier)
                  .updateStatusFilter('flagged'),
              children: _statusLabels.entries.map((entry) {
                final selected = currentFilter == entry.key;
                return FilterChip(
                  label: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 13),
                  ),
                  selected: selected,
                  onSelected: (_) => ref
                      .read(adminCommentProvider.notifier)
                      .updateStatusFilter(entry.key),
                  selectedColor: const Color(0xFFEEF2FF),
                  checkmarkColor: const Color(0xFF4F46E5),
                  backgroundColor: Colors.white,
                );
              }).toList(),
            ),
            if (state.hasSelection) ...[
              const SizedBox(height: 16),
              AdminBatchActionBar(
                selectionLabel: 'Đã chọn ${state.selectedIds.length} bình luận',
                onClearSelection: ref
                    .read(adminCommentProvider.notifier)
                    .clearSelection,
                actions: [
                  if (currentFilter == 'flagged')
                    FilledButton.icon(
                      onPressed: () => _runBatchApprove(selectedComments),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Duyệt'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: () => _runBatchDelete(selectedComments),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Xóa'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: state.items.isEmpty
                  ? const AdminEmptyState(
                      icon: Icons.comment_outlined,
                      title: 'Không có bình luận nào',
                      message: 'Thử chuyển bộ lọc hoặc quay lại sau.',
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          _CommentTableHeader(allSelected: allSelected),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: EdgeInsets.zero,
                              itemCount:
                                  state.items.length + (state.hasMore ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  Divider(height: 1, color: Colors.grey[100]),
                              itemBuilder: (context, index) {
                                if (index >= state.items.length) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: state.isLoadingMore
                                          ? const CircularProgressIndicator()
                                          : TextButton.icon(
                                              onPressed: () => ref
                                                  .read(
                                                    adminCommentProvider
                                                        .notifier,
                                                  )
                                                  .loadNextPage(),
                                              icon: const Icon(
                                                Icons.expand_more,
                                              ),
                                              label: const Text('Tải thêm'),
                                            ),
                                    ),
                                  );
                                }

                                final comment = state.items[index];
                                return _CommentRow(
                                  comment: comment,
                                  isSelected: state.selectedIds.contains(
                                    comment.id,
                                  ),
                                  onToggleSelection: () => ref
                                      .read(adminCommentProvider.notifier)
                                      .toggleSelection(comment.id),
                                  onApprove: comment.status == 'flagged'
                                      ? () => ref
                                            .read(adminCommentProvider.notifier)
                                            .approveComment(comment)
                                      : null,
                                  onReject: comment.status == 'flagged'
                                      ? () => ref
                                            .read(adminCommentProvider.notifier)
                                            .rejectComment(comment)
                                      : null,
                                  onDelete: () => _confirmDelete(comment),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTableHeader extends ConsumerWidget {
  const _CommentTableHeader({required this.allSelected});

  final bool allSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Checkbox(
              value: allSelected,
              onChanged: (_) => ref
                  .read(adminCommentProvider.notifier)
                  .toggleSelectAllVisible(),
              activeColor: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            flex: 2,
            child: Text(
              'Người bình luận',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const Expanded(
            flex: 4,
            child: Text(
              'Nội dung',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(
            width: 120,
            child: Text(
              'Lý do gắn cờ',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(
            width: 90,
            child: Text(
              'Trạng thái',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(
            width: 120,
            child: Text(
              'Thao tác',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.comment,
    required this.isSelected,
    required this.onToggleSelection,
    required this.onDelete,
    this.onApprove,
    this.onReject,
  });

  final Comment comment;
  final bool isSelected;
  final VoidCallback onToggleSelection;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggleSelection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? const Color(0xFFEEF2FF) : null,
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onToggleSelection(),
                activeColor: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Text(
                comment.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                comment.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                comment.flagReason ?? '—',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ),
            SizedBox(
              width: 90,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(comment.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel(comment.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(comment.status),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onApprove != null)
                    IconButton(
                      onPressed: onApprove,
                      tooltip: 'Duyệt',
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      color: const Color(0xFF10B981),
                    ),
                  if (onReject != null)
                    IconButton(
                      onPressed: onReject,
                      tooltip: 'Từ chối',
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      color: const Color(0xFFF97316),
                    ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Xóa',
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: const Color(0xFFDC2626),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      default:
        return 'Chờ duyệt';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFF59E0B);
    }
  }
}
