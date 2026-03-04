import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/location.dart';
import '../providers/location_provider.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../trip/presentation/widgets/add_to_trip_gesture_wrapper.dart';
import '../../../trip/presentation/widgets/day_picker_bottom_sheet.dart';
import '../../../recommendation/presentation/providers/recommendation_provider.dart';
import '../../../recommendation/domain/entities/user_interaction_event.dart';

/// Location Detail Screen displaying full location information.
///
/// Features (Story 3.7):
/// - Full-bleed hero image with gradient overlay
/// - Location name, category badge, address
/// - Description text section
/// - "Thêm vào Trip" gradient CTA button
class LocationDetailScreen extends ConsumerWidget {
  final String locationId;
  final Location? location;

  const LocationDetailScreen({
    super.key,
    required this.locationId,
    this.location,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (location != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: _LocationDetailContent(location: location!),
      );
    }

    final locationAsync = ref.watch(locationByIdProvider(locationId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: locationAsync.when(
        data: (loc) => _LocationDetailContent(location: loc),
        loading: () => _buildLoading(),
        error: (error, stack) => _buildError(context, error.toString()),
      ),
    );
  }

  Widget _buildLoading() {
    return const CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 350,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: ShimmerPlaceholder.card(
              width: double.infinity,
              height: 350,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerPlaceholder.card(width: 100, height: 24),
                SizedBox(height: 12),
                ShimmerPlaceholder.card(width: double.infinity, height: 32),
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
              'Không tìm thấy địa điểm',
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

/// Internal content widget with location data available.
///
/// Uses ConsumerStatefulWidget to:
/// - Log a 'view' event once when the page is opened (for recommendation engine)
/// - Access ref for event logging on user actions
class _LocationDetailContent extends ConsumerStatefulWidget {
  final Location location;

  const _LocationDetailContent({required this.location});

  @override
  ConsumerState<_LocationDetailContent> createState() =>
      _LocationDetailContentState();
}

class _LocationDetailContentState
    extends ConsumerState<_LocationDetailContent> {
  Location get location => widget.location;

  @override
  void initState() {
    super.initState();
    // Log 'view' event once when location detail is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      logUserEvent(
        ref,
        locationId: location.id,
        destinationId: location.destinationId,
        type: InteractionType.view,
        locationCategory: location.category,
        locationTags: location.tags,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            _buildHeroHeader(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection(),
                    const SizedBox(height: 24),
                    _buildDescriptionSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Sticky CTA button
        Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          child: GradientButton(
            text: 'Thêm vào Trip',
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () {
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
            borderRadius: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.white,
      leading: _buildBackButton(context),
      actions: [
        _buildActionButton(Icons.favorite_border, () {
          // Log 'save' event for recommendation engine
          logUserEvent(
            ref,
            locationId: location.id,
            destinationId: location.destinationId,
            type: InteractionType.save,
            locationCategory: location.category,
            locationTags: location.tags,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã lưu vào yêu thích ❤️'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        }),
        _buildActionButton(Icons.share_outlined, () {}),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: location.image,
              fit: BoxFit.cover,
              memCacheHeight: 700,
              placeholder: (context, url) => const ShimmerPlaceholder.card(
                width: double.infinity,
                height: 350,
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
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCategoryBadge(),
                  const SizedBox(height: 8),
                  Text(
                    location.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
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

  Widget _buildBackButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed) {
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

  Widget _buildCategoryBadge() {
    final (bgColor, textColor) = _getCategoryColors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(location.categoryEmoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            location.category[0].toUpperCase() + location.category.substring(1),
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _getCategoryColors() {
    switch (location.category.toLowerCase()) {
      case 'food':
        return (const Color(0xFFFEF3C7), const Color(0xFF92400E));
      case 'places':
        return (const Color(0xFFDBEAFE), const Color(0xFF1E40AF));
      case 'stay':
        return (const Color(0xFFD1FAE5), const Color(0xFF065F46));
      default:
        return (const Color(0xFFF1F5F9), const Color(0xFF475569));
    }
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (location.address != null) ...[
          Row(
            children: [
              const Icon(
                Icons.pin_drop_outlined,
                size: 18,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location.address!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            if (location.rating != null) ...[
              const Icon(Icons.star, size: 18, color: Color(0xFFFBBF24)),
              const SizedBox(width: 4),
              Text(
                location.rating!.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Icon(Icons.visibility_outlined, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              location.formattedViewCount,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(width: 16),
            Icon(Icons.bookmark_outline, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              location.formattedSaveCount,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            if (location.priceRange != null) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    location.priceRange!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giới thiệu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          location.description ?? 'Chưa có mô tả cho địa điểm này.',
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
