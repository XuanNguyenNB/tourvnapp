import 'package:flutter/material.dart';

import '../../../destination/domain/entities/destination.dart';
import '../../../destination/domain/entities/location.dart';
import '../../../review/domain/entities/review.dart';
import 'search_result_item.dart';

/// Overlay widget displaying search results below the search bar.
///
/// Features (Story 8.5):
/// - Positioned below search bar with 8px gap
/// - Rounded corners (16px radius) with shadow
/// - Max height 400px, scrollable
/// - Shows loading indicator when searching
/// - Shows empty state when no results
/// - Max 8 results displayed
///
/// Design reference: Story 8-5 UI Specifications
class SearchResultsOverlay extends StatelessWidget {
  final List<Destination> destinations;
  final List<Location> locations;
  final List<Review> reviews;

  /// Whether search is currently loading
  final bool isLoading;

  /// Error message if search failed
  final String? errorMessage;

  /// Callbacks
  final Function(Destination) onDestinationSelected;
  final Function(Location) onLocationSelected;
  final Function(Review) onReviewSelected;

  /// Maximum number of results to show per category
  static const int maxResults = 5;

  const SearchResultsOverlay({
    super.key,
    required this.destinations,
    required this.locations,
    required this.reviews,
    required this.onDestinationSelected,
    required this.onLocationSelected,
    required this.onReviewSelected,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: colorScheme.surface,
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 400, // Max height with scrolling
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _buildContent(context, colorScheme),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    // Loading state (AC8)
    if (isLoading) {
      return _buildLoadingState(colorScheme);
    }

    // Error state
    if (errorMessage != null) {
      return _buildErrorState(colorScheme);
    }

    // Empty state (AC5)
    if (destinations.isEmpty && locations.isEmpty && reviews.isEmpty) {
      return _buildEmptyState(colorScheme);
    }

    // Results list (AC4)
    return _buildResultsList(context, colorScheme);
  }

  /// Loading indicator (AC8)
  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Đang tìm kiếm...',
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Empty state when no results found (AC5)
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Không tìm thấy địa điểm nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Thử tìm với từ khóa khác',
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Error state
  Widget _buildErrorState(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 40, color: colorScheme.error),
          const SizedBox(height: 8),
          Text(
            'Có lỗi xảy ra',
            style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            errorMessage ?? 'Vui lòng thử lại',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Results list (AC4)
  Widget _buildResultsList(BuildContext context, ColorScheme colorScheme) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (destinations.isNotEmpty) ...[
          _buildSectionHeader('ĐIỂM ĐẾN', colorScheme),
          ...destinations.map((d) => _buildDestinationItem(d, colorScheme)),
          if (locations.isNotEmpty || reviews.isNotEmpty)
            Divider(height: 16, color: colorScheme.outline.withOpacity(0.2)),
        ],
        if (locations.isNotEmpty) ...[
          _buildSectionHeader('ĐỊA ĐIỂM', colorScheme),
          ...locations.map(
            (l) => SearchResultItem(
              location: l,
              onTap: () => onLocationSelected(l),
            ),
          ),
          if (reviews.isNotEmpty)
            Divider(height: 16, color: colorScheme.outline.withOpacity(0.2)),
        ],
        if (reviews.isNotEmpty) ...[
          _buildSectionHeader('BÀI VIẾT', colorScheme),
          ...reviews.map((r) => _buildReviewItem(r, colorScheme)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDestinationItem(
    Destination destination,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: () => onDestinationSelected(destination),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🗺️', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destination.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(Review review, ColorScheme colorScheme) {
    return InkWell(
      onTap: () => onReviewSelected(review),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('📝', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'bởi ${review.authorName} • ${review.destinationName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
