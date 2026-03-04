import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_review_provider.dart';
import '../providers/admin_location_provider.dart';
import '../../../review/domain/entities/review.dart';
import '../../../destination/domain/entities/location.dart' as loc;
import '../widgets/review_form_dialog.dart';

class ManageReviewsScreen extends ConsumerStatefulWidget {
  const ManageReviewsScreen({super.key});

  @override
  ConsumerState<ManageReviewsScreen> createState() =>
      _ManageReviewsScreenState();
}

class _ManageReviewsScreenState extends ConsumerState<ManageReviewsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  String? _selectedDestination;
  String? _selectedCategory;
  String? _selectedLocationId;
  final Set<String> _selectedIds = {};
  Timer? _debounce;

  static const _categoryLabels = {
    'food': '🍜 Ăn uống',
    'places': '📸 Điểm đến',
    'stay': '🏨 Lưu trú',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminReviewProvider.notifier).loadNextPage();
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

  List<Review> _applyFilters(List<Review> reviews) {
    var result = reviews;

    if (_searchQuery.isNotEmpty) {
      result = result
          .where(
            (r) =>
                r.title.toLowerCase().contains(_searchQuery) ||
                r.authorName.toLowerCase().contains(_searchQuery),
          )
          .toList();
    }

    // Filter by destinationId (not destinationName) to avoid string mismatch
    if (_selectedDestination != null) {
      result = result
          .where((r) => r.destinationId == _selectedDestination)
          .toList();
    }

    if (_selectedCategory != null) {
      result = result.where((r) => r.category == _selectedCategory).toList();
    }

    // Filter by locationId (match against relatedLocationIds)
    if (_selectedLocationId != null) {
      result = result
          .where((r) => r.relatedLocationIds.contains(_selectedLocationId))
          .toList();
    }

    return result;
  }

  /// Returns a Map of destinationId -> destinationName for filter chips
  Map<String, String> _getUniqueDestinations(List<Review> reviews) {
    final map = <String, String>{};
    for (final r in reviews) {
      if (r.destinationId != null) {
        map[r.destinationId!] = r.destinationName ?? r.destinationId!;
      }
    }
    return map;
  }

  Set<String> _getUniqueCategories(List<Review> reviews) {
    return reviews
        .where((r) => r.category != null)
        .map((r) => r.category!)
        .toSet();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedDestination = null;
      _selectedCategory = null;
      _selectedLocationId = null;
    });
  }

  void _toggleSelectAll(List<Review> filtered) {
    setState(() {
      final filteredIds = filtered.map((r) => r.id).toSet();
      if (_selectedIds.containsAll(filteredIds)) {
        _selectedIds.removeAll(filteredIds);
      } else {
        _selectedIds.addAll(filteredIds);
      }
    });
  }

  void _toggleItem(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _confirmBatchDelete() async {
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa hàng loạt?'),
        content: Text(
          'Bạn có chắc chắn muốn xóa $count bài viết đã chọn? Không thể hoàn tác.',
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
      final ids = _selectedIds.toList();
      setState(() => _selectedIds.clear());
      await ref.read(adminReviewProvider.notifier).deleteBatch(ids);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa $count bài viết thành công!')),
        );
      }
    }
  }

  Future<void> _confirmDeleteSingle(Review review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa Bài viết?'),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${review.title}"? Không thể hoàn tác.',
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
      await ref.read(adminReviewProvider.notifier).deleteReviewData(review.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa bài viết thành công!')),
        );
      }
    }
  }

  void _showReviewForm(Review? review) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReviewFormDialog(review: review),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(adminReviewProvider);
    final locationsAsync = ref.watch(adminLocationProvider);

    if (reviewsAsync.isInitialLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (reviewsAsync.error != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text('Lỗi tải dữ liệu bài viết: ${reviewsAsync.error}'),
        ),
      );
    }

    final allReviews = reviewsAsync.items;
    final locations = locationsAsync.items;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Builder(
        builder: (context) {
          final filtered = _applyFilters(allReviews);
          final destinations = _getUniqueDestinations(allReviews);
          final categories = _getUniqueCategories(allReviews);
          final hasActiveFilters =
              _searchQuery.isNotEmpty ||
              _selectedDestination != null ||
              _selectedCategory != null ||
              _selectedLocationId != null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              _buildHeader(filtered, hasActiveFilters),
              // ── Filter bar ──
              _buildFilterBar(
                destinations,
                categories,
                locations,
                hasActiveFilters,
              ),
              // ── Batch action bar ──
              if (_selectedIds.isNotEmpty) _buildBatchBar(),
              // ── Content ──
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(hasActiveFilters)
                    : _buildReviewList(filtered),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────
  Widget _buildHeader(List<Review> filtered, bool hasActiveFilters) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 24, 36, 0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Title + count
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quản lý Bài viết',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(() {
                final reviewsAsync = ref.watch(adminReviewProvider);
                final countStr = reviewsAsync.hasMore
                    ? '${filtered.length}+'
                    : '${filtered.length}';
                final suffix = hasActiveFilters ? ' (đã lọc)' : '';
                return '$countStr bài viết$suffix';
              }(), style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ],
          ),
          // Search + Add button row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search field
              SizedBox(
                width: 220,
                height: 42,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tiêu đề, tác giả...',
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
              // Add button
              FilledButton.icon(
                onPressed: () => _showReviewForm(null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm bài viết'),
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

  // ── FILTER BAR ──────────────────────────────────────────
  Widget _buildFilterBar(
    Map<String, String> destinations,
    Set<String> categories,
    List<loc.Location> allLocations,
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
          // Destination filter (uses destinationId for matching)
          ...destinations.entries.map(
            (entry) => FilterChip(
              label: Text(entry.value, style: const TextStyle(fontSize: 13)),
              selected: _selectedDestination == entry.key,
              onSelected: (selected) {
                setState(() {
                  _selectedDestination = selected ? entry.key : null;
                  _selectedIds.clear();
                });
              },
              selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: _selectedDestination == entry.key
                      ? const Color(0xFF6366F1)
                      : Colors.grey.shade300,
                ),
              ),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          // Divider
          if (destinations.isNotEmpty && categories.isNotEmpty)
            Container(width: 1, height: 24, color: Colors.grey[300]),
          // Category filter
          ...categories.map(
            (cat) => FilterChip(
              label: Text(
                _categoryLabels[cat] ?? cat,
                style: const TextStyle(fontSize: 13),
              ),
              selected: _selectedCategory == cat,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? cat : null;
                  _selectedIds.clear();
                });
              },
              selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: _selectedCategory == cat
                      ? const Color(0xFF6366F1)
                      : Colors.grey.shade300,
                ),
              ),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          // Divider before location filter
          if ((destinations.isNotEmpty || categories.isNotEmpty) &&
              allLocations.isNotEmpty)
            Container(width: 1, height: 24, color: Colors.grey[300]),
          // Location filter (dropdown vì có thể nhiều)
          if (allLocations.isNotEmpty)
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _selectedLocationId != null
                    ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedLocationId != null
                      ? const Color(0xFF6366F1)
                      : Colors.grey.shade300,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedLocationId,
                  hint: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Địa điểm',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: Colors.grey[500],
                  ),
                  isDense: true,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'Tất cả địa điểm',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ),
                    ...allLocations.map(
                      (l) => DropdownMenuItem<String?>(
                        value: l.id,
                        child: Text(
                          l.name,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _selectedLocationId = v;
                      _selectedIds.clear();
                    });
                  },
                ),
              ),
            ),
          // Clear filters
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
          Icon(Icons.check_circle, color: const Color(0xFF6366F1), size: 20),
          const SizedBox(width: 8),
          Text(
            'Đã chọn ${_selectedIds.length} bài viết',
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Bỏ chọn', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            key: const Key('batch_delete_button'),
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

  // ── EMPTY STATE ─────────────────────────────────────────
  Widget _buildEmptyState(bool hasActiveFilters) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasActiveFilters ? Icons.search_off : Icons.article_outlined,
            size: 56,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            hasActiveFilters
                ? 'Không tìm thấy bài viết phù hợp'
                : 'Chưa có bài viết nào',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        ],
      ),
    );
  }

  // ── REVIEW LIST ─────────────────────────────────────────
  Widget _buildReviewList(List<Review> filtered) {
    final reviewsAsync = ref.watch(adminReviewProvider);
    final allSelected = filtered.every((r) => _selectedIds.contains(r.id));

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
          _buildTableHeader(filtered, allSelected),
          const Divider(height: 1),
          // Table rows
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              itemCount:
                  filtered.length +
                  (reviewsAsync.isLoadingMore || reviewsAsync.hasMore ? 1 : 0),
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                if (index >= filtered.length) {
                  if (reviewsAsync.isLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  if (reviewsAsync.hasMore) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () => ref
                              .read(adminReviewProvider.notifier)
                              .loadNextPage(),
                          icon: const Icon(Icons.expand_more),
                          label: const Text('Tải thêm'),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }
                return _buildReviewRow(filtered[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(List<Review> filtered, bool allSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // Select all checkbox
          SizedBox(
            width: 32,
            child: Checkbox(
              value: filtered.isNotEmpty && allSelected,
              onChanged: (_) => _toggleSelectAll(filtered),
              activeColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Columns
          const SizedBox(width: 52), // image space
          const SizedBox(width: 12),
          const Expanded(
            flex: 3,
            child: Text(
              'Tiêu đề',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Tác giả',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Địa điểm',
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
              'Danh mục',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(
            width: 70,
            child: Text(
              'Lượt ❤️',
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
    );
  }

  Widget _buildReviewRow(Review review) {
    final isSelected = _selectedIds.contains(review.id);

    return InkWell(
      onTap: () => _toggleItem(review.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isSelected
            ? const Color(0xFF6366F1).withValues(alpha: 0.04)
            : null,
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 32,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleItem(review.id),
                activeColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: review.heroImage.isEmpty
                  ? Container(
                      width: 52,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.image,
                        size: 18,
                        color: Colors.grey,
                      ),
                    )
                  : Image.network(
                      review.heroImage,
                      width: 52,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 52,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.image,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              flex: 3,
              child: Text(
                review.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Author
            Expanded(
              flex: 2,
              child: Text(
                review.authorName,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Location name
            Expanded(
              flex: 2,
              child: Builder(
                builder: (context) {
                  final locations = ref.watch(adminLocationProvider).items;
                  String name = review.destinationName ?? '—';
                  if (review.relatedLocationIds.isNotEmpty) {
                    final locId = review.relatedLocationIds.first;
                    final loc = locations
                        .where((l) => l.id == locId)
                        .firstOrNull;
                    if (loc != null) name = loc.name;
                  }
                  return Text(
                    name,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),
            // Category
            SizedBox(
              width: 100,
              child: review.category != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          review.category!,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _categoryLabels[review.category] ?? review.category!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getCategoryColor(review.category!),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Text(
                      '—',
                      style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    ),
            ),
            // Like count
            SizedBox(
              width: 70,
              child: Text(
                review.formattedLikes,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
            // Actions
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: const Color(0xFF6366F1),
                    tooltip: 'Sửa',
                    onPressed: () => _showReviewForm(review),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: Colors.red[400],
                    tooltip: 'Xóa',
                    onPressed: () => _confirmDeleteSingle(review),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'food':
        return Colors.orange;
      case 'places':
        return Colors.blue;
      case 'stay':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
