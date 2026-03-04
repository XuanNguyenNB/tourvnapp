import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget for filtering locations by distance radius.
///
/// Displays horizontal scrollable chips:
/// - "Gần tôi" (sort by nearest)
/// - "< 1km", "< 5km", "< 10km" (filter by radius)
/// - "Tất cả" (show all)
///
/// Story 8-0.5: GPS-Based Distance Calculation
class DistanceFilterChips extends StatelessWidget {
  /// Currently selected filter
  final DistanceFilter selectedFilter;

  /// Callback when filter is selected
  final ValueChanged<DistanceFilter> onFilterSelected;

  /// Whether location is loading
  final bool isLoading;

  /// Whether location permission is denied
  final bool permissionDenied;

  /// Callback to request permission
  final VoidCallback? onRequestPermission;

  const DistanceFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    this.isLoading = false,
    this.permissionDenied = false,
    this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip(
            label: 'Gần tôi',
            emoji: '📍',
            filter: DistanceFilter.nearest,
            isLoading: isLoading && selectedFilter == DistanceFilter.nearest,
          ),
          const SizedBox(width: 8),
          _buildChip(label: '< 1km', filter: DistanceFilter.within1km),
          const SizedBox(width: 8),
          _buildChip(label: '< 5km', filter: DistanceFilter.within5km),
          const SizedBox(width: 8),
          _buildChip(label: '< 10km', filter: DistanceFilter.within10km),
          const SizedBox(width: 8),
          _buildChip(label: 'Tất cả', emoji: '✨', filter: DistanceFilter.all),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    String? emoji,
    required DistanceFilter filter,
    bool isLoading = false,
  }) {
    final isSelected = selectedFilter == filter;
    final isDisabled = permissionDenied && filter != DistanceFilter.all;

    return GestureDetector(
      onTap: isDisabled
          ? onRequestPermission
          : () {
              HapticFeedback.selectionClick();
              onFilterSelected(filter);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDisabled
              ? const Color(0xFFE5E7EB)
              : isSelected
              ? const Color(0xFF10B981)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(
                  color: isDisabled
                      ? const Color(0xFFD1D5DB)
                      : const Color(0xFFE5E7EB),
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else if (emoji != null)
              Text(emoji, style: const TextStyle(fontSize: 12)),
            if (isLoading || emoji != null) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isDisabled
                    ? const Color(0xFF9CA3AF)
                    : isSelected
                    ? Colors.white
                    : const Color(0xFF374151),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isDisabled) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.lock_outline,
                size: 12,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Distance filter options.
enum DistanceFilter {
  /// Sort by nearest (no radius filter)
  nearest,

  /// Filter to locations within 1km
  within1km,

  /// Filter to locations within 5km
  within5km,

  /// Filter to locations within 10km
  within10km,

  /// Show all locations (no distance filter)
  all,
}

/// Extension methods for DistanceFilter.
extension DistanceFilterExtension on DistanceFilter {
  /// Get the radius in meters for this filter.
  /// Returns null for "nearest" (sort only) and "all" (no filter).
  double? get radiusMeters {
    switch (this) {
      case DistanceFilter.nearest:
        return null;
      case DistanceFilter.within1km:
        return 1000;
      case DistanceFilter.within5km:
        return 5000;
      case DistanceFilter.within10km:
        return 10000;
      case DistanceFilter.all:
        return null;
    }
  }

  /// Whether this filter requires distance calculation.
  bool get requiresLocation => this != DistanceFilter.all;

  /// Whether this is a sort-only filter (no radius).
  bool get isSortOnly => this == DistanceFilter.nearest;
}
