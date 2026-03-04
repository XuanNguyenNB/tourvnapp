import 'package:flutter/material.dart';
import '../../domain/entities/trip.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_to_trip_gesture_wrapper.dart';
import 'day_pills_list.dart';
import 'time_slot_selector.dart';
import 'day_picker_item_preview.dart';
import 'schedule_warning_banner.dart';
import 'day_picker_action_buttons.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/entities/day_picker_selection.dart';
import '../../domain/entities/pending_activity.dart';
import '../../domain/entities/schedule_validation_result.dart';
import '../../domain/services/trip_schedule_validation_service.dart';
import '../providers/pending_trip_provider.dart';
import '../providers/trip_save_provider.dart';
import '../helpers/trip_feedback_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/helpers/sign_in_prompt_helper.dart';

/// Day Picker Bottom Sheet for selecting which day and time to add items.
///
/// Displays:
/// - Item preview header with thumbnail and name
/// - Destination info display
/// - Horizontal scrollable day pills (Day 1, Day 2, Day 3...)
/// - Schedule conflict warning banner (when applicable)
/// - Time slot selector (Sáng, Trưa, Chiều, Tối)
/// - Action buttons with suggestion support
class DayPickerBottomSheet extends ConsumerStatefulWidget {
  /// Data about the item being added to trip.
  final TripItemData itemData;

  /// Optional active trip context
  final Trip? activeTrip;

  /// Optional callback when selection is confirmed.
  final void Function(DayPickerSelection selection)? onConfirm;

  const DayPickerBottomSheet({
    super.key,
    required this.itemData,
    this.activeTrip,
    this.onConfirm,
  });

  /// Show the Day Picker Bottom Sheet.
  static Future<DayPickerSelection?> show({
    required BuildContext context,
    required TripItemData itemData,
    Trip? activeTrip,
    void Function(DayPickerSelection selection)? onConfirm,
  }) {
    return showModalBottomSheet<DayPickerSelection>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DayPickerBottomSheet(
        itemData: itemData,
        activeTrip: activeTrip,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  ConsumerState<DayPickerBottomSheet> createState() =>
      _DayPickerBottomSheetState();
}

class _DayPickerBottomSheetState extends ConsumerState<DayPickerBottomSheet> {
  late List<int> _days;
  int _selectedDay = 0;
  TimeSlot? _selectedTimeSlot;
  ScheduleValidationResult? _validationResult;
  String? _existingDestinationName;
  final GlobalKey<DayPillsListState> _dayPillsKey = GlobalKey();
  final TripScheduleValidationService _validationService =
      TripScheduleValidationService();

  @override
  void initState() {
    super.initState();
    final totalDays = widget.activeTrip != null
        ? widget.activeTrip!.totalDays
        : ref.read(pendingTripProvider).totalDays;
    final dayCount = totalDays.clamp(3, 100);
    _days = List.generate(dayCount, (i) => i);

    // Initial validation for default selected day
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateSelectedDay(_selectedDay);
    });
  }

  bool get _canConfirm => _selectedTimeSlot != null;

  String get _effectiveDestId =>
      widget.activeTrip?.destinationId ?? widget.itemData.destinationId;
  String get _effectiveDestName =>
      widget.activeTrip?.destinationName ?? widget.itemData.destinationName;

  void _selectDay(int dayIndex) {
    HapticFeedback.selectionClick();
    setState(() => _selectedDay = dayIndex);
    _validateSelectedDay(dayIndex);
  }

  void _validateSelectedDay(int dayIndex) {
    final activities = ref.read(pendingTripProvider).activitiesByDay;
    final existingActivities = activities.values
        .expand((list) => list)
        .toList();

    final result = _validationService.validateActivityAddition(
      existingActivities: existingActivities,
      targetDayIndex: dayIndex,
      activityDestinationId: _effectiveDestId,
      activityDestinationName: _effectiveDestName,
    );

    // Get existing destination name for display
    String? existingDestName;
    if (result.hasWarning) {
      final dayActivities = existingActivities
          .where((a) => a.dayIndex == dayIndex)
          .toList();
      if (dayActivities.isNotEmpty) {
        existingDestName = dayActivities.first.destinationName;
      }
    }

    setState(() {
      _validationResult = result;
      _existingDestinationName = existingDestName;
    });
  }

  void _selectTimeSlot(TimeSlot slot) {
    HapticFeedback.selectionClick();
    setState(() => _selectedTimeSlot = slot);
  }

  void _addNewDay() {
    HapticFeedback.lightImpact();
    ref.read(pendingTripProvider.notifier).addNewDay();
    setState(() {
      _days.add(_days.length);
      _selectedDay = _days.length - 1;
    });
    _validateSelectedDay(_selectedDay);
    _dayPillsKey.currentState?.scrollToLast();
  }

  void _confirmSelection({bool useSuggestion = false}) async {
    if (!_canConfirm) return;

    HapticFeedback.lightImpact();

    final targetDay =
        useSuggestion && _validationResult?.suggestedDayIndex != null
        ? _validationResult!.suggestedDayIndex!
        : _selectedDay;

    final selection = DayPickerSelection(
      dayIndex: targetDay,
      timeSlot: _selectedTimeSlot!,
      itemData: widget.itemData,
    );

    final pendingActivity = PendingActivity.fromSelection(selection);
    ref
        .read(pendingTripProvider.notifier)
        .addActivity(
          pendingActivity,
          destinationId: _effectiveDestId,
          destinationName: _effectiveDestName,
        );

    final isAnonymous = ref.read(isAnonymousProvider);
    debugPrint('🔵 [DayPicker] isAnonymous: $isAnonymous');

    if (isAnonymous) {
      await showSignInPrompt(
        context: context,
        onSignInSuccess: () {
          if (mounted) _saveTripAndClose(selection);
        },
        onDismiss: () {
          _showPendingFeedback(targetDay);
          if (mounted) Navigator.of(context).pop(selection);
        },
      );
    } else {
      await _saveTripAndClose(selection);
    }
  }

  Future<void> _saveTripAndClose(DayPickerSelection selection) async {
    final success = await ref
        .read(tripSaveProvider.notifier)
        .saveCurrentTrip(
          destinationId: _effectiveDestId,
          destinationName: _effectiveDestName,
        );

    if (success) {
      final saveState = ref.read(tripSaveProvider);
      if (saveState is TripSaveSuccess) {
        TripFeedbackHelper.showSuccess(
          context,
          itemName: widget.itemData.name,
          isNewTrip: saveState.isNewTrip,
        );
      }
      widget.onConfirm?.call(selection);
      if (mounted) Navigator.of(context).pop(selection);
    } else {
      final saveState = ref.read(tripSaveProvider);
      if (saveState is TripSaveDuplicate) {
        // Show confirmation dialog instead of just a snackbar
        if (!mounted) return;
        final addAnyway = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Text('⚠️', style: TextStyle(fontSize: 24)),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Địa điểm đã có',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            content: Text(
              '${saveState.locationName} đã có trong '
              'Ngày ${saveState.dayNumber} - ${saveState.timeSlotLabel}.\n\n'
              'Bạn có muốn thêm lần nữa không?',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Huỷ'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                ),
                child: const Text('Thêm lần nữa'),
              ),
            ],
          ),
        );

        if (addAnyway == true && mounted) {
          // Re-save with forceSave to bypass duplicate check
          final forceSuccess = await ref
              .read(tripSaveProvider.notifier)
              .saveCurrentTrip(
                destinationId: _effectiveDestId,
                destinationName: _effectiveDestName,
                forceSave: true,
              );
          if (forceSuccess && mounted) {
            final forceState = ref.read(tripSaveProvider);
            if (forceState is TripSaveSuccess) {
              TripFeedbackHelper.showSuccess(
                context,
                itemName: widget.itemData.name,
                isNewTrip: forceState.isNewTrip,
              );
            }
            widget.onConfirm?.call(selection);
            Navigator.of(context).pop(selection);
          }
        } else {
          // User cancelled — reset save state so next add works
          ref.read(tripSaveProvider.notifier).reset();
        }
      } else if (saveState is TripSaveError) {
        TripFeedbackHelper.showError(context, saveState.message);
        widget.onConfirm?.call(selection);
        if (mounted) Navigator.of(context).pop(selection);
      }
    }
  }

  void _showPendingFeedback(int dayIndex) {
    TripFeedbackHelper.showPending(
      context,
      itemName: widget.itemData.name,
      dayNumber: dayIndex + 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHandle(),
          const SizedBox(height: 16),
          _buildTitle(),
          const SizedBox(height: 8),
          _buildDestinationInfo(),
          const SizedBox(height: 16),
          DayPickerItemPreview(itemData: widget.itemData),
          const SizedBox(height: 20),
          DayPillsList(
            key: _dayPillsKey,
            days: _days,
            selectedDay: _selectedDay,
            onDaySelected: _selectDay,
            onAddNewDay: _addNewDay,
          ),
          _buildWarningBanner(),
          const SizedBox(height: 16),
          TimeSlotSelector(
            selectedTimeSlot: _selectedTimeSlot,
            onTimeSlotSelected: _selectTimeSlot,
          ),
          const SizedBox(height: 20),
          DayPickerActionButtons(
            canConfirm: _canConfirm,
            selectedDayIndex: _selectedDay,
            validationResult: _validationResult,
            onConfirm: () => _confirmSelection(useSuggestion: false),
            onAcceptSuggestion: () => _confirmSelection(useSuggestion: true),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final title = widget.activeTrip != null
        ? 'Thêm vào: ${widget.activeTrip!.name}'
        : 'Thêm vào chuyến đi';
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildDestinationInfo() {
    return Text(
      '📍 Địa điểm thuộc: $_effectiveDestName',
      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
    );
  }

  Widget _buildWarningBanner() {
    if (_validationResult == null || !_validationResult!.hasWarning) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: ScheduleWarningBanner(
          validationResult: _validationResult!,
          selectedDayNumber: _selectedDay + 1,
          existingDestinationName: _existingDestinationName ?? '',
        ),
      ),
    );
  }
}
