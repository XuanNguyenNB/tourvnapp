import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/content_item.dart';
import '../providers/filtered_home_content_provider.dart';
import '../providers/home_provider.dart';
import '../providers/location_search_provider.dart';
import '../providers/distance_provider.dart';
import '../providers/user_location_provider.dart';
import '../widgets/suggestion_chips_row.dart';
import '../widgets/review_card.dart';
import '../widgets/search_bar_widget.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../widgets/home_recommended_section.dart';
import '../../../../core/services/location_service.dart';

/// Home Screen with Instagram-style feed layout.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  SuggestionData? _activeSuggestion;
  String? _boostCategory;

  int _displayCount = 10;
  bool _isLoadingMore = false;

  /// Tracks whether initial data has been loaded at least once.
  bool _initialDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoadingMore = true;
    });
    // Simulate network delay for loading more
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _displayCount += 10;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    ref.invalidate(homeContentProvider);
    ref.invalidate(filteredHomeContentProvider);
    setState(() {
      _displayCount = 10;
    });
    await ref
        .read(filteredHomeContentProvider.future)
        .catchError((_) => <ContentItem>[]);
  }

  /// Whether the current chip is "Gợi ý cho bạn" (recommendation-only, no feed filter).
  bool get _isRecommendationChip =>
      _activeSuggestion != null && _activeSuggestion!.label == 'Gợi ý cho bạn';

  /// Handle chip tap: request GPS if needed, set boost category, scroll.
  void _handleChipTap(SuggestionData? suggestion) {
    setState(() {
      _activeSuggestion = suggestion;
      _displayCount = 10;
    });

    if (suggestion == null) {
      // Chip deselected — clear boost
      setState(() => _boostCategory = null);
      return;
    }

    // Determine boost category based on chip
    String? newBoost;
    if (suggestion.filterType == SuggestionFilterType.category) {
      newBoost = suggestion.filterValue;
    }
    setState(() => _boostCategory = newBoost);

    // Request GPS for location-aware chips
    final needsGps =
        suggestion.filterType == SuggestionFilterType.nearMe ||
        suggestion.label == 'Gợi ý cho bạn';

    if (needsGps) {
      _requestLocationIfNeeded();
    }
  }

  /// Request location permission and load position if not already available.
  Future<void> _requestLocationIfNeeded() async {
    final locationState = ref.read(userLocationProvider);

    if (locationState.hasPosition) return; // Already have position

    final notifier = ref.read(userLocationProvider.notifier);

    if (locationState.permissionStatus == LocationPermissionStatus.granted) {
      // Permission granted but no position yet — load it
      await notifier.loadPosition();
      return;
    }

    if (locationState.permissionStatus ==
        LocationPermissionStatus.permanentlyDenied) {
      // Need to go to settings
      if (mounted) _showPermissionDeniedDialog();
      return;
    }

    // Request permission
    final granted = await notifier.requestPermission();
    if (!granted && mounted) {
      _showPermissionDeniedDialog();
    }
  }

  /// Dialog khi quyền vị trí bị từ chối.
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Color(0xFF8B5CF6)),
            SizedBox(width: 8),
            Text('Cần quyền vị trí'),
          ],
        ),
        content: const Text(
          'Để gợi ý địa điểm gần bạn, ứng dụng cần truy cập vị trí. '
          'Vui lòng bật trong Cài đặt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(userLocationProvider.notifier).openSettings();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
            child: const Text('Mở Cài đặt'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color(0xFF8B5CF6),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App header (logo + profile)
              SliverToBoxAdapter(child: _buildAppHeader(context)),

              // Search Bar (Story 8-5)
              SliverToBoxAdapter(child: _buildSearchBar(context, ref)),

              // Suggestion Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: SuggestionChipsRow(
                    onSuggestionTap: (suggestion) {
                      _handleChipTap(suggestion);
                    },
                  ),
                ),
              ),

              // ✨ AI Recommendations section — always visible, independent from pills
              SliverToBoxAdapter(
                child: HomeRecommendedSection(boostCategory: _boostCategory),
              ),

              // Instagram-style Review Feed (filtered by pills)
              _buildReviewFeed(context, ref),

              // Bottom spacing for floating nav bar overlap
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the Gen Z app header with gradient logo, greeting, and avatar.
  Widget _buildAppHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo + Greeting
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Xin chào! 👋',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
              // Gradient logo text
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppGradients.primaryGradient.createShader(bounds),
                child: const Text(
                  'TourVN',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white, // Gets masked by gradient
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          // Right side: notification + avatar
          Row(
            children: [
              // Notification bell
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  size: 22,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 10),
              // Gradient ring avatar
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.primaryGradient,
                  ),
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 20,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the Search Bar section (Story 8-5/8-6).
  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(locationSearchProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SearchBarWidget(
        controller: _searchController,
        onSearch: (query) {
          ref.read(locationSearchProvider.notifier).search(query);
        },
        onDestinationSelected: (destination) {
          context.push('/destination/${destination.id}');
        },
        onLocationSelected: (location) {
          context.push(
            '/location/${location.destinationId}/${location.id}',
            extra: location,
          );
        },
        onReviewSelected: (review) {
          context.push('/review/${review.id}');
        },
        searchDestinations: searchState.destinations,
        searchLocations: searchState.locations,
        searchReviews: searchState.reviews,
        isLoading: searchState.isLoading,
        errorMessage: searchState.errorMessage,
      ),
    );
  }

  /// Builds the Instagram-style review feed, filtered by active suggestion.
  ///
  /// "Gợi ý cho bạn" chip does NOT filter the feed — it only affects
  /// the recommendation section. All other chips filter normally.
  Widget _buildReviewFeed(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(filteredHomeContentProvider);

    return contentAsync.when(
      data: (items) {
        // Get all reviews
        var reviews = items
            .whereType<ReviewContent>()
            .map((rc) => rc.review)
            .toList();

        // Apply suggestion filter (skip for "Gợi ý cho bạn" chip)
        if (_activeSuggestion != null && !_isRecommendationChip) {
          final suggestion = _activeSuggestion!;
          if (suggestion.filterType == SuggestionFilterType.nearMe) {
            // GPS sort: attach distances and sort by nearest
            final locationState = ref.watch(userLocationProvider);
            if (locationState.hasPosition) {
              reviews = DistanceCalculator.attachDistances(
                reviews: reviews,
                userLat: locationState.position!.latitude,
                userLng: locationState.position!.longitude,
              );
              reviews = DistanceCalculator.sortByDistance(reviews);
            } else if (!locationState.isLoading) {
              // Auto-request location if not loaded yet
              Future.microtask(() {
                ref.read(userLocationProvider.notifier).loadPosition();
              });
            }
          } else {
            reviews = reviews.where((review) {
              switch (suggestion.filterType) {
                case SuggestionFilterType.category:
                  return review.category == suggestion.filterValue;
                case SuggestionFilterType.mood:
                  return review.moods?.contains(suggestion.filterValue) ??
                      false;
                case SuggestionFilterType.nearMe:
                  return true; // Handled above
                case SuggestionFilterType.none:
                  // Text-based match for non-category/mood chips
                  final query = suggestion.searchQuery.toLowerCase();
                  return (review.shortText?.toLowerCase().contains(query) ??
                          false) ||
                      review.title.toLowerCase().contains(query);
              }
            }).toList();
          }
        } else {
          // No filter or recommendation chip — attach distance info for badges
          final locationState = ref.watch(userLocationProvider);
          if (locationState.hasPosition) {
            reviews = DistanceCalculator.attachDistances(
              reviews: reviews,
              userLat: locationState.position!.latitude,
              userLng: locationState.position!.longitude,
            );
          }
        }

        if (reviews.isEmpty) {
          if (!_initialDataLoaded) {
            _initialDataLoaded = true;
            return SliverToBoxAdapter(child: _buildInitialLoadingState());
          }
          return SliverToBoxAdapter(child: _buildEmptyState());
        }

        if (!_initialDataLoaded) _initialDataLoaded = true;

        final displayedReviews = reviews.take(_displayCount).toList();

        return SliverList.separated(
          itemCount:
              displayedReviews.length +
              (_isLoadingMore && _displayCount < reviews.length ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == displayedReviews.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              );
            }
            final review = displayedReviews[index];
            return ReviewCard(
              review: review,
              distanceKm: review.distanceKm,
              onTap: () => context.push('/review/${review.id}'),
            );
          },
        );
      },
      loading: () => SliverToBoxAdapter(child: _buildLoadingFeed()),
      error: (error, stack) {
        // Mặc dù đã dùng future, nếu có exception mạng thực sự, ta hiện lỗi
        return SliverToBoxAdapter(child: _buildErrorState(error.toString()));
      },
    );
  }

  /// Animated loading state shown on initial load before empty state.
  Widget _buildInitialLoadingState() {
    return _DelayedEmptyState(
      onTimeout: () {
        if (mounted) setState(() {});
      },
    );
  }

  /// Empty state when no reviews match filters.
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy bài viết nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử bỏ bộ lọc hoặc chọn điểm đến khác',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// Loading shimmer with fun animation for first-time experience.
  Widget _buildLoadingFeed() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Fun loading indicator
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Column(
                children: [
                  // Animated travel icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: -10, end: 10),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeInOut,
                    builder: (context, bounce, _) {
                      return Transform.translate(
                        offset: Offset(0, bounce.abs() - 5),
                        child: const Text('✈️', style: TextStyle(fontSize: 36)),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Đang khám phá cho bạn...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '🗺️ Tìm kiếm những trải nghiệm tuyệt vời',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        // Shimmer cards
        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ShimmerPlaceholder.card(width: double.infinity, height: 380),
          ),
        ),
      ],
    );
  }

  /// Error state widget.
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a loading animation for a few seconds, then calls [onTimeout].
class _DelayedEmptyState extends StatefulWidget {
  final VoidCallback onTimeout;
  const _DelayedEmptyState({required this.onTimeout});

  @override
  State<_DelayedEmptyState> createState() => _DelayedEmptyStateState();
}

class _DelayedEmptyStateState extends State<_DelayedEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onTimeout();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  -8 * (1 - (2 * (_controller.value - 0.5)).abs()),
                ),
                child: child,
              );
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    const Color(0xFFEC4899).withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('🗺️', style: TextStyle(fontSize: 28)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Đợi xíu nhé...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đang tìm kiếm nội dung cho bạn',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 140,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF8B5CF6),
                ),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
