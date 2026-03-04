import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/active_trip_provider.dart';
import '../providers/trips_provider.dart';
import 'trip_selector_bottom_sheet.dart';
import 'day_picker_bottom_sheet.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/day_picker_selection.dart';

/// Item data that can be added to a trip.
///
/// This is used by [AddToTripGestureWrapper] to provide context
/// for the Day Picker Bottom Sheet.
class TripItemData {
  /// Unique identifier for the item (location or review ID).
  final String id;

  /// Display name for the item.
  final String name;

  /// Optional image URL for the item thumbnail.
  final String? imageUrl;

  /// Type of item: 'location' or 'review'.
  final String type;

  /// Optional emoji/category icon.
  final String? emoji;

  /// Optional estimated duration (e.g., "1h", "30m", "1h30m").
  final String? estimatedDuration;

  /// Estimated duration in minutes for algorithmic use.
  final int? estimatedDurationMin;

  /// Destination ID for multi-destination scheduling.
  /// Example: "da-nang", "hue", "ha-noi"
  final String destinationId;

  /// Destination name for display.
  /// Example: "Đà Nẵng", "Huế", "Hà Nội"
  final String destinationName;

  const TripItemData({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.type,
    this.emoji,
    this.estimatedDuration,
    this.estimatedDurationMin,
    required this.destinationId,
    required this.destinationName,
  });

  /// Create from a location data map.
  factory TripItemData.fromLocation({
    required String id,
    required String name,
    String? imageUrl,
    String? categoryEmoji,
    String? estimatedDuration,
    int? estimatedDurationMin,
    required String destinationId,
    required String destinationName,
  }) {
    return TripItemData(
      id: id,
      name: name,
      imageUrl: imageUrl,
      type: 'location',
      emoji: categoryEmoji,
      estimatedDuration: estimatedDuration,
      estimatedDurationMin: estimatedDurationMin,
      destinationId: destinationId,
      destinationName: destinationName,
    );
  }

  /// Create from a review data map.
  /// Note: Reviews use the location's destination info.
  factory TripItemData.fromReview({
    required String id,
    required String name,
    String? imageUrl,
    required String destinationId,
    required String destinationName,
  }) {
    return TripItemData(
      id: id,
      name: name,
      imageUrl: imageUrl,
      type: 'review',
      destinationId: destinationId,
      destinationName: destinationName,
    );
  }
}

/// A reusable gesture wrapper that detects long-press to add items to a trip.
///
/// This widget wraps any child widget and provides:
/// - 200ms long-press detection (per UX spec)
/// - Haptic feedback on long-press trigger
/// - Pass-through tap functionality
/// - Optional scale animation on long-press start
///
/// Usage:
/// ```dart
/// AddToTripGestureWrapper(
///   itemData: TripItemData.fromLocation(
///     id: location.id,
///     name: location.name,
///     imageUrl: location.image,
///   ),
///   onTap: () => navigateToDetail(),
///   child: LocationCard(location: location),
/// )
/// ```
class AddToTripGestureWrapper extends ConsumerStatefulWidget {
  /// The child widget to wrap.
  final Widget child;

  /// Data about the item that will be added to trip on long-press.
  final TripItemData itemData;

  /// Optional callback when card is tapped (preserved from wrapped widget).
  final VoidCallback? onTap;

  /// Optional callback when long-press is detected.
  /// If not provided, shows the Day Picker Bottom Sheet.
  final VoidCallback? onLongPress;

  /// Optional callback when day/time selection is complete.
  final void Function(DayPickerSelection selection)? onSelectionComplete;

  /// Duration to wait before recognizing long-press.
  /// Default is 500ms to avoid accidental triggers during scrolling.
  final Duration longPressDuration;

  /// Whether to show scale animation on long-press start.
  final bool enableScaleAnimation;

  /// Maximum movement allowed during long-press (in logical pixels).
  /// If finger moves more than this, long-press is cancelled.
  /// Default is 10.0 pixels to allow slight finger wobble.
  final double movementTolerance;

  const AddToTripGestureWrapper({
    super.key,
    required this.child,
    required this.itemData,
    this.onTap,
    this.onLongPress,
    this.onSelectionComplete,
    this.longPressDuration = const Duration(milliseconds: 500),
    this.enableScaleAnimation = true,
    this.movementTolerance = 10.0,
  });

  @override
  ConsumerState<AddToTripGestureWrapper> createState() =>
      _AddToTripGestureWrapperState();
}

class _AddToTripGestureWrapperState
    extends ConsumerState<AddToTripGestureWrapper>
    with SingleTickerProviderStateMixin {
  Timer? _longPressTimer;
  Timer? _scaleAnimationDelayTimer;
  bool _isLongPressing = false;
  bool _hasMovedBeyondTolerance = false;
  Offset? _pointerDownPosition;

  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _scaleAnimationDelayTimer?.cancel();
    _scaleController.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerDownPosition = event.position;
    _hasMovedBeyondTolerance = false;

    _longPressTimer = Timer(widget.longPressDuration, () {
      if (mounted) {
        _triggerLongPress();
      }
    });

    // Delay scale animation to avoid visual feedback during normal scrolling
    if (widget.enableScaleAnimation) {
      _scaleAnimationDelayTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted && _longPressTimer != null && !_hasMovedBeyondTolerance) {
          _scaleController.forward();
        }
      });
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_pointerDownPosition == null || _hasMovedBeyondTolerance) return;

    // Cancel if finger moved beyond tolerance (likely scrolling)
    final distance = (event.position - _pointerDownPosition!).distance;
    if (distance > widget.movementTolerance) {
      _hasMovedBeyondTolerance = true;
      _cancelLongPress();
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final wasLongPressing = _isLongPressing;
    final wasMoved = _hasMovedBeyondTolerance;
    _cancelLongPress();

    // Only treat as tap if:
    // 1. We weren't long-pressing
    // 2. Finger didn't move beyond tolerance (not scrolling)
    if (!wasLongPressing && !wasMoved && widget.onTap != null) {
      widget.onTap!();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _cancelLongPress();
  }

  void _cancelLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _scaleAnimationDelayTimer?.cancel();
    _scaleAnimationDelayTimer = null;
    _isLongPressing = false;
    _pointerDownPosition = null;
    // Note: Don't reset _hasMovedBeyondTolerance here - it's needed in _handlePointerUp
    if (widget.enableScaleAnimation) {
      _scaleController.reverse();
    }
  }

  void _triggerLongPress() {
    _isLongPressing = true;

    // Trigger haptic feedback immediately (NFR2 - <500ms response)
    HapticFeedback.mediumImpact();

    // Reset scale animation
    if (widget.enableScaleAnimation) {
      _scaleController.reverse();
    }

    // Execute callback or show default bottom sheet
    if (widget.onLongPress != null) {
      widget.onLongPress!();
    } else {
      _showDayPickerSheet();
    }
  }

  Future<void> _showDayPickerSheet() async {
    Trip? activeTrip = ref.read(activeTripProvider);

    if (activeTrip == null) {
      final userTripsAsync = ref.read(userTripsProvider);
      final hasTrips =
          userTripsAsync.hasValue &&
          userTripsAsync.value != null &&
          userTripsAsync.value!.isNotEmpty;

      if (hasTrips) {
        final selectedTrip = await TripSelectorBottomSheet.show(
          context: context,
        );
        if (selectedTrip == null) {
          // User dismissed the dialog or chose 'Tạo chuyến đi mới' which navigates
          return;
        }
        ref.read(activeTripProvider.notifier).setActiveTrip(selectedTrip);
        activeTrip = selectedTrip;
      }
    }

    if (!mounted) return;

    final selection = await DayPickerBottomSheet.show(
      context: context,
      itemData: widget.itemData,
      activeTrip: activeTrip,
    );
    if (selection != null && widget.onSelectionComplete != null) {
      widget.onSelectionComplete!(selection);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );

    if (widget.enableScaleAnimation) {
      child = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: child,
      );
    }

    return child;
  }
}
