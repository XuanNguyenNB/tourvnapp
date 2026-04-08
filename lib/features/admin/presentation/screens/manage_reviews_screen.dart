import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../destination/domain/entities/location.dart';
import '../../../review/domain/entities/review.dart';
import '../providers/admin_reference_data_provider.dart';
import '../providers/admin_review_provider.dart';
import '../widgets/admin_batch_action_bar.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_error_state.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_search_toolbar.dart';
import '../widgets/review_form_dialog.dart';

class ManageReviewsScreen extends ConsumerStatefulWidget {
  const ManageReviewsScreen({super.key});

  @override
  ConsumerState<ManageReviewsScreen> createState() =>
      _ManageReviewsScreenState();
}

class _ManageReviewsScreenState extends ConsumerState<ManageReviewsScreen> {
  final _scrollController = ScrollController();

  static const _categoryLabels = <String, String>{
    'food': 'Ăn uống',
    'places': 'Điểm đến',
    'stay': 'Lưu trú',
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
      ref.read(adminReviewProvider.notifier).loadNextPage();
    }
  }

  void _showReviewForm(Review? review) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReviewFormDialog(review: review),
    );
  }

  Future<void> _confirmDelete(Review review) async {
    final confirmed = await AdminConfirmDialog.show(
      context,
      title: 'Xóa bài viết?',
      message:
          'Bạn có chắc muốn xóa "${review.title}"? Hành động này không thể hoàn tác.',
      confirmLabel: 'Xóa',
    );

    if (!confirmed || !mounted) return;

    await ref.read(adminReviewProvider.notifier).deleteReviewData(review.id);
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa bài viết')));
  }

  Future<void> _confirmBatchDelete(Set<String> ids) async {
    if (ids.isEmpty) return;

    final confirmed = await AdminConfirmDialog.show(
      context,
      title: 'Xóa hàng loạt?',
      message: 'Bạn có chắc muốn xóa ${ids.length} bài viết đã chọn?',
      confirmLabel: 'Xóa',
    );

    if (!confirmed || !mounted) return;

    final result = await ref
        .read(adminReviewProvider.notifier)
        .deleteBatch(ids.toList());
    if (!mounted) return;

    ref.read(adminReviewProvider.notifier).clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.hasErrors
              ? 'Đã xử lý ${result.processed} mục, có lỗi xảy ra'
              : 'Đã xóa ${result.succeeded} bài viết',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReviewProvider);
    final destinationLookup = ref.watch(adminDestinationLookupProvider);
    final locationLookup = ref.watch(adminLocationLookupProvider);
    final locations = locationLookup.asData?.value ?? const <Location>[];

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
          message: state.errorMessage ?? 'Không thể tải danh sách bài viết',
          onRetry: () => ref.read(adminReviewProvider.notifier).refresh(),
        ),
      );
    }

    final allSelected =
        state.items.isNotEmpty &&
        state.selectedIds.length == state.items.length &&
        state.selectedIds.containsAll(state.items.map((item) => item.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 1100;
          final pagePadding = isCompact ? 20.0 : 24.0;
          final sectionSpacing = isCompact ? 12.0 : 16.0;

          return Padding(
            padding: EdgeInsets.all(pagePadding),
            child: Column(
              children: [
                AdminPageHeader(
                  title: 'Quản lý Bài viết',
                  subtitle:
                      '${state.items.length}${state.hasMore ? '+' : ''} bài viết${state.query.hasActiveCriteria ? ' theo bộ lọc hiện tại' : ''}',
                  actions: [
                    FilledButton.icon(
                      onPressed: () => _showReviewForm(null),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Thêm bài viết'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: sectionSpacing),
                AdminSearchToolbar(
                  searchValue: state.query.search,
                  onSearchChanged: ref
                      .read(adminReviewProvider.notifier)
                      .updateSearch,
                  searchHint: 'Tìm theo tiêu đề hoặc tác giả...',
                ),
                SizedBox(height: sectionSpacing),
                AdminFilterBar(
                  hasActiveFilters: state.query.hasActiveCriteria,
                  onClearFilters: ref
                      .read(adminReviewProvider.notifier)
                      .clearFilters,
                  children: [
                    ...destinationLookup.asData?.value.map((destination) {
                          final selected =
                              state.query.filterValue('destinationId') ==
                              destination.id;
                          return FilterChip(
                            label: Text(
                              destination.name,
                              style: const TextStyle(fontSize: 13),
                            ),
                            selected: selected,
                            onSelected: (_) => ref
                                .read(adminReviewProvider.notifier)
                                .updateFilter(
                                  'destinationId',
                                  selected ? null : destination.id,
                                ),
                            selectedColor: const Color(0xFFEEF2FF),
                            checkmarkColor: const Color(0xFF4F46E5),
                            backgroundColor: Colors.white,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList() ??
                        const [],
                    if ((destinationLookup.asData?.value.isNotEmpty ?? false))
                      Container(
                        width: 1,
                        height: 24,
                        color: Colors.grey.shade300,
                      ),
                    ..._categoryLabels.entries.map((entry) {
                      final selected =
                          state.query.filterValue('category') == entry.key;
                      return FilterChip(
                        label: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 13),
                        ),
                        selected: selected,
                        onSelected: (_) => ref
                            .read(adminReviewProvider.notifier)
                            .updateFilter(
                              'category',
                              selected ? null : entry.key,
                            ),
                        selectedColor: const Color(0xFFEEF2FF),
                        checkmarkColor: const Color(0xFF4F46E5),
                        backgroundColor: Colors.white,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }),
                    if (locations.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: state.query.filterValue('locationId'),
                            hint: const Text(
                              'Địa điểm',
                              style: TextStyle(fontSize: 13),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Tất cả địa điểm'),
                              ),
                              ...locations.map(
                                (location) => DropdownMenuItem<String?>(
                                  value: location.id,
                                  child: Text(
                                    location.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) => ref
                                .read(adminReviewProvider.notifier)
                                .updateFilter('locationId', value),
                          ),
                        ),
                      ),
                  ],
                ),
                if (state.hasSelection) ...[
                  SizedBox(height: sectionSpacing),
                  AdminBatchActionBar(
                    selectionLabel:
                        'Đã chọn ${state.selectedIds.length} bài viết',
                    onClearSelection: ref
                        .read(adminReviewProvider.notifier)
                        .clearSelection,
                    actions: [
                      FilledButton.icon(
                        key: const Key('batch_delete_button'),
                        onPressed: () => _confirmBatchDelete(state.selectedIds),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Xóa'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: sectionSpacing),
                Expanded(
                  child: state.items.isEmpty
                      ? AdminEmptyState(
                          icon: state.query.hasActiveCriteria
                              ? Icons.search_off_outlined
                              : Icons.article_outlined,
                          title: state.query.hasActiveCriteria
                              ? 'Không tìm thấy bài viết phù hợp'
                              : 'Chưa có bài viết nào',
                          message: state.query.hasActiveCriteria
                              ? 'Thử đổi bộ lọc hoặc từ khóa tìm kiếm.'
                              : 'Thêm bài viết mới hoặc duyệt bản nháp AI để hiển thị tại đây.',
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            children: [
                              _ReviewTableHeader(allSelected: allSelected),
                              const Divider(height: 1),
                              Expanded(
                                child: ListView.separated(
                                  controller: _scrollController,
                                  cacheExtent: 800,
                                  padding: EdgeInsets.zero,
                                  itemCount:
                                      state.items.length +
                                      (state.hasMore ? 1 : 0),
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: Colors.grey[100],
                                  ),
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
                                                        adminReviewProvider
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

                                    final review = state.items[index];
                                    String? firstLocationName;
                                    for (final location in locations) {
                                      if (review.relatedLocationIds.contains(
                                        location.id,
                                      )) {
                                        firstLocationName = location.name;
                                        break;
                                      }
                                    }

                                    return _ReviewRow(
                                      review: review,
                                      firstLocationName:
                                          firstLocationName ??
                                          review.destinationName ??
                                          '—',
                                      isSelected: state.selectedIds.contains(
                                        review.id,
                                      ),
                                      onToggleSelection: () => ref
                                          .read(adminReviewProvider.notifier)
                                          .toggleSelection(review.id),
                                      onEdit: () => _showReviewForm(review),
                                      onDelete: () => _confirmDelete(review),
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
          );
        },
      ),
    );
  }
}

class _ReviewTableHeader extends ConsumerWidget {
  const _ReviewTableHeader({required this.allSelected});

  final bool allSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  .read(adminReviewProvider.notifier)
                  .toggleSelectAllVisible(),
              activeColor: const Color(0xFF6366F1),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 56),
          const Expanded(
            flex: 3,
            child: Text(
              'Tiêu đề',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Tác giả',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Liên kết địa điểm',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(
            width: 96,
            child: Text(
              'Danh mục',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(
            width: 60,
            child: Text(
              'Thích',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(
            width: 96,
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

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.review,
    required this.firstLocationName,
    required this.isSelected,
    required this.onToggleSelection,
    required this.onEdit,
    required this.onDelete,
  });

  final Review review;
  final String firstLocationName;
  final bool isSelected;
  final VoidCallback onToggleSelection;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _categoryLabels = <String, String>{
    'food': 'Ăn uống',
    'places': 'Điểm đến',
    'stay': 'Lưu trú',
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggleSelection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isSelected ? const Color(0xFFEEF2FF) : null,
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onToggleSelection(),
                activeColor: const Color(0xFF6366F1),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: review.heroImage.isEmpty
                  ? Container(
                      width: 48,
                      height: 36,
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_outlined,
                        color: Colors.grey,
                      ),
                    )
                  : Image.network(
                      review.heroImage,
                      width: 48,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 36,
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
              flex: 3,
              child: Text(
                review.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                review.authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                firstLocationName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
            SizedBox(
              width: 96,
              child: Text(
                _categoryLabels[review.category] ?? review.category ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                review.formattedLikes,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
            SizedBox(
              width: 96,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Sửa',
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: const Color(0xFF2563EB),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Xóa',
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: const Color(0xFFDC2626),
                    visualDensity: VisualDensity.compact,
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
