import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/category.dart';
import '../../../recommendation/presentation/widgets/recommended_section.dart';
import '../providers/destination_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/location_card.dart';
import '../widgets/sticky_tab_bar.dart';
import '../../../trip/presentation/widgets/trip_context_banner.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';

/// Destination Hub Screen displaying destination details and locations.
///
/// Features (Story 3.4):
/// - Hero header with destination image and name (collapsible)
/// - Sticky category tabs: All, Food, Places, Stay
/// - Location cards grid with filtering
/// - Navigation to location detail
///
/// Based on Figma design node 1-220.
class DestinationHubScreen extends ConsumerWidget {
  /// Destination ID passed via route parameter
  final String destinationId;

  const DestinationHubScreen({super.key, required this.destinationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinationAsync = ref.watch(destinationByIdProvider(destinationId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SafeArea(bottom: false, child: TripContextBanner()),
          Expanded(
            child: destinationAsync.when(
              data: (destination) => _DestinationHubContent(
                destination: destination,
                destinationId: destinationId,
              ),
              loading: () => _buildLoading(),
              error: (error, stack) => _buildError(context, error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: ShimmerPlaceholder.card(
              width: double.infinity,
              height: 280,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                4,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShimmerPlaceholder.card(
                    width: index == 3 ? 200 : double.infinity,
                    height: 16,
                  ),
                ),
              ),
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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              const Text(
                'Không tìm thấy điểm đến',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Internal stateful content widget for managing tab state.
class _DestinationHubContent extends ConsumerWidget {
  final dynamic destination;
  final String destinationId;

  const _DestinationHubContent({
    required this.destination,
    required this.destinationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final filteredLocationsAsync = ref.watch(
      filteredLocationsProvider(destinationId),
    );
    final categoriesAsync = ref.watch(categoryTabsProvider);

    // Resolve categories: use dynamic data, fallback to defaults
    final categories =
        categoriesAsync.whenOrNull(data: (cats) => cats) ??
        [
          const Category(id: 'all', name: 'Tất cả', emoji: '✨', sortOrder: -1),
          ...Category.defaultCategories,
        ];

    return CustomScrollView(
      slivers: [
        // Hero header with parallax effect
        _buildHeroHeader(context, destination),

        // Sticky category tabs (dynamic from Firestore)
        SliverPersistentHeader(
          pinned: true,
          delegate: StickyTabBarDelegate(
            height: 56,
            child: CategoryTabsRow(
              selectedCategory: selectedCategory,
              categories: categories,
              onCategorySelected: (category) {
                ref.read(selectedCategoryProvider.notifier).select(category);
              },
            ),
          ),
        ),

        // AI Personalized recommendations
        RecommendedSection(destinationId: destinationId),

        // Section title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Text(
                  '🔥 Nổi bật nhất',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Text(
                  filteredLocationsAsync.whenOrNull(
                        data: (locations) => '${locations.length} địa điểm',
                      ) ??
                      '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Location cards grid
        filteredLocationsAsync.when(
          data: (locations) => _buildLocationsGrid(context, locations),
          loading: () => _buildLocationsLoading(),
          error: (error, stack) => _buildLocationsError(error.toString()),
        ),

        // Bottom spacing for safe area
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildHeroHeader(BuildContext context, destination) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.white,
      leading: _buildBackButton(context),
      actions: [
        _buildActionButton(Icons.favorite_border, () {}),
        _buildActionButton(Icons.share_outlined, () {}),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero image
            CachedNetworkImage(
              imageUrl: destination.heroImage,
              fit: BoxFit.cover,
              memCacheHeight: 600,
              placeholder: (context, url) => const ShimmerPlaceholder.card(
                width: double.infinity,
                height: 280,
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
            // Gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            // Destination info overlay
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Country flag + name
                  Row(
                    children: [
                      Text(
                        destination.countryFlag,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Việt Nam',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Destination name
                  Text(
                    destination.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle
                  Text(
                    destination.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
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
        color: Colors.black.withOpacity(0.3),
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
        color: Colors.black.withOpacity(0.3),
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

  Widget _buildLocationsGrid(BuildContext context, List locations) {
    if (locations.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(
                Icons.location_off_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có địa điểm nào',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy thử chọn danh mục khác',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75, // Height > Width for location cards
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final location = locations[index];
          return LocationCard(
            location: location,
            onTap: () {
              // Navigate to location detail
              context.push(
                '/destination/$destinationId/location/${location.id}',
                extra: location,
              );
            },
          );
        }, childCount: locations.length),
      ),
    );
  }

  Widget _buildLocationsLoading() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const ShimmerPlaceholder.card(
            width: double.infinity,
            height: 200,
          ),
          childCount: 4,
        ),
      ),
    );
  }

  Widget _buildLocationsError(String message) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              'Lỗi tải địa điểm',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
