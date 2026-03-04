import 'package:flutter/foundation.dart';

/// Result of trip schedule validation.
///
/// Contains information about destination conflicts and suggestions
/// for optimal day placement.
@immutable
class ScheduleValidationResult {
  /// Whether the activity can be added (always true for soft warnings).
  final bool isValid;

  /// Type of warning, if any.
  final ScheduleWarningType warningType;

  /// Human-readable warning message for display.
  final String? warningMessage;

  /// Suggested day index (0-based) for optimal placement.
  final int? suggestedDayIndex;

  /// Distance in kilometers between destinations.
  final double? distanceKm;

  /// Estimated travel time in minutes between destinations.
  final int? travelTimeMin;

  const ScheduleValidationResult({
    required this.isValid,
    required this.warningType,
    this.warningMessage,
    this.suggestedDayIndex,
    this.distanceKm,
    this.travelTimeMin,
  });

  /// Factory for a valid result with no warnings.
  factory ScheduleValidationResult.valid() {
    return const ScheduleValidationResult(
      isValid: true,
      warningType: ScheduleWarningType.none,
    );
  }

  /// Factory for adjacent destination warning (<50km).
  factory ScheduleValidationResult.adjacentWarning({
    required String message,
    required double distanceKm,
    required int travelTimeMin,
    int? suggestedDayIndex,
  }) {
    return ScheduleValidationResult(
      isValid: true,
      warningType: ScheduleWarningType.adjacentDestination,
      warningMessage: message,
      distanceKm: distanceKm,
      travelTimeMin: travelTimeMin,
      suggestedDayIndex: suggestedDayIndex,
    );
  }

  /// Factory for different destination warning (50-200km).
  factory ScheduleValidationResult.differentWarning({
    required String message,
    required double distanceKm,
    required int travelTimeMin,
    int? suggestedDayIndex,
  }) {
    return ScheduleValidationResult(
      isValid: true,
      warningType: ScheduleWarningType.differentDestination,
      warningMessage: message,
      distanceKm: distanceKm,
      travelTimeMin: travelTimeMin,
      suggestedDayIndex: suggestedDayIndex,
    );
  }

  /// Factory for distant destination warning (>200km).
  factory ScheduleValidationResult.distantWarning({
    required String message,
    required double distanceKm,
    required int travelTimeMin,
    int? suggestedDayIndex,
  }) {
    return ScheduleValidationResult(
      isValid: true,
      warningType: ScheduleWarningType.distantDestination,
      warningMessage: message,
      distanceKm: distanceKm,
      travelTimeMin: travelTimeMin,
      suggestedDayIndex: suggestedDayIndex,
    );
  }

  /// Whether there is any warning to display.
  bool get hasWarning => warningType != ScheduleWarningType.none;

  @override
  String toString() {
    return 'ScheduleValidationResult('
        'isValid: $isValid, '
        'warningType: ${warningType.name}, '
        'distanceKm: $distanceKm, '
        'travelTimeMin: $travelTimeMin'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleValidationResult &&
        other.isValid == isValid &&
        other.warningType == warningType &&
        other.warningMessage == warningMessage &&
        other.suggestedDayIndex == suggestedDayIndex &&
        other.distanceKm == distanceKm &&
        other.travelTimeMin == travelTimeMin;
  }

  @override
  int get hashCode {
    return Object.hash(
      isValid,
      warningType,
      warningMessage,
      suggestedDayIndex,
      distanceKm,
      travelTimeMin,
    );
  }
}

/// Types of schedule warnings based on destination distance.
enum ScheduleWarningType {
  /// Same destination or no conflict.
  none,

  /// Adjacent destinations (<50km) - e.g., Đà Nẵng + Hội An.
  adjacentDestination,

  /// Different destinations (50-200km) - e.g., Đà Nẵng + Huế.
  differentDestination,

  /// Distant destinations (>200km) - e.g., Hà Nội + Phú Quốc.
  distantDestination,
}
