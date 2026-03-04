import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_destination_provider.dart';
import '../providers/admin_location_provider.dart';
import '../providers/admin_review_provider.dart';
import '../providers/paginated_admin_provider.dart';
import '../../../destination/domain/entities/destination.dart';
import '../widgets/destination_form_dialog.dart';

class ManageDestinationsScreen extends ConsumerStatefulWidget {
  const ManageDestinationsScreen({super.key});

  @override
  ConsumerState<ManageDestinationsScreen> createState() =>
      _ManageDestinationsScreenState();
}

class _ManageDestinationsScreenState
    extends ConsumerState<ManageDestinationsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  final Set<String> _selectedIds = {};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminDestinationProvider.notifier).loadNextPage();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value.trim().toLowerCase());
    });
  }

  List<Destination> _applyFilters(List<Destination> destinations) {
    var result = destinations;

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((d) => d.name.toLowerCase().contains(_searchQuery))
          .toList();
    }

    return result;
  }

  void _toggleSelectAll(List<Destination> filtered) {
    setState(() {
      if (_selectedIds.length == filtered.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(filtered.map((d) => d.id));
      }
    });
  }

  void _showDestinationForm(Destination? destination) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DestinationFormDialog(destination: destination),
    );
  }

  Future<void> _confirmDelete(Destination destination) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Điểm đến?'),
        content: Text(
          'Bạn có chắc chắn muốn xóa ${destination.name}? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(adminDestinationProvider.notifier)
          .deleteDestinationData(destination.id);
      if (mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa điểm đến thành công!')),
          );
        } catch (_) {}
      }
    }
  }

  Future<void> _confirmBatchDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa hàng loạt?'),
        content: Text('Bạn có chắc muốn xóa $count điểm đến đã chọn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ids = _selectedIds.toList();
      setState(() => _selectedIds.clear());
      await ref.read(adminDestinationProvider.notifier).deleteBatch(ids);
      if (mounted) {
        try {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Đã xóa $count điểm đến!')));
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginatedState = ref.watch(adminDestinationProvider);
    final allItems = paginatedState.items;

    // Show initial loading spinner
    if (paginatedState.isInitialLoading && allItems.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show error state
    if (paginatedState.error != null && allItems.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text('Lỗi tải dữ liệu điểm đến: ${paginatedState.error}'),
        ),
      );
    }

    final filtered = _applyFilters(allItems);
    final hasActiveFilters = _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(filtered, hasActiveFilters),
          if (_selectedIds.isNotEmpty) _buildBatchBar(),
          const SizedBox(height: 8),
          _buildTableHeader(filtered),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có điểm đến nào',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : _buildPaginatedList(filtered, paginatedState),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginatedList(
    List<Destination> filtered,
    PaginatedState<Destination> paginatedState,
  ) {
    // If search is active, don't use the scroll controller for pagination
    final useScrollController = _searchQuery.isEmpty;
    return ListView.builder(
      controller: useScrollController ? _scrollController : null,
      padding: const EdgeInsets.symmetric(horizontal: 36),
      itemCount:
          filtered.length +
          (paginatedState.hasMore && _searchQuery.isEmpty ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == filtered.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: paginatedState.isLoadingMore
                  ? const CircularProgressIndicator()
                  : TextButton.icon(
                      onPressed: () => ref
                          .read(adminDestinationProvider.notifier)
                          .loadNextPage(),
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Tải thêm'),
                    ),
            ),
          );
        }
        return _buildRow(filtered[i]);
      },
    );
  }

  // ── HEADER ──────────────────────────────────────────────
  Widget _buildHeader(List<Destination> filtered, bool hasActiveFilters) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 24, 36, 0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quản lý Điểm đến',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${filtered.length} điểm đến'
                '${hasActiveFilters ? ' (đã lọc)' : ''}',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 220,
                height: 42,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _showDestinationForm(null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm điểm đến'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── BATCH ACTION BAR ────────────────────────────────────
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
          Text(
            '${_selectedIds.length} đã chọn',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF6366F1),
              fontSize: 14,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Bỏ chọn', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            key: const Key('batch_delete_destinations'),
            onPressed: _confirmBatchDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Xóa', style: TextStyle(fontSize: 13)),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  // ── TABLE HEADER ────────────────────────────────────────
  Widget _buildTableHeader(List<Destination> filtered) {
    final allSelected =
        filtered.isNotEmpty && _selectedIds.length == filtered.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(36, 12, 36, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: allSelected,
              onChanged: (_) => _toggleSelectAll(filtered),
              activeColor: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 60), // image placeholder
          const Expanded(
            flex: 4,
            child: Text(
              'Tên',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),

          const Expanded(
            flex: 2,
            child: Text(
              'Địa điểm',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),

          const Expanded(
            flex: 2,
            child: Text(
              'Bài viết',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const SizedBox(
            width: 100,
            child: Text(
              'Thao tác',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── DATA ROW ────────────────────────────────────────────
  Widget _buildRow(Destination dest) {
    final isSelected = _selectedIds.contains(dest.id);

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF6366F1).withValues(alpha: 0.04)
            : Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: isSelected,
              onChanged: (_) {
                setState(() {
                  isSelected
                      ? _selectedIds.remove(dest.id)
                      : _selectedIds.add(dest.id);
                });
              },
              activeColor: const Color(0xFF6366F1),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              dest.heroImage,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: Colors.grey[200],
                child: const Icon(Icons.image, color: Colors.grey, size: 20),
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
                  dest.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (dest.description.isNotEmpty)
                  Text(
                    dest.description,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Builder(
              builder: (_) {
                final locations = ref.watch(adminLocationProvider).items;
                final count = locations
                    .where((l) => l.destinationId == dest.id)
                    .length;
                return Text(
                  '$count',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                );
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Builder(
              builder: (_) {
                final reviews = ref.watch(adminReviewProvider).items;
                final count = reviews
                    .where((r) => r.destinationId == dest.id)
                    .length;
                return Text(
                  '$count',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                );
              },
            ),
          ),
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: Colors.blue,
                  tooltip: 'Sửa',
                  onPressed: () => _showDestinationForm(dest),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red,
                  tooltip: 'Xóa',
                  onPressed: () => _confirmDelete(dest),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
