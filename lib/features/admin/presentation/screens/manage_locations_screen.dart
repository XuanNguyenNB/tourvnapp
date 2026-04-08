import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../destination/domain/entities/category.dart';
import '../../../destination/domain/entities/destination.dart';
import '../../../destination/domain/entities/location.dart';
import '../providers/admin_category_provider.dart';
import '../providers/admin_location_provider.dart';
import '../providers/admin_reference_data_provider.dart';
import '../widgets/admin_batch_action_bar.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_error_state.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_search_toolbar.dart';
import '../widgets/location_form_dialog.dart';

class ManageLocationsScreen extends ConsumerStatefulWidget {
  const ManageLocationsScreen({super.key});

  @override
  ConsumerState<ManageLocationsScreen> createState() =>
      _ManageLocationsScreenState();
}

class _ManageLocationsScreenState extends ConsumerState<ManageLocationsScreen> {
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
      ref.read(adminLocationProvider.notifier).loadNextPage();
    }
  }

  void _showLocationForm(Location? location) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationFormDialog(location: location),
    );
  }

  Future<void> _confirmDelete(Location location) async {
    final confirmed = await AdminConfirmDialog.show(
      context,
      title: 'Xóa địa điểm?',
      message:
          'Bạn có chắc muốn xóa "${location.name}"? Hành động này không thể hoàn tác.',
      confirmLabel: 'Xóa',
    );

    if (!confirmed || !mounted) return;

    await ref
        .read(adminLocationProvider.notifier)
        .deleteLocationData(location.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa địa điểm')));
  }

  Future<void> _confirmBatchDelete(Set<String> ids) async {
    if (ids.isEmpty) return;

    final confirmed = await AdminConfirmDialog.show(
      context,
      title: 'Xóa hàng loạt?',
      message: 'Bạn có chắc muốn xóa ${ids.length} địa điểm đã chọn?',
      confirmLabel: 'Xóa',
    );

    if (!confirmed || !mounted) return;

    final result = await ref
        .read(adminLocationProvider.notifier)
        .deleteBatch(ids.toList());
    if (!mounted) return;

    ref.read(adminLocationProvider.notifier).clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.hasErrors
              ? 'Đã xử lý ${result.processed} mục, có lỗi xảy ra'
              : 'Đã xóa ${result.succeeded} địa điểm',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminLocationProvider);
    final List<Destination> destinations =
        ref.watch(adminDestinationLookupProvider).asData?.value ??
        const <Destination>[];
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final categories =
        categoriesAsync.asData?.value ?? Category.defaultCategories;

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
          message: state.errorMessage ?? 'Không thể tải danh sách địa điểm',
          onRetry: () => ref.read(adminLocationProvider.notifier).refresh(),
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
              title: 'Quản lý Địa điểm',
              subtitle:
                  '${state.items.length}${state.hasMore ? '+' : ''} địa điểm${state.query.hasActiveCriteria ? ' theo bộ lọc hiện tại' : ''}',
              actions: [
                FilledButton.icon(
                  onPressed: () => _showLocationForm(null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm địa điểm'),
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
                  .read(adminLocationProvider.notifier)
                  .updateSearch,
              searchHint: 'Tìm theo tên hoặc từ khóa địa điểm...',
            ),
            const SizedBox(height: 16),
            AdminFilterBar(
              hasActiveFilters: state.query.hasActiveCriteria,
              onClearFilters: ref
                  .read(adminLocationProvider.notifier)
                  .clearFilters,
              children: [
                ...destinations.map((destination) {
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
                        .read(adminLocationProvider.notifier)
                        .updateFilter(
                          'destinationId',
                          selected ? null : destination.id,
                        ),
                    selectedColor: const Color(0xFFEEF2FF),
                    checkmarkColor: const Color(0xFF4F46E5),
                    backgroundColor: Colors.white,
                  );
                }),
                if (destinations.isNotEmpty && categories.isNotEmpty)
                  Container(width: 1, height: 24, color: Colors.grey.shade300),
                ...categories.map((category) {
                  final selected =
                      state.query.filterValue('category') == category.id;
                  return FilterChip(
                    label: Text(
                      category.displayText,
                      style: const TextStyle(fontSize: 13),
                    ),
                    selected: selected,
                    onSelected: (_) => ref
                        .read(adminLocationProvider.notifier)
                        .updateFilter(
                          'category',
                          selected ? null : category.id,
                        ),
                    selectedColor: const Color(0xFFEEF2FF),
                    checkmarkColor: const Color(0xFF4F46E5),
                    backgroundColor: Colors.white,
                  );
                }),
              ],
            ),
            if (state.hasSelection) ...[
              const SizedBox(height: 16),
              AdminBatchActionBar(
                selectionLabel: 'Đã chọn ${state.selectedIds.length} địa điểm',
                onClearSelection: ref
                    .read(adminLocationProvider.notifier)
                    .clearSelection,
                actions: [
                  FilledButton.icon(
                    key: const Key('batch_delete_locations'),
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
                      icon: Icons.place_outlined,
                      title: 'Chưa có địa điểm nào',
                      message:
                          'Thêm địa điểm mới hoặc thay đổi bộ lọc để hiển thị dữ liệu.',
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          _LocationTableHeader(allSelected: allSelected),
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
                                                    adminLocationProvider
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

                                final location = state.items[index];
                                String? destinationName;
                                for (final item in destinations) {
                                  if (item.id == location.destinationId) {
                                    destinationName = item.name;
                                    break;
                                  }
                                }

                                return _LocationRow(
                                  location: location,
                                  destinationName:
                                      destinationName ??
                                      location.resolvedDestinationName,
                                  isSelected: state.selectedIds.contains(
                                    location.id,
                                  ),
                                  onToggleSelection: () => ref
                                      .read(adminLocationProvider.notifier)
                                      .toggleSelection(location.id),
                                  onEdit: () => _showLocationForm(location),
                                  onDelete: () => _confirmDelete(location),
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

class _LocationTableHeader extends ConsumerWidget {
  const _LocationTableHeader({required this.allSelected});

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
            width: 40,
            child: Checkbox(
              value: allSelected,
              onChanged: (_) => ref
                  .read(adminLocationProvider.notifier)
                  .toggleSelectAllVisible(),
              activeColor: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 60),
          const Expanded(
            flex: 3,
            child: Text(
              'Tên địa điểm',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Danh mục',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Điểm đến',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(
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

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.location,
    required this.destinationName,
    required this.isSelected,
    required this.onToggleSelection,
    required this.onEdit,
    required this.onDelete,
  });

  final Location location;
  final String destinationName;
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
              child: location.image.isEmpty
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
                      location.image,
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
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (location.address?.trim().isNotEmpty == true)
                    Text(
                      location.address!,
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
                location.category,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      destinationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                  if (location.hasCoordinates)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.gps_fixed,
                        size: 14,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                ],
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
