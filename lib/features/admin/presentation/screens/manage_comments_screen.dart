import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_comment_provider.dart';
import '../../../review/domain/entities/comment.dart';

/// Admin screen for managing and moderating user comments.
///
/// Features:
/// - Filter by status (flagged / approved / rejected / all)
/// - Approve, reject, or delete individual comments
/// - Batch approve / delete selected comments
/// - Highlight flagged words in comment text
class ManageCommentsScreen extends ConsumerStatefulWidget {
  const ManageCommentsScreen({super.key});

  @override
  ConsumerState<ManageCommentsScreen> createState() =>
      _ManageCommentsScreenState();
}

class _ManageCommentsScreenState extends ConsumerState<ManageCommentsScreen> {
  final Set<String> _selectedIds = {};

  static const _statusLabels = {
    'flagged': '🚩 Chờ duyệt',
    'approved': '✅ Đã duyệt',
    'rejected': '❌ Đã từ chối',
    'all': '📋 Tất cả',
  };

  static const _statusColors = {
    'flagged': Color(0xFFF59E0B),
    'approved': Color(0xFF10B981),
    'rejected': Color(0xFFEF4444),
  };

  void _toggleItem(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll(List<Comment> comments) {
    setState(() {
      final ids = comments.map((c) => c.id).toSet();
      if (_selectedIds.containsAll(ids)) {
        _selectedIds.removeAll(ids);
      } else {
        _selectedIds.addAll(ids);
      }
    });
  }

  Future<void> _confirmDelete(Comment comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa bình luận?'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa bình luận này? Không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(adminCommentProvider.notifier).deleteComment(comment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bình luận!')),
        );
      }
    }
  }

  Future<void> _batchApprove() async {
    final adminState = ref.read(adminCommentProvider);
    final selected = adminState.comments
        .where((c) => _selectedIds.contains(c.id))
        .toList();

    await ref.read(adminCommentProvider.notifier).approveBatch(selected);
    setState(() => _selectedIds.clear());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã duyệt ${selected.length} bình luận!')),
      );
    }
  }

  Future<void> _batchDelete() async {
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa hàng loạt?'),
        content: Text(
          'Bạn có chắc muốn xóa $count bình luận đã chọn? Không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final adminState = ref.read(adminCommentProvider);
      final selected = adminState.comments
          .where((c) => _selectedIds.contains(c.id))
          .toList();
      setState(() => _selectedIds.clear());
      await ref.read(adminCommentProvider.notifier).deleteBatch(selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa $count bình luận!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminCommentProvider);

    if (adminState.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (adminState.error != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text('Lỗi: ${adminState.error}'),
        ),
      );
    }

    final comments = adminState.comments;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(comments),
          _buildFilterBar(adminState.statusFilter),
          if (_selectedIds.isNotEmpty) _buildBatchBar(),
          Expanded(
            child: comments.isEmpty
                ? _buildEmptyState()
                : _buildCommentList(comments),
          ),
        ],
      ),
    );
  }

  // ── HEADER ──
  Widget _buildHeader(List<Comment> comments) {
    final flaggedCount = comments.where((c) => c.isFlagged).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 24, 36, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Quản lý Bình luận',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  if (flaggedCount > 0) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: Text(
                        '$flaggedCount chờ duyệt',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${comments.length} bình luận',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
          IconButton(
            onPressed: () =>
                ref.read(adminCommentProvider.notifier).loadComments(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FILTER BAR ──
  Widget _buildFilterBar(String currentFilter) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 16, 36, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _statusLabels.entries.map((entry) {
          final isSelected = currentFilter == entry.key;
          return FilterChip(
            label: Text(entry.value, style: const TextStyle(fontSize: 13)),
            selected: isSelected,
            onSelected: (_) {
              ref.read(adminCommentProvider.notifier).setFilter(entry.key);
              setState(() => _selectedIds.clear());
            },
            selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
            checkmarkColor: const Color(0xFF6366F1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : Colors.grey.shade300,
              ),
            ),
            backgroundColor: Colors.white,
          );
        }).toList(),
      ),
    );
  }

  // ── BATCH BAR ──
  Widget _buildBatchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(36, 12, 36, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF6366F1), size: 20),
          const SizedBox(width: 8),
          Text(
            'Đã chọn ${_selectedIds.length} bình luận',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF6366F1),
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () => setState(() => _selectedIds.clear()),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Bỏ chọn', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _batchApprove,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Duyệt', style: TextStyle(fontSize: 13)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _batchDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Xóa', style: TextStyle(fontSize: 13)),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  // ── EMPTY STATE ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_outlined, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Không có bình luận nào',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── COMMENT LIST ──
  Widget _buildCommentList(List<Comment> comments) {
    final allSelected = comments.every((c) => _selectedIds.contains(c.id));

    return Container(
      margin: const EdgeInsets.fromLTRB(36, 16, 36, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Checkbox(
                    value: comments.isNotEmpty && allSelected,
                    onChanged: (_) => _toggleSelectAll(comments),
                    activeColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Người bình luận',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 4,
                  child: Text(
                    'Nội dung',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 120,
                  child: Text(
                    'Lý do gắn cờ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 80,
                  child: Text(
                    'Trạng thái',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 100,
                  child: Text(
                    'Ngày tạo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 130,
                  child: Text(
                    'Thao tác',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Rows
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: comments.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (_, index) => _buildCommentRow(comments[index]),
            ),
          ),
        ],
      ),
    );
  }

  // ── COMMENT ROW ──
  Widget _buildCommentRow(Comment comment) {
    final isSelected = _selectedIds.contains(comment.id);
    final statusColor = _statusColors[comment.status] ?? Colors.grey;

    // Format date
    final dt = comment.createdAt;
    final dateStr =
        '${dt.day}/${dt.month}/${dt.year}\n${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

    return Container(
      color: isSelected
          ? const Color(0xFF6366F1).withValues(alpha: 0.04)
          : null,
      child: InkWell(
        onTap: () => _toggleItem(comment.id),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Checkbox
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleItem(comment.id),
                  activeColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // User info
              Expanded(
                flex: 2,
                child: Row(
                  children: [
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
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF8B5CF6),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        comment.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                flex: 4,
                child: Text(
                  comment.text,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Flag reason
              SizedBox(
                width: 120,
                child: comment.flagReason != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          comment.flagReason!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : Text(
                        '—',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
              ),
              // Status badge
              SizedBox(
                width: 80,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      comment.status == 'flagged'
                          ? 'Chờ duyệt'
                          : comment.status == 'approved'
                              ? 'Đã duyệt'
                              : 'Từ chối',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ),
              // Date
              SizedBox(
                width: 100,
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              // Actions
              SizedBox(
                width: 130,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (comment.status == 'flagged') ...[
                      _ActionButton(
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF10B981),
                        tooltip: 'Duyệt',
                        onTap: () => ref
                            .read(adminCommentProvider.notifier)
                            .approveComment(comment),
                      ),
                      const SizedBox(width: 4),
                      _ActionButton(
                        icon: Icons.cancel_outlined,
                        color: const Color(0xFFF59E0B),
                        tooltip: 'Từ chối',
                        onTap: () => ref
                            .read(adminCommentProvider.notifier)
                            .rejectComment(comment),
                      ),
                      const SizedBox(width: 4),
                    ],
                    _ActionButton(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      tooltip: 'Xóa',
                      onTap: () => _confirmDelete(comment),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small icon action button for table rows.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
