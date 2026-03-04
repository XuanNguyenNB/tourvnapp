import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../domain/entities/content_item.dart';
import 'destination_card.dart';
import 'review_card.dart';

/// Bento Grid widget displaying mixed content in masonry layout.
///
/// Uses flutter_staggered_grid_view for masonry layout.
/// Content items alternate between destinations and reviews
/// with varying sizes (1x1, 2x1, 1x2) for visual interest.
///
/// See Story 3.1 AC #1, #2 for requirements.
class BentoGrid extends StatelessWidget {
  final List<ContentItem> items;
  final void Function(String id)? onDestinationTap;
  final void Function(String id)? onReviewTap;

  const BentoGrid({
    super.key,
    required this.items,
    this.onDestinationTap,
    this.onReviewTap,
  });

  @override
  Widget build(BuildContext context) {
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: _buildGridItems(),
    );
  }

  List<Widget> _buildGridItems() {
    final List<Widget> gridItems = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final tileSize = _getTileSize(i, item);

      gridItems.add(
        StaggeredGridTile.count(
          crossAxisCellCount: tileSize.crossAxisCells,
          mainAxisCellCount: tileSize.mainAxisCells,
          child: _buildItemCard(item),
        ),
      );
    }

    return gridItems;
  }

  Widget _buildItemCard(ContentItem item) {
    return switch (item) {
      DestinationContent(destination: final destination) => DestinationCard(
        destination: destination,
        onTap: () => onDestinationTap?.call(destination.id),
      ),
      ReviewContent(review: final review) => ReviewCard(
        review: review,
        onTap: () => onReviewTap?.call(review.id),
      ),
    };
  }

  /// Determine tile size based on item index and type.
  /// Creates visual rhythm with alternating patterns.
  _TileSize _getTileSize(int index, ContentItem item) {
    // First item is always full width (hero)
    if (index == 0) {
      return const _TileSize(crossAxisCells: 2, mainAxisCells: 1.2);
    }

    // Reviews are typically wider for readability
    if (item is ReviewContent) {
      return const _TileSize(crossAxisCells: 2, mainAxisCells: 0.7);
    }

    // Destinations alternate between sizes
    if (item is DestinationContent) {
      final destination = item.destination;
      if (destination.sizeHint >= 2) {
        return const _TileSize(crossAxisCells: 2, mainAxisCells: 1.2);
      }
      return const _TileSize(crossAxisCells: 1, mainAxisCells: 1.2);
    }

    // Default size
    return const _TileSize(crossAxisCells: 1, mainAxisCells: 1.0);
  }
}

/// Helper class for tile dimensions
class _TileSize {
  final int crossAxisCells;
  final double mainAxisCells;

  const _TileSize({required this.crossAxisCells, required this.mainAxisCells});
}
