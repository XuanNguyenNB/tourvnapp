import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../destination/domain/entities/destination.dart';
import '../providers/admin_destination_provider.dart';
import '../providers/admin_stats_provider.dart';
import '../widgets/admin_batch_action_bar.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_error_state.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_search_toolbar.dart';
import '../widgets/destination_form_dialog.dart';

class ManageDestinationsScreen extends ConsumerStatefulWidget {
  const ManageDestinationsScreen({super.key});

  @override
  ConsumerState<ManageDestinationsScreen> createState() =>
      _ManageDestinationsScreenState();
}

class _ManageDestinationsScreenState
    extends ConsumerState<ManageDestinationsScreen> {
  final _scrollController = ScrollController();

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
      ref.read(adminDestinationProvider.notifier).loadNextPage();
    }
  }

  void _showDestinationForm(Destination? destination) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DestinationFormDialog(destination: destination),
    );
  }

  Future<void> _confirmDelete(Destination destination) async {
    final confirmed = await AdminConfirmDialog.show(
      context,
      title: 'Xóa điểm đến?',
      message:
          'Bạn có chắc muốn xóa "${destination.name}"? Hành động này không thể hoàn tác.',
      confirmLabel: 'Xóa',
    );

    if (!confirmed || !mounted) return;

    await ref
        .read(adminDestinationProvider.notifier)
        .deleteDestinationData(destination.id);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa điểm đến')));
  }

  Future<void> _confirmBatchDelete(Set<String> ids) async {
    if (ids.isEmpty) return;

    final confirmed = await AdminConfirmDialog.show(
      context,
      title: 'Xóa hàng loạt?',
      message: 'Bạn có chắc muốn xóa ${ids.length} điểm đến đã chọn?',
      confirmLabel: 'Xóa',
    );

    if (!confirmed || !mounted) return;

    final result = await ref
        .read(adminDestinationProvider.notifier)
        .deleteBatch(ids.toList());

    if (!mounted) return;
    ref.read(adminDestinationProvider.notifier).clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.hasErrors
              ? 'Đã xử lý ${result.processed} mục, có lỗi xảy ra'
              : 'Đã xóa ${result.succeeded} điểm đến',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDestinationProvider);
    final countStats = ref.watch(adminDestinationContentStatsProvider);

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
          message: state.errorMessage ?? 'Không thể tải danh sách điểm đến',
          onRetry: () => ref.read(adminDestinationProvider.notifier).refresh(),
        ),
      );
    }

    final allSelected =
        state.items.isNotEmpty &&
        state.selectedIds.length == state.items.length &&
        state.selectedIds.containsAll(state.items.map((item) => item.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            AdminPageHeader(
              title: 'Quản lý Điểm đến',
              subtitle:
                  '${state.items.length}${state.hasMore ? '+' : ''} điểm đến${state.query.hasActiveCriteria ? ' đang theo bộ lọc hiện tại' : ''}',
              actions: [
                FilledButton.icon(
                  onPressed: () => _showDestinationForm(null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm điểm đến'),
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
            AdminSearchToolbar(
              searchValue: state.query.search,
              onSearchChanged: ref
                  .read(adminDestinationProvider.notifier)
                  .updateSearch,
              searchHint: 'Tìm theo tên điểm đến...',
            ),
            if (state.hasSelection) ...[
              const SizedBox(height: 16),
              AdminBatchActionBar(
                selectionLabel: 'Đã chọn ${state.selectedIds.length} điểm đến',
                onClearSelection: ref
                    .read(adminDestinationProvider.notifier)
                    .clearSelection,
                actions: [
                  FilledButton.icon(
                    key: const Key('batch_delete_destinations'),
                    onPressed: () => _confirmBatchDelete(state.selectedIds),
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
                      icon: Icons.map_outlined,
                      title: 'Chưa có điểm đến nào',
                      message:
                          'Thêm điểm đến mới hoặc điều chỉnh bộ lọc để xem dữ liệu.',
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          _DestinationTableHeader(
                            allSelected: allSelected,
                            onToggleAll: () => ref
                                .read(adminDestinationProvider.notifier)
                                .toggleSelectAllVisible(),
                          ),
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
                                                    adminDestinationProvider
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

                                final destination = state.items[index];
                                final stats = countStats.value?[destination.id];

                                return _DestinationRow(
                                  destination: destination,
                                  locationCount:
                                      stats?.locationCount ??
                                      destination.locationCount,
                                  reviewCount:
                                      stats?.reviewCount ??
                                      destination.postCount,
                                  isSelected: state.selectedIds.contains(
                                    destination.id,
                                  ),
                                  onToggleSelection: () => ref
                                      .read(adminDestinationProvider.notifier)
                                      .toggleSelection(destination.id),
                                  onEdit: () =>
                                      _showDestinationForm(destination),
                                  onDelete: () => _confirmDelete(destination),
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

class _DestinationTableHeader extends StatelessWidget {
  const _DestinationTableHeader({
    required this.allSelected,
    required this.onToggleAll,
  });

  final bool allSelected;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: const [
          SizedBox(width: 40, child: _HeaderCheckbox()),
          SizedBox(width: 60),
          Expanded(
            flex: 4,
            child: Text(
              'Tên điểm đến',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Địa điểm',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Bài viết',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          SizedBox(
            width: 112,
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

class _HeaderCheckbox extends ConsumerWidget {
  const _HeaderCheckbox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDestinationProvider);
    final allSelected =
        state.items.isNotEmpty &&
        state.selectedIds.length == state.items.length &&
        state.selectedIds.containsAll(state.items.map((item) => item.id));

    return Checkbox(
      value: allSelected,
      onChanged: (_) =>
          ref.read(adminDestinationProvider.notifier).toggleSelectAllVisible(),
      activeColor: const Color(0xFF6366F1),
    );
  }
}

class _DestinationRow extends StatelessWidget {
  const _DestinationRow({
    required this.destination,
    required this.locationCount,
    required this.reviewCount,
    required this.isSelected,
    required this.onToggleSelection,
    required this.onEdit,
    required this.onDelete,
  });

  final Destination destination;
  final int locationCount;
  final int reviewCount;
  final bool isSelected;
  final VoidCallback onToggleSelection;
  final VoidCallback onEdit;
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
              width: 40,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onToggleSelection(),
                activeColor: const Color(0xFF6366F1),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: destination.heroImage.isEmpty
                  ? Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_outlined,
                        color: Colors.grey,
                      ),
                    )
                  : Image.network(
                      destination.heroImage,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (destination.description.trim().isNotEmpty)
                    Text(
                      destination.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '$locationCount',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '$reviewCount',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
            SizedBox(
              width: 112,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Sửa',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: const Color(0xFF2563EB),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Xóa',
                    icon: const Icon(Icons.delete_outline, size: 20),
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
}
