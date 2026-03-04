import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Domain entity representing a TourVN user.
/// Can be anonymous or authenticated (Google/Facebook).
///
/// Story 6.3: Added moodPreferences and onboardingCompleted fields
class User {
  final String uid;
  final bool isAnonymous;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  /// User's mood preferences from onboarding (Story 6.3)
  /// Stored as list of mood names: ['healing', 'adventure', etc.]
  final List<String>? moodPreferences;

  /// Whether user has completed onboarding (Story 6.3)
  final bool onboardingCompleted;

  const User({
    required this.uid,
    required this.isAnonymous,
    this.email,
    this.displayName,
    this.photoUrl,
    this.moodPreferences,
    this.onboardingCompleted = false,
  });

  /// Factory constructor from Firebase User
  factory User.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return User(
      uid: firebaseUser.uid,
      isAnonymous: firebaseUser.isAnonymous,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      // moodPreferences and onboardingCompleted need to be loaded from Firestore
      moodPreferences: null,
      onboardingCompleted: false,
    );
  }

  /// Create a copy with updated fields
  User copyWith({
    String? uid,
    bool? isAnonymous,
    String? email,
    String? displayName,
    String? photoUrl,
    List<String>? moodPreferences,
    bool? onboardingCompleted,
  }) {
    return User(
      uid: uid ?? this.uid,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      moodPreferences: moodPreferences ?? this.moodPreferences,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  /// Convert to JSON for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'isAnonymous': isAnonymous,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'moodPreferences': moodPreferences,
      'onboardingCompleted': onboardingCompleted,
    };
  }

  /// Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as String,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      moodPreferences: (json['moodPreferences'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    );
  }

  /// Check if user has selected any mood preferences
  bool get hasMoodPreferences =>
      moodPreferences != null && moodPreferences!.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'User(uid: $uid, isAnonymous: $isAnonymous, '
        'email: $email, onboardingCompleted: $onboardingCompleted)';
  }
}
