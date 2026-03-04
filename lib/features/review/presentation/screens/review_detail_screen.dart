import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/review.dart';
import '../providers/review_provider.dart';
import '../../../home/domain/entities/review_preview.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../destination/domain/entities/location.dart';
import '../widgets/animated_heart_button.dart';
import '../../../trip/presentation/widgets/add_to_trip_gesture_wrapper.dart';
import '../../../trip/presentation/widgets/day_picker_bottom_sheet.dart';
import '../../../../core/router/app_router.dart';

/// Review Detail Screen displaying full review information.
///
/// Features (Story 3.8):
/// - Full-bleed hero image with gradient overlay
/// - Author avatar, name, and date
/// - Full review text
/// - Engagement row (❤️ 💬 💾)
/// - "Thêm vào Trip" gradient CTA button
/// - Related Locations carousel
class ReviewDetailScreen extends ConsumerWidget {
  final String reviewId;
  final ReviewPreview? reviewPreview;

  const ReviewDetailScreen({
    super.key,
    required this.reviewId,
    this.reviewPreview,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewAsync = ref.watch(reviewByIdProvider(reviewId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: reviewAsync.when(
        data: (review) => _ReviewDetailContent(review: review),
        loading: () => _buildLoading(context),
        error: (error, stack) => _buildError(context, error.toString()),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    // Use preview data while loading full review
    if (reviewPreview != null) {
      return _ReviewDetailContentFromPreview(preview: reviewPreview!);
    }

    return const CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: ShimmerPlaceholder.card(
              width: double.infinity,
              height: 300,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerPlaceholder.card(width: double.infinity, height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lỗi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy bài review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview-based content while full review is loading
class _ReviewDetailContentFromPreview extends StatelessWidget {
  final ReviewPreview preview;

  const _ReviewDetailContentFromPreview({required this.preview});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              _buildHeroHeader(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReviewInfoRow(),
                      const SizedBox(height: 16),
                      _buildReviewText(),
                      const SizedBox(height: 24),
                      const ShimmerPlaceholder.card(
                        width: double.infinity,
                        height: 120,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildBottomActionBar(context),
      ],
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.white,
      leading: _GlassBackButton(onPressed: () => context.pop()),
      actions: [
        _GlassActionButton(icon: Icons.more_vert, onPressed: () {}),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (preview.heroImage != null)
              CachedNetworkImage(
                imageUrl: preview.heroImage!,
                fit: BoxFit.cover,
                memCacheHeight: 600,
                placeholder: (context, url) => const ShimmerPlaceholder.card(
                  width: double.infinity,
                  height: 300,
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFFE2E8F0),
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Color(0xFF94A3B8),
                    size: 48,
                  ),
                ),
              )
            else
              Container(color: const Color(0xFF1F2937)),
            _buildGradientOverlay(),
          ],
        ),
      ),
    );
  }

  /// Review info row with rating and category.
  Widget _buildReviewInfoRow() {
    final rating = (preview.likeCount / 10).clamp(0.0, 5.0);
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 3,
          height: 3,
          decoration: const BoxDecoration(
            color: Color(0xFF94A3B8),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        if (preview.destinationName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '📍 ${preview.destinationName}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
          stops: const [0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildReviewText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          preview.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          preview.shortText,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      child: Row(
        children: [
          // Like button
          _BottomPillButton(
            child: AnimatedHeartButton(
              reviewId: preview.id,
              initialLikeCount: preview.likeCount,
              initiallyLiked: false,
              showCount: true,
              iconSize: 20,
            ),
          ),
          const SizedBox(width: 6),
          // Add to Trip (highlighted gradient)
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                DayPickerBottomSheet.show(
                  context: context,
                  itemData: TripItemData.fromReview(
                    id: preview.id,
                    name: preview.title,
                    imageUrl: preview.heroImage,
                    destinationId: preview.destinationId ?? '',
                    destinationName: preview.destinationName ?? '',
                  ),
                );
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Thêm vào Trip',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Share button
          _BottomPillButton(
            onTap: () {
              HapticFeedback.lightImpact();
              Clipboard.setData(
                ClipboardData(text: 'https://tourvn.app/review/${preview.id}'),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép link bài review! 📎'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.share_outlined, size: 20, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text(
                  'Chia sẻ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full review content widget
class _ReviewDetailContent extends ConsumerWidget {
  final Review review;

  const _ReviewDetailContent({required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              _buildHeroHeader(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReviewInfoRow(),
                      const SizedBox(height: 16),
                      _buildReviewText(),
                      const SizedBox(height: 32),
                      _RelatedLocationsSection(
                        locationIds: review.relatedLocationIds,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildBottomActionBar(context),
      ],
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.white,
      leading: _GlassBackButton(onPressed: () => context.pop()),
      actions: [
        _GlassActionButton(icon: Icons.more_vert, onPressed: () {}),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: review.heroImage,
              fit: BoxFit.cover,
              memCacheHeight: 600,
              placeholder: (context, url) => const ShimmerPlaceholder.card(
                width: double.infinity,
                height: 300,
              ),
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFFE2E8F0),
                child: const Icon(
                  Icons.image_not_supported,
                  color: Color(0xFF94A3B8),
                  size: 48,
                ),
              ),
            ),
            _buildGradientOverlay(),
          ],
        ),
      ),
    );
  }

  /// Review info row with rating, category badge, and date.
  Widget _buildReviewInfoRow() {
    final rating = (review.likeCount / 10).clamp(0.0, 5.0);
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 3,
          height: 3,
          decoration: const BoxDecoration(
            color: Color(0xFF94A3B8),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        if (review.categoryDisplay != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              review.categoryDisplay!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        const Spacer(),
        Text(
          review.formattedDate,
          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
          stops: const [0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildReviewText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          review.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          review.fullText,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      child: Row(
        children: [
          // Like button
          _BottomPillButton(
            child: AnimatedHeartButton(
              reviewId: review.id,
              initialLikeCount: review.likeCount,
              initiallyLiked: false,
              showCount: true,
              iconSize: 20,
            ),
          ),
          const SizedBox(width: 6),
          // Add to Trip (highlighted gradient)
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                DayPickerBottomSheet.show(
                  context: context,
                  itemData: TripItemData.fromReview(
                    id: review.id,
                    name: review.title,
                    imageUrl: review.heroImage,
                    destinationId: review.destinationId ?? '',
                    destinationName: review.destinationName ?? '',
                  ),
                );
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Thêm vào Trip',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Share button
          _BottomPillButton(
            onTap: () {
              HapticFeedback.lightImpact();
              Clipboard.setData(
                ClipboardData(text: 'https://tourvn.app/review/${review.id}'),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép link bài review! 📎'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.share_outlined, size: 20, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text(
                  'Chia sẻ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass-effect back button for hero header
class _GlassBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GlassBackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

/// Glass-effect action button for hero header
class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassActionButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }
}

/// Pill-shaped button for bottom action bar
class _BottomPillButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _BottomPillButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(22),
        ),
        child: child,
      ),
    );
  }
}

/// Related Locations carousel section
class _RelatedLocationsSection extends ConsumerWidget {
  final List<String> locationIds;

  const _RelatedLocationsSection({required this.locationIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (locationIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final locationsAsync = ref.watch(relatedLocationsProvider(locationIds));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bài viết liên quan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        locationsAsync.when(
          data: (locations) => _buildCarousel(context, locations),
          loading: () => _buildLoadingCarousel(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildCarousel(BuildContext context, List<Location> locations) {
    if (locations.isEmpty) {
      return const Text(
        'Không có địa điểm liên quan',
        style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: locations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final location = locations[index];
          return _RelatedLocationCard(location: location);
        },
      ),
    );
  }

  Widget _buildLoadingCarousel() {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) =>
            const ShimmerPlaceholder.card(width: 120, height: 140),
      ),
    );
  }
}

/// Compact location card for Related Locations carousel
class _RelatedLocationCard extends StatelessWidget {
  final Location location;

  const _RelatedLocationCard({required this.location});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to standalone location detail route (outside the shell)
        // to avoid GlobalKey duplication with StatefulShellRoute
        context.pushNamed(
          AppRoutes.locationStandalone,
          pathParameters: {
            'destId': location.destinationId,
            'locId': location.id,
          },
          extra: location,
        );
      },
      onLongPress: () {
        // Haptic feedback for tactile response (Story 4-1)
        HapticFeedback.mediumImpact();

        // Show Day Picker Bottom Sheet (Story 4-1)
        DayPickerBottomSheet.show(
          context: context,
          itemData: TripItemData.fromLocation(
            id: location.id,
            name: location.name,
            imageUrl: location.image,
            categoryEmoji: location.categoryEmoji,
            destinationId: location.destinationId,
            destinationName: location.resolvedDestinationName,
          ),
        );
      },
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: location.image,
                width: 120,
                height: 80,
                fit: BoxFit.cover,
                memCacheHeight: 160,
                placeholder: (_, __) =>
                    const ShimmerPlaceholder.card(width: 120, height: 80),
                errorWidget: (_, __, ___) => Container(
                  width: 120,
                  height: 80,
                  color: const Color(0xFFE2E8F0),
                  child: const Icon(Icons.image, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${location.categoryEmoji} ${location.category}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
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
}
