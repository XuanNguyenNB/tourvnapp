import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../destination/domain/entities/destination.dart';
import '../../../destination/domain/entities/location.dart';
import '../../../review/domain/entities/review.dart';
import 'search_results_overlay.dart';

/// Search bar widget for the home screen with full search functionality.
///
/// Features (Story 8.5):
/// - 56px height with fully rounded corners (28px radius)
/// - Search icon that changes color on focus
/// - Clear button when text is entered
/// - Debounced search (300ms) for performance
/// - Haptic feedback on focus
/// - Results overlay display
///
/// This component handles the UI and delegates search execution
/// to the parent via [onSearch] callback.
class SearchBarWidget extends StatefulWidget {
  /// Callback when search query changes (debounced 300ms)
  final Function(String) onSearch;

  /// Callbacks when user selects an item from results
  final Function(Destination) onDestinationSelected;
  final Function(Location) onLocationSelected;
  final Function(Review) onReviewSelected;

  /// Current search results to display
  final List<Destination> searchDestinations;
  final List<Location> searchLocations;
  final List<Review> searchReviews;

  /// Whether search is currently loading
  final bool isLoading;

  /// Error message if search failed
  final String? errorMessage;

  /// Placeholder text for the search bar
  final String placeholder;

  /// Optional external controller for programmatic text updates.
  final TextEditingController? controller;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    required this.onDestinationSelected,
    required this.onLocationSelected,
    required this.onReviewSelected,
    this.controller,
    this.searchDestinations = const [],
    this.searchLocations = const [],
    this.searchReviews = const [],
    this.isLoading = false,
    this.errorMessage,
    this.placeholder = 'Tìm kiếm địa điểm, quán ăn...',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _isFocused = false;
  bool _showOverlay = false;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChanged);
  }

  void _onFocusChange() {
    final wasFocused = _isFocused;
    setState(() => _isFocused = _focusNode.hasFocus);

    // Trigger haptic feedback when gaining focus (AC2)
    if (!wasFocused && _isFocused) {
      HapticFeedback.lightImpact();
    }

    // Update overlay visibility
    _updateOverlayVisibility();
  }

  void _onTextChanged() {
    setState(() {});
    _updateOverlayVisibility();
  }

  void _updateOverlayVisibility() {
    final shouldShow = _isFocused && _controller.text.isNotEmpty;
    if (_showOverlay != shouldShow) {
      setState(() => _showOverlay = shouldShow);
    }
  }

  /// Handle search input with 300ms debounce (AC3)
  void _onSearchChanged(String query) {
    // Cancel previous debounce timer
    _debounce?.cancel();

    if (query.isEmpty) {
      // Clear results immediately when text is empty
      widget.onSearch('');
      return;
    }

    // Start new debounce timer (300ms)
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(query);
    });
  }

  /// Clear search text and close overlay (AC7)
  void _clearSearch() {
    _controller.clear();
    widget.onSearch('');
    setState(() => _showOverlay = false);
    HapticFeedback.lightImpact();
  }

  /// Handle location selection from results (AC6)
  void _onLocationSelected(Location location) {
    _dismissAndClearSearch();
    widget.onLocationSelected(location);
  }

  void _onDestinationSelected(Destination destination) {
    _dismissAndClearSearch();
    widget.onDestinationSelected(destination);
  }

  void _onReviewSelected(Review review) {
    _dismissAndClearSearch();
    widget.onReviewSelected(review);
  }

  void _dismissAndClearSearch() {
    // Dismiss keyboard
    _focusNode.unfocus();

    // Close overlay
    setState(() => _showOverlay = false);

    // Clear search text
    _controller.clear();

    // Trigger haptic feedback
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_ownsController) _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search Bar Container
        _buildSearchBar(colorScheme),

        // Results Overlay
        if (_showOverlay)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SearchResultsOverlay(
              destinations: widget.searchDestinations,
              locations: widget.searchLocations,
              reviews: widget.searchReviews,
              isLoading: widget.isLoading,
              errorMessage: widget.errorMessage,
              onDestinationSelected: _onDestinationSelected,
              onLocationSelected: _onLocationSelected,
              onReviewSelected: _onReviewSelected,
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Container(
      height: 56, // AC1: 56px height
      decoration: BoxDecoration(
        color: colorScheme.surface, // AC1: surface background
        borderRadius: BorderRadius.circular(28), // Fully rounded
        border: Border.all(
          color: _isFocused ? colorScheme.primary : colorScheme.outline,
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      // Clip content to match border radius
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Row(
          children: [
            // Search icon with proper spacing
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(
                Icons.search,
                size: 22,
                color: _isFocused
                    ? colorScheme
                          .primary // AC2: primary when focused
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            // Expanded TextField
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: widget.placeholder, // AC1: placeholder text
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 18,
                  ),
                ),
              ),
            ),
            // Clear button (AC7)
            if (_controller.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: _clearSearch,
                  tooltip: 'Xóa',
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
