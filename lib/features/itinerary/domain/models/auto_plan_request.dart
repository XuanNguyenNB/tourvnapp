import 'package:flutter/foundation.dart';

import '../../../recommendation/domain/entities/user_profile.dart';

/// Input options for "AI Lập Kế Hoạch Tự Động" (Cách A: fixed time blocks).
///
/// - destinationId: bắt buộc (để fetch locations bằng locationsForDestinationProvider)
/// - preferredCategoryIds / preferredTags: sở thích explicit từ user (override profile nếu có)
/// - pace/budget/groupType: feed trực tiếp vào scoring + constraints
@immutable
class AutoPlanRequest {
  final String destinationId;
  final String destinationName;

  /// Trip length.
  final int numberOfDays;

  /// User explicit preferences (optional but usually provided by wizard).
  final List<String> preferredCategoryIds;
  final List<String> preferredTags;

  /// Planning style.
  final TravelPace pace;
  final BudgetLevel budgetLevel;
  final GroupType groupType;

  /// Use implicit behavior signals (events) if available.
  /// If false: chỉ dùng explicit preferences + quality/popularity.
  final bool useBehaviorSignals;

  /// Apply MMR diversity in RecommendationService.
  final bool diversify;

  /// Optional GPS for proximity scoring in RecommendationService.
  final double? userLat;
  final double? userLng;

  /// Mặc định trip N ngày (N-1) đêm → ngày cuối về sớm.
  final bool endEarlyOnLastDay;

  const AutoPlanRequest({
    required this.destinationId,
    required this.destinationName,
    required this.numberOfDays,
    this.preferredCategoryIds = const [],
    this.preferredTags = const [],
    this.pace = TravelPace.normal,
    this.budgetLevel = BudgetLevel.medium,
    this.groupType = GroupType.solo,
    this.useBehaviorSignals = true,
    this.diversify = true,
    this.userLat,
    this.userLng,
    this.endEarlyOnLastDay = true,
  }) : assert(numberOfDays > 0 && numberOfDays <= 30);

  AutoPlanRequest copyWith({
    String? destinationId,
    String? destinationName,
    int? numberOfDays,
    List<String>? preferredCategoryIds,
    List<String>? preferredTags,
    TravelPace? pace,
    BudgetLevel? budgetLevel,
    GroupType? groupType,
    bool? useBehaviorSignals,
    bool? diversify,
    double? userLat,
    double? userLng,
    bool? endEarlyOnLastDay,
  }) {
    return AutoPlanRequest(
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      preferredCategoryIds: preferredCategoryIds ?? this.preferredCategoryIds,
      preferredTags: preferredTags ?? this.preferredTags,
      pace: pace ?? this.pace,
      budgetLevel: budgetLevel ?? this.budgetLevel,
      groupType: groupType ?? this.groupType,
      useBehaviorSignals: useBehaviorSignals ?? this.useBehaviorSignals,
      diversify: diversify ?? this.diversify,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
      endEarlyOnLastDay: endEarlyOnLastDay ?? this.endEarlyOnLastDay,
    );
  }

  @override
  String toString() =>
      'AutoPlanRequest(dest: $destinationId, days: $numberOfDays, '
      'pace: ${pace.name}, endEarlyOnLastDay: $endEarlyOnLastDay)';
}
