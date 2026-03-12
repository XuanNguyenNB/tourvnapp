import 'package:cloud_firestore/cloud_firestore.dart';

/// Entity representing a comment on a review.
///
/// Stored as subcollection: reviews/{reviewId}/comments/{commentId}
///
/// Moderation flow:
/// 1. User posts comment → ProfanityFilterService checks text
/// 2. Clean text → status = 'approved' (visible immediately)
/// 3. Flagged text → status = 'flagged' (hidden, pending admin review)
/// 4. Admin approves → status = 'approved' / rejects → status = 'rejected'
class Comment {
  /// Unique identifier
  final String id;

  /// ID of the review this comment belongs to
  final String reviewId;

  /// ID of the user who wrote the comment
  final String userId;

  /// Display name of the author
  final String userName;

  /// Avatar URL of the author (nullable)
  final String? userAvatar;

  /// Comment text content
  final String text;

  /// When the comment was created
  final DateTime createdAt;

  /// Moderation status: 'approved', 'flagged', 'rejected'
  final String status;

  /// Reason for flagging (matched profanity words), null if approved
  final String? flagReason;

  /// When the comment was moderated by admin
  final DateTime? moderatedAt;

  /// UID of the admin who moderated this comment
  final String? moderatedBy;

  const Comment({
    required this.id,
    required this.reviewId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.text,
    required this.createdAt,
    this.status = 'approved',
    this.flagReason,
    this.moderatedAt,
    this.moderatedBy,
  });

  /// Create from Firestore document snapshot
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      reviewId: json['reviewId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      text: json['text'] as String,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String? ?? 'approved',
      flagReason: json['flagReason'] as String?,
      moderatedAt: json['moderatedAt'] is Timestamp
          ? (json['moderatedAt'] as Timestamp).toDate()
          : json['moderatedAt'] != null
              ? DateTime.parse(json['moderatedAt'] as String)
              : null,
      moderatedBy: json['moderatedBy'] as String?,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewId': reviewId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'flagReason': flagReason,
      'moderatedAt':
          moderatedAt != null ? Timestamp.fromDate(moderatedAt!) : null,
      'moderatedBy': moderatedBy,
    };
  }

  /// Human-readable relative time (e.g., "5 phút trước", "2 ngày trước")
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7} tuần trước';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30} tháng trước';
    return '${diff.inDays ~/ 365} năm trước';
  }

  /// Whether this comment is visible to regular users
  bool get isVisible => status == 'approved';

  /// Whether this comment is pending moderation
  bool get isFlagged => status == 'flagged';

  /// Creates a copy with modified fields
  Comment copyWith({
    String? id,
    String? reviewId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? text,
    DateTime? createdAt,
    String? status,
    String? flagReason,
    DateTime? moderatedAt,
    String? moderatedBy,
  }) {
    return Comment(
      id: id ?? this.id,
      reviewId: reviewId ?? this.reviewId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      flagReason: flagReason ?? this.flagReason,
      moderatedAt: moderatedAt ?? this.moderatedAt,
      moderatedBy: moderatedBy ?? this.moderatedBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Comment(id: $id, userId: $userId, status: $status)';
}
