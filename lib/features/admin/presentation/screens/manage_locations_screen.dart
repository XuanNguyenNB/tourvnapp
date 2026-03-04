import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_location_provider.dart';
import '../providers/admin_destination_provider.dart';
import '../providers/admin_category_provider.dart';
import '../../../destination/domain/entities/location.dart';
import '../widgets/location_form_dialog.dart';

class ManageLocationsScreen extends ConsumerStatefulWidget {
  const ManageLocationsScreen({super.key});

  @override
  ConsumerState<ManageLocationsScreen> createState() =>
      _ManageLocationsScreenState();
}

class _ManageLocationsScreenState extends ConsumerState<ManageLocationsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  String? _selectedDestinationId;
  String? _selectedCategory;
  final Set<String> _selectedIds = {};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminLocationProvider.notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value.trim().toLowerCase());
    });
  }

  List<Location> _applyFilters(List<Location> locations) {
    var result = locations;

    if (_searchQuery.isNotEmpty) {
      result = result
          .where(
            (l) =>
                l.name.toLowerCase().contains(_searchQuery) ||
                (l.address?.toLowerCase().contains(_searchQuery) ?? false),
          )
          .toList();
    }

    if (_selectedDestinationId != null) {
      result = result
          .where((l) => l.destinationId == _selectedDestinationId)
          .toList();
    }

    if (_selectedCategory != null) {
      result = result.where((l) => l.category == _selectedCategory).toList();
    }

    return result;
  }

  void _clearFilters() {
    setState(() {
      _selectedDestinationId = null;
      _selectedCategory = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _toggleSelectAll(List<Location> filtered) {
    setState(() {
      if (_selectedIds.length == filtered.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(filtered.map((l) => l.id));
      }
    });
  }

  void _showLocationForm(Location? location) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationFormDialog(location: location),
    );
  }

  Future<void> _confirmDelete(Location location) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Địa điểm?'),
        content: Text(
          'Bạn có chắc chắn muốn xóa ${location.name}? Hành động này không thể hoàn tác.',
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
          .read(adminLocationProvider.notifier)
          .deleteLocationData(location.id);
      if (mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa địa điểm thành công!')),
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
        content: Text('Bạn có chắc muốn xóa $count địa điểm đã chọn?'),
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
      await ref.read(adminLocationProvider.notifier).deleteBatch(ids);
      if (mounted) {
        try {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Đã xóa $count địa điểm!')));
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(adminLocationProvider);
    final destinationsAsync = ref.watch(adminDestinationProvider);
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final categoryMap = <String, String>{};
    categoriesAsync.whenData((cats) {
      for (final c in cats) {
        categoryMap[c.id] = c.displayText;
      }
    });

    final destinationMap = <String, String>{};
    for (final d in destinationsAsync.items) {
      destinationMap[d.id] = d.name;
    }

    if (locationsAsync.isInitialLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (locationsAsync.error != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text('Lỗi tải dữ liệu địa điểm: ${locationsAsync.error}'),
        ),
      );
    }

    final locations = locationsAsync.items;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Builder(
        builder: (context) {
          final filtered = _applyFilters(locations);

          // Get unique destination names for filter chips
          final destinationNames = <String, String>{}; // id -> name
          for (final loc in locations) {
            destinationNames[loc.destinationId] =
                destinationMap[loc.destinationId] ??
                loc.resolvedDestinationName;
          }

          final hasActiveFilters =
              _selectedDestinationId != null ||
              _selectedCategory != null ||
              _searchQuery.isNotEmpty;

          return Column(
            children: [
              _buildHeader(filtered, hasActiveFilters),
              _buildFilterBar(destinationNames, categoryMap, hasActiveFilters),
              if (_selectedIds.isNotEmpty) _buildBatchBar(),
              const SizedBox(height: 8),
              _buildTableHeader(filtered),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có địa điểm nào',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        itemCount:
                            filtered.length +
                            (locationsAsync.isLoadingMore ||
                                    locationsAsync.hasMore
                                ? 1
                                : 0),
                        itemBuilder: (_, i) {
                          if (i >= filtered.length) {
                            // Loading or Load More row
                            if (locationsAsync.isLoadingMore) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            }
                            if (locationsAsync.hasMore) {
                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: Center(
                                  child: TextButton.icon(
                                    onPressed: () => ref
                                        .read(adminLocationProvider.notifier)
                                        .loadNextPage(),
                                    icon: const Icon(Icons.expand_more),
                                    label: const Text('Tải thêm'),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }
                          return _buildRow(
                            filtered[i],
                            categoryMap,
                            destinationMap,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────
  Widget _buildHeader(List<Location> filtered, bool hasActiveFilters) {
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
                'Quản lý Địa điểm',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(() {
                final locationsAsync = ref.watch(adminLocationProvider);
                final countStr = locationsAsync.hasMore
                    ? '${filtered.length}+'
                    : '${filtered.length}';
                final suffix = hasActiveFilters ? ' (đã lọc)' : '';
                return '$countStr địa điểm$suffix';
              }(), style: TextStyle(color: Colors.grey[500], fontSize: 13)),
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
                    hintText: 'Tìm theo tên, địa chỉ...',
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
                onPressed: () => _showLocationForm(null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm địa điểm'),
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

  // ── FILTER BAR ─────────────────────────────────────────
  Widget _buildFilterBar(
    Map<String, String> destinationNames,
    Map<String, String> categoryMap,
    bool hasActiveFilters,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 16, 36, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(Icons.filter_list, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 4),
          // Destination filters
          ...destinationNames.entries.map(
            (entry) => FilterChip(
              label: Text(entry.value, style: const TextStyle(fontSize: 13)),
              selected: _selectedDestinationId == entry.key,
              onSelected: (selected) {
                setState(
                  () => _selectedDestinationId = selected ? entry.key : null,
                );
              },
              selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: _selectedDestinationId == entry.key
                      ? const Color(0xFF6366F1)
                      : Colors.grey.shade300,
                ),
              ),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          // Divider
          if (destinationNames.isNotEmpty)
            Container(
              width: 1,
              height: 24,
              color: Colors.grey.shade300,
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
          // Category filters
          ...categoryMap.entries.map(
            (entry) => FilterChip(
              label: Text(entry.value, style: const TextStyle(fontSize: 13)),
              selected: _selectedCategory == entry.key,
              onSelected: (selected) {
                setState(() => _selectedCategory = selected ? entry.key : null);
              },
              selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: _selectedCategory == entry.key
                      ? const Color(0xFF6366F1)
                      : Colors.grey.shade300,
                ),
              ),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          if (hasActiveFilters)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Xóa bộ lọc', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
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
            key: const Key('batch_delete_locations'),
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
  Widget _buildTableHeader(List<Location> filtered) {
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
            flex: 3,
            child: Text(
              'Tên',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Danh mục',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Điểm đến',
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
  Widget _buildRow(
    Location loc,
    Map<String, String> categoryMap,
    Map<String, String> destinationMap,
  ) {
    final isSelected = _selectedIds.contains(loc.id);

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
                      ? _selectedIds.remove(loc.id)
                      : _selectedIds.add(loc.id);
                });
              },
              activeColor: const Color(0xFF6366F1),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              loc.image,
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
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (loc.address != null)
                  Text(
                    loc.address!,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              categoryMap[loc.category] ?? loc.category,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    destinationMap[loc.destinationId] ??
                        loc.resolvedDestinationName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (loc.hasCoordinates)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.gps_fixed,
                      size: 14,
                      color: Colors.green[400],
                    ),
                  ),
              ],
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
                  onPressed: () => _showLocationForm(loc),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red,
                  tooltip: 'Xóa',
                  onPressed: () => _confirmDelete(loc),
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
