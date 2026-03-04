import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/review_preview.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../trip/presentation/widgets/add_to_trip_gesture_wrapper.dart';
import '../../../trip/presentation/widgets/day_picker_bottom_sheet.dart';
import '../providers/distance_provider.dart';

/// A compact review card for the Explore feed.
///
/// Redesigned from Instagram-style to a minimal review-focused layout:
/// - 16:9 landscape hero image with rounded corners
/// - Rating + category badge row
/// - 2-line caption with "Xem thêm" link
/// - Compact add-to-trip icon button
/// - Location tag overlay on image
///
/// Interactions:
/// - Tap → Review Detail navigation
/// - Long-press → Day Picker Bottom Sheet
/// - Add-to-trip icon → Day Picker Bottom Sheet
class ReviewCard extends StatefulWidget {
  final ReviewPreview review;
  final VoidCallback? onTap;
  final double? distanceKm;

  const ReviewCard({
    super.key,
    required this.review,
    this.onTap,
    this.distanceKm,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Design tokens
  static const _cardRadius = 16.0;
  static const _imageAspectRatio = 16 / 9;
  static const _textPrimary = Color(0xFF1E293B);
  static const _textSecondary = Color(0xFF64748B);
  static const _cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) => _scaleController.forward();
  void _handleTapUp(TapUpDetails details) => _scaleController.reverse();
  void _handleTapCancel() => _scaleController.reverse();

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      context.push('/review/${widget.review.id}', extra: widget.review);
    }
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    _showDayPicker();
  }

  void _showDayPicker() {
    DayPickerBottomSheet.show(
      context: context,
      itemData: TripItemData.fromReview(
        id: widget.review.id,
        name: widget.review.title,
        imageUrl: widget.review.heroImage,
        destinationId: widget.review.destinationId ?? '',
        destinationName: widget.review.destinationName ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(_cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hero image 16:9
              _buildHeroImageSection(),

              // Info section below image
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.review.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Subtitle row: Location • Rating • Category
                    _buildSubtitleRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitleRow() {
    final elements = <Widget>[];

    // Location
    if (widget.review.destinationName != null) {
      elements.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, size: 14, color: Color(0xFFEF4444)),
            const SizedBox(width: 4),
            Text(
              widget.review.destinationName!,
              style: const TextStyle(
                fontSize: 13,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Rating
    if (widget.review.rating > 0) {
      if (elements.isNotEmpty) elements.add(_buildDotDivider());
      elements.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            Text(
              widget.review.rating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 13,
                color: _textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Category
    if (widget.review.categoryName != null) {
      if (elements.isNotEmpty) elements.add(_buildDotDivider());
      elements.add(
        Text(
          '${widget.review.categoryEmoji ?? ""} ${widget.review.categoryName}'
              .trim(),
          style: const TextStyle(
            fontSize: 13,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // Time ago
    if (widget.review.createdAt != null) {
      if (elements.isNotEmpty) elements.add(_buildDotDivider());
      elements.add(
        Text(
          _timeAgo(widget.review.createdAt!),
          style: const TextStyle(
            fontSize: 13,
            color: _textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: 4,
      children: elements,
    );
  }

  Widget _buildDotDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '•',
        style: TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Formats a [DateTime] as a Vietnamese relative time string.
  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7} tuần trước';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30} tháng trước';
    return '${diff.inDays ~/ 365} năm trước';
  }

  /// Hero image with 16:9 aspect ratio, rounded top corners, and distance badge.
  Widget _buildHeroImageSection() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(_cardRadius),
      ),
      child: AspectRatio(
        aspectRatio: _imageAspectRatio,
        child: Stack(
          children: [
            Positioned.fill(child: _buildHeroImage()),
            // Distance badge (top-left)
            if (widget.distanceKm != null)
              Positioned(
                top: 10,
                left: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.near_me,
                            size: 12,
                            color: Color(0xFF67E8F9),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DistanceCalculator.formatDistance(
                              widget.distanceKm!,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    final imageUrl = widget.review.heroImage;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        memCacheHeight: 500,
        placeholder: (context, url) => const ShimmerPlaceholder.card(
          width: double.infinity,
          height: double.infinity,
        ),
        errorWidget: (context, url, error) => Container(
          color: const Color(0xFFE2E8F0),
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(Icons.image, color: Colors.grey, size: 40),
      ),
    );
  }
}
