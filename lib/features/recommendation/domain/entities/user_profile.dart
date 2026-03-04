import 'package:cloud_firestore/cloud_firestore.dart';

/// Travel pace preference.
enum TravelPace {
  relaxed,
  normal,
  packed;

  String get label {
    switch (this) {
      case TravelPace.relaxed:
        return 'Thư giãn';
      case TravelPace.normal:
        return 'Bình thường';
      case TravelPace.packed:
        return 'Dày đặc';
    }
  }

  /// Suggested number of locations per day based on pace.
  int get locationsPerDay {
    switch (this) {
      case TravelPace.relaxed:
        return 3;
      case TravelPace.normal:
        return 5;
      case TravelPace.packed:
        return 7;
    }
  }
}

/// Budget level preference.
enum BudgetLevel {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case BudgetLevel.low:
        return 'Tiết kiệm';
      case BudgetLevel.medium:
        return 'Trung bình';
      case BudgetLevel.high:
        return 'Cao cấp';
    }
  }
}

/// Group type preference.
enum GroupType {
  solo,
  couple,
  family,
  friends;

  String get label {
    switch (this) {
      case GroupType.solo:
        return 'Một mình';
      case GroupType.couple:
        return 'Cặp đôi';
      case GroupType.family:
        return 'Gia đình';
      case GroupType.friends:
        return 'Bạn bè';
    }
  }

  String get emoji {
    switch (this) {
      case GroupType.solo:
        return '🧑';
      case GroupType.couple:
        return '💑';
      case GroupType.family:
        return '👨‍👩‍👧';
      case GroupType.friends:
        return '👫';
    }
  }
}

/// User profile for personalized recommendations.
///
/// Stored at `users/{uid}/profile` in Firestore.
/// Captures user preferences for travel style, budget, and interests.
class UserProfile {
  /// Firebase Auth UID.
  final String userId;

  /// Preferred category IDs (e.g., 'food', 'nature', 'nightlife').
  final List<String> preferredCategoryIds;

  /// Preferred tags (e.g., 'romantic', 'adventure', 'hidden-gem').
  final List<String> preferredTags;

  /// Preferred destination IDs (e.g., 'ninh-binh', 'da-lat').
  final List<String> preferredDestinationIds;

  /// Preferred travel pace.
  final TravelPace travelPace;

  /// Budget level.
  final BudgetLevel budgetLevel;

  /// Group type.
  final GroupType groupType;

  /// Last time the profile was updated.
  final DateTime updatedAt;

  const UserProfile({
    required this.userId,
    this.preferredCategoryIds = const [],
    this.preferredTags = const [],
    this.preferredDestinationIds = const [],
    this.travelPace = TravelPace.normal,
    this.budgetLevel = BudgetLevel.medium,
    this.groupType = GroupType.solo,
    required this.updatedAt,
  });

  /// Whether this profile has any preferences set.
  bool get hasPreferences =>
      preferredCategoryIds.isNotEmpty ||
      preferredTags.isNotEmpty ||
      preferredDestinationIds.isNotEmpty;

  /// Create from Firestore document.
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] as String,
      preferredCategoryIds:
          (map['preferredCategoryIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      preferredTags:
          (map['preferredTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      preferredDestinationIds:
          (map['preferredDestinationIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      travelPace: TravelPace.values.firstWhere(
        (e) => e.name == (map['travelPace'] as String?),
        orElse: () => TravelPace.normal,
      ),
      budgetLevel: BudgetLevel.values.firstWhere(
        (e) => e.name == (map['budgetLevel'] as String?),
        orElse: () => BudgetLevel.medium,
      ),
      groupType: GroupType.values.firstWhere(
        (e) => e.name == (map['groupType'] as String?),
        orElse: () => GroupType.solo,
      ),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Serialize to Firestore map.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'preferredCategoryIds': preferredCategoryIds,
      'preferredTags': preferredTags,
      'preferredDestinationIds': preferredDestinationIds,
      'travelPace': travelPace.name,
      'budgetLevel': budgetLevel.name,
      'groupType': groupType.name,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserProfile copyWith({
    String? userId,
    List<String>? preferredCategoryIds,
    List<String>? preferredTags,
    List<String>? preferredDestinationIds,
    TravelPace? travelPace,
    BudgetLevel? budgetLevel,
    GroupType? groupType,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      preferredCategoryIds: preferredCategoryIds ?? this.preferredCategoryIds,
      preferredTags: preferredTags ?? this.preferredTags,
      preferredDestinationIds:
          preferredDestinationIds ?? this.preferredDestinationIds,
      travelPace: travelPace ?? this.travelPace,
      budgetLevel: budgetLevel ?? this.budgetLevel,
      groupType: groupType ?? this.groupType,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'UserProfile(userId: $userId, categories: $preferredCategoryIds, '
      'tags: $preferredTags, pace: ${travelPace.name})';
}
