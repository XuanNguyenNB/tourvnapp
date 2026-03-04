import 'package:flutter/material.dart';
import 'package:tour_vn/features/trip/domain/entities/schedule_validation_result.dart';

/// A banner widget that displays schedule validation warnings.
///
/// Shows different styling based on warning severity:
/// - Adjacent: Blue info banner
/// - Different: Amber warning banner
/// - Distant: Red strong warning banner
class ScheduleWarningBanner extends StatelessWidget {
  /// The validation result containing warning details.
  final ScheduleValidationResult validationResult;

  /// The day number (1-indexed) that was selected.
  final int selectedDayNumber;

  /// Name of the destination already in the selected day.
  final String existingDestinationName;

  const ScheduleWarningBanner({
    super.key,
    required this.validationResult,
    required this.selectedDayNumber,
    required this.existingDestinationName,
  });

  @override
  Widget build(BuildContext context) {
    if (!validationResult.hasWarning) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: _accentColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          _buildDistanceInfo(),
          if (validationResult.suggestedDayIndex != null) ...[
            const SizedBox(height: 8),
            _buildSuggestion(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(_headerIcon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _headerText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceInfo() {
    final distance = validationResult.distanceKm;
    final travelTime = validationResult.travelTimeMin;

    if (distance == null || travelTime == null) {
      return const SizedBox.shrink();
    }

    final distanceText = _formatDistance(distance);
    final timeText = _formatTravelTime(travelTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📏 Khoảng cách: ~$distanceText',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),
        Text(
          '⏱️ Di chuyển: ~$timeText',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildSuggestion() {
    final suggestedDay = validationResult.suggestedDayIndex! + 1;
    return Text(
      '💡 Gợi ý: Thêm vào Ngày $suggestedDay để tối ưu lịch trình',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        color: _accentColor,
      ),
    );
  }

  String get _headerIcon {
    switch (validationResult.warningType) {
      case ScheduleWarningType.adjacentDestination:
        return 'ℹ️';
      case ScheduleWarningType.differentDestination:
        return '⚠️';
      case ScheduleWarningType.distantDestination:
        return '⚠️';
      case ScheduleWarningType.none:
        return '';
    }
  }

  String get _headerText {
    switch (validationResult.warningType) {
      case ScheduleWarningType.adjacentDestination:
        return 'Ngày $selectedDayNumber có hoạt động ở $existingDestinationName';
      case ScheduleWarningType.differentDestination:
        return 'Ngày $selectedDayNumber đã có hoạt động ở $existingDestinationName';
      case ScheduleWarningType.distantDestination:
        return 'Lịch trình có thể không thực tế';
      case ScheduleWarningType.none:
        return '';
    }
  }

  Color get _backgroundColor {
    switch (validationResult.warningType) {
      case ScheduleWarningType.adjacentDestination:
        return Colors.blue.shade50;
      case ScheduleWarningType.differentDestination:
        return Colors.amber.shade50;
      case ScheduleWarningType.distantDestination:
        return Colors.red.shade50;
      case ScheduleWarningType.none:
        return Colors.transparent;
    }
  }

  Color get _accentColor {
    switch (validationResult.warningType) {
      case ScheduleWarningType.adjacentDestination:
        return Colors.blue.shade600;
      case ScheduleWarningType.differentDestination:
        return Colors.amber.shade700;
      case ScheduleWarningType.distantDestination:
        return Colors.red.shade600;
      case ScheduleWarningType.none:
        return Colors.transparent;
    }
  }

  Color get _textColor {
    switch (validationResult.warningType) {
      case ScheduleWarningType.adjacentDestination:
        return Colors.blue.shade800;
      case ScheduleWarningType.differentDestination:
        return Colors.amber.shade900;
      case ScheduleWarningType.distantDestination:
        return Colors.red.shade800;
      case ScheduleWarningType.none:
        return Colors.black;
    }
  }

  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m';
    }
    return '${km.round()} km';
  }

  String _formatTravelTime(int minutes) {
    if (minutes < 60) {
      return '$minutes phút';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours tiếng';
    }
    return '$hours tiếng $mins phút';
  }
}
