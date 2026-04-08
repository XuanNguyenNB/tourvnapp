import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/saved_item.dart';
import '../providers/saved_provider.dart';

/// Screen displaying the user's saved/bookmarked items.
///
/// Features:
/// - Filter chips: Tất cả | Địa điểm | Bài viết
/// - Grid view with thumbnail cards
/// - Swipe-to-delete
/// - Empty state
class SavedItemsScreen extends ConsumerStatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  ConsumerState<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends ConsumerState<SavedItemsScreen> {
  String _filter = 'all'; // 'all' | 'location' | 'review'

  @override
  Widget build(BuildContext context) {
    final savedAsync = ref.watch(savedItemsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Đã lưu',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: savedAsync.when(
              data: (items) => _buildContent(items),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF8B5CF6),
                ),
              ),
              error: (e, _) => Center(
                child: Text('Lỗi: $e',
                    style: const TextStyle(color: Color(0xFFEF4444))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final chips = [
      ('all', 'Tất cả', Icons.apps),
      ('location', 'Địa điểm', Icons.place_outlined),
      ('review', 'Bài viết', Icons.article_outlined),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: chips.map((chip) {
          final isSelected = _filter == chip.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    chip.$3,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(chip.$2),
                ],
              ),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              selectedColor: const Color(0xFF8B5CF6),
              backgroundColor: const Color(0xFFF8FAFC),
              checkmarkColor: Colors.white,
              showCheckmark: false,
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFFE2E8F0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (_) => setState(() => _filter = chip.$1),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(List<SavedItem> items) {
    final filtered = _filter == 'all'
        ? items
        : items.where((i) => i.itemType == _filter).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildItemCard(filtered[index]),
    );
  }

  Widget _buildEmptyState() {
    final messages = {
      'all': 'Chưa lưu gì cả',
      'location': 'Chưa lưu địa điểm nào',
      'review': 'Chưa lưu bài viết nào',
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.bookmark_border,
              size: 40,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            messages[_filter] ?? 'Chưa lưu gì cả',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhấn biểu tượng 📌 để lưu lại\nnhững địa điểm bạn yêu thích',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(SavedItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        ref.read(savedActionsProvider.notifier).deleteById(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã bỏ lưu "${item.title}"'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _navigateToItem(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 100,
                  height: 90,
                  child: item.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                          memCacheHeight: 180,
                          placeholder: (_, __) => Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(Icons.image,
                                color: Color(0xFFCBD5E1)),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(Icons.broken_image,
                                color: Color(0xFFCBD5E1)),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF1F5F9),
                          child: Icon(
                            item.isLocation
                                ? Icons.place_outlined
                                : Icons.article_outlined,
                            color: const Color(0xFFCBD5E1),
                            size: 32,
                          ),
                        ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.isLocation
                              ? const Color(0xFFDBEAFE)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.isLocation ? '📍 Địa điểm' : '📝 Bài viết',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: item.isLocation
                                ? const Color(0xFF1E40AF)
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Title
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (item.destinationName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.destinationName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Bookmark indicator
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.bookmark,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToItem(SavedItem item) {
    if (item.isLocation) {
      context.push('/location/${item.itemId}');
    } else if (item.isReview) {
      context.push('/review/${item.itemId}');
    }
  }
}
