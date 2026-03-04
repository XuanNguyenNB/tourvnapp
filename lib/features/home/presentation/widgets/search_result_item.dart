import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../destination/domain/entities/location.dart';

/// Individual search result item widget.
///
/// Features (Story 8.5):
/// - Shows location name (bold, 16px)
/// - Shows destination • category (14px, muted)
/// - Category emoji mapping
/// - 64px height with tap target
/// - Haptic feedback on tap
///
/// Design reference: Story 8-5 UI Specifications
class SearchResultItem extends StatelessWidget {
  /// The location to display
  final Location location;

  /// Callback when item is tapped
  final VoidCallback onTap;

  /// Category emoji mapping
  static const Map<String, String> categoryEmojis = {
    'food': '🍜',
    'cafe': '☕',
    'attraction': '🏛️',
    'stay': '🏨',
    'places': '📍',
  };

  const SearchResultItem({
    super.key,
    required this.location,
    required this.onTap,
  });

  /// Get emoji for category
  String _getCategoryEmoji() {
    return categoryEmojis[location.category.toLowerCase()] ?? '📍';
  }

  /// Get formatted category name
  String _getFormattedCategory() {
    final categoryName = location.category.toLowerCase();
    switch (categoryName) {
      case 'food':
        return 'Ăn uống';
      case 'cafe':
        return 'Cafe';
      case 'attraction':
        return 'Tham quan';
      case 'stay':
        return 'Lưu trú';
      case 'places':
        return 'Địa điểm';
      default:
        return location.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        // Haptic feedback (AC6)
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 64, // AC4: 64px height
        padding: const EdgeInsets.symmetric(
          horizontal: 16, // Slightly more padding for better look
          vertical: 8,
        ),
        child: Row(
          children: [
            // Location icon with category color
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _getCategoryEmoji(),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Location info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location name (bold, 16px) - AC4
                  Text(
                    location.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  // Destination • Category (14px, muted) - AC4
                  Text(
                    '${location.resolvedDestinationName} • ${_getCategoryEmoji()} ${_getFormattedCategory()}',
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

            // Chevron icon
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
