import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/saved_provider.dart';

/// A reusable bookmark/save toggle button.
///
/// Shows filled bookmark when saved, outline when not.
/// Animates scale + color on toggle.
class BookmarkButton extends ConsumerWidget {
  final String itemId;
  final String itemType; // 'review' | 'location'
  final String title;
  final String? imageUrl;
  final String? destinationId;
  final String? destinationName;

  /// Visual style variant.
  final BookmarkButtonStyle style;

  const BookmarkButton({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.title,
    this.imageUrl,
    this.destinationId,
    this.destinationName,
    this.style = BookmarkButtonStyle.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSavedAsync = ref.watch(isItemSavedProvider(itemId));

    final isSaved = isSavedAsync.when(
      data: (v) => v,
      loading: () => false,
      error: (_, __) => false,
    );

    switch (style) {
      case BookmarkButtonStyle.icon:
        return _buildIconButton(context, ref, isSaved);
      case BookmarkButtonStyle.pill:
        return _buildPillButton(context, ref, isSaved);
      case BookmarkButtonStyle.headerCircle:
        return _buildHeaderCircle(context, ref, isSaved);
    }
  }

  void _onToggle(BuildContext context, WidgetRef ref, bool currentlySaved) {
    // Check if user is logged in (not anonymous)
    final user = ref.read(currentUserProvider);
    if (user == null || user.isAnonymous) {
      HapticFeedback.mediumImpact();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Chưa đăng nhập'),
          content: const Text(
            'Vui lòng đăng nhập để lưu bài viết và địa điểm yêu thích.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Để sau'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/login');
              },
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    ref.read(savedActionsProvider.notifier).toggleSave(
          itemId: itemId,
          itemType: itemType,
          title: title,
          imageUrl: imageUrl,
          destinationId: destinationId,
          destinationName: destinationName,
        );

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(currentlySaved ? 'Đã bỏ lưu' : 'Đã lưu 📌'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Simple icon button (for action bars).
  Widget _buildIconButton(BuildContext context, WidgetRef ref, bool isSaved) {
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: child,
        ),
        child: Icon(
          isSaved ? Icons.bookmark : Icons.bookmark_border,
          key: ValueKey(isSaved),
          color: isSaved ? const Color(0xFF8B5CF6) : const Color(0xFF64748B),
        ),
      ),
      onPressed: () => _onToggle(context, ref, isSaved),
    );
  }

  /// Pill-shaped button with text (for bottom action bars).
  Widget _buildPillButton(BuildContext context, WidgetRef ref, bool isSaved) {
    return GestureDetector(
      onTap: () => _onToggle(context, ref, isSaved),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        height: 48,
        decoration: BoxDecoration(
          color: isSaved
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSaved
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                key: ValueKey(isSaved),
                size: 20,
                color: isSaved
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isSaved ? 'Đã lưu' : 'Lưu',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSaved
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Circle button for AppBar header (location_detail_screen style).
  Widget _buildHeaderCircle(
      BuildContext context, WidgetRef ref, bool isSaved) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: child,
          ),
          child: Icon(
            isSaved ? Icons.bookmark : Icons.bookmark_border,
            key: ValueKey(isSaved),
            color: isSaved ? const Color(0xFFFBBF24) : Colors.white,
            size: 22,
          ),
        ),
        onPressed: () => _onToggle(context, ref, isSaved),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }
}

/// Visual style for the bookmark button.
enum BookmarkButtonStyle {
  /// Simple icon button.
  icon,

  /// Pill-shaped button with text label.
  pill,

  /// Circle button matching AppBar header style.
  headerCircle,
}
