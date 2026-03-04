import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/home_recommendation_provider.dart';
import '../providers/user_location_provider.dart';
import '../../../destination/presentation/providers/destination_provider.dart';
import '../../../destination/domain/entities/location.dart';
import '../../../recommendation/domain/entities/recommendation_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';

/// A horizontal scrollable section showing personalized recommendations
/// on the Home screen.
///
/// Uses [homeRecommendationsProvider] to fetch AI-driven suggestions
/// based on user mood preferences, interaction history, and GPS proximity.
class HomeRecommendedSection extends ConsumerWidget {
  /// Optional category to boost (e.g. 'places' for check-in).
  final String? boostCategory;

  const HomeRecommendedSection({super.key, this.boostCategory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user position for proximity scoring
    final locationState = ref.watch(userLocationProvider);
    final params = HomeRecParams(
      lat: locationState.position?.latitude,
      lng: locationState.position?.longitude,
      boostCategory: boostCategory,
    );

    final recAsync = ref.watch(homeRecommendationsProvider(params));

    return recAsync.when(
      loading: () => _buildLoading(),
      error: (_, __) => const SizedBox.shrink(),
      data: (recommendations) {
        if (recommendations.isEmpty) return const SizedBox.shrink();
        return _RecommendedSectionResolver(
          recommendations: recommendations,
          userPosition: locationState.position,
        );
      },
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '✨ Gợi ý cho bạn',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) => _ShimmerRecommendedCard(index: index),
            ),
          ),
        ],
      ),
    );
  }
}

/// Resolves location data for recommendations and builds the UI.
class _RecommendedSectionResolver extends ConsumerWidget {
  final List<RecommendationItem> recommendations;
  final Position? userPosition;

  const _RecommendedSectionResolver({
    required this.recommendations,
    this.userPosition,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destRepo = ref.watch(destinationRepositoryProvider);

    return FutureBuilder<List<Location>>(
      future: destRepo.getAllLocations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final locMap = {for (final l in snapshot.data!) l.id: l};
        final validRecs = recommendations
            .where((r) => locMap.containsKey(r.locationId))
            .take(6)
            .toList();

        if (validRecs.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      '✨ Gợi ý cho bạn',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: validRecs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final rec = validRecs[index];
                    final loc = locMap[rec.locationId]!;

                    // Calculate distance if we have user position + location GPS
                    double? distanceKm;
                    if (userPosition != null &&
                        loc.latitude != null &&
                        loc.longitude != null) {
                      distanceKm =
                          Geolocator.distanceBetween(
                            userPosition!.latitude,
                            userPosition!.longitude,
                            loc.latitude!,
                            loc.longitude!,
                          ) /
                          1000.0;
                    }

                    return _HomeRecommendedCard(
                      location: loc,
                      reasons: rec.reasons,
                      distanceKm: distanceKm,
                      onTap: () {
                        context.push(
                          '/location/${loc.destinationId}/${loc.id}',
                          extra: loc,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeRecommendedCard extends StatelessWidget {
  final Location location;
  final List<String> reasons;
  final double? distanceKm;
  final VoidCallback onTap;

  const _HomeRecommendedCard({
    required this.location,
    required this.reasons,
    this.distanceKm,
    required this.onTap,
  });

  String _formatDist(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 100) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 110,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: location.image,
                    fit: BoxFit.cover,
                    memCacheHeight: 220,
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(Icons.image_outlined, size: 32),
                    ),
                  ),
                  // Category badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        location.categoryEmoji,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  // Distance badge
                  if (distanceKm != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.near_me,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatDist(distanceKm!),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (reasons.isNotEmpty)
                      Text(
                        reasons.first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (location.rating != null) ...[
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 12,
                            color: Color(0xFFFBBF24),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            location.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _ShimmerRecommendedCard extends StatelessWidget {
  final int index;
  const _ShimmerRecommendedCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 150),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerPlaceholder(width: 160, height: 110, borderRadius: 0),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerPlaceholder.line(width: 120, height: 14),
                  const SizedBox(height: 8),
                  ShimmerPlaceholder.line(width: 80, height: 11),
                  const SizedBox(height: 12),
                  ShimmerPlaceholder.line(width: 50, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
