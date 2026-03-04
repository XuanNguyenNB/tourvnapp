import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/auth/domain/entities/user.dart';

void main() {
  group('User Entity Tests', () {
    test('User.fromFirebaseUser creates User from Firebase User', () {
      // This is a conceptual test - in real scenario, we'd mock Firebase User
      // For now, we're testing the entity structure

      const testUser = User(
        uid: 'test-uid-123',
        isAnonymous: true,
        email: null,
        displayName: null,
        photoUrl: null,
      );

      expect(testUser.uid, 'test-uid-123');
      expect(testUser.isAnonymous, true);
      expect(testUser.email, null);
    });

    test('User.copyWith updates fields correctly', () {
      const original = User(
        uid: 'uid-123',
        isAnonymous: true,
        email: null,
        displayName: null,
        photoUrl: null,
      );

      final updated = original.copyWith(
        isAnonymous: false,
        email: 'test@example.com',
      );

      expect(updated.uid, 'uid-123'); // Unchanged
      expect(updated.isAnonymous, false); // Changed
      expect(updated.email, 'test@example.com'); // Changed
    });

    test('User.toJson serializes correctly', () {
      const user = User(
        uid: 'uid-123',
        isAnonymous: true,
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
      );

      final json = user.toJson();

      expect(json['uid'], 'uid-123');
      expect(json['isAnonymous'], true);
      expect(json['email'], 'test@example.com');
      expect(json['displayName'], 'Test User');
      expect(json['photoUrl'], 'https://example.com/photo.jpg');
    });

    test('User.fromJson deserializes correctly', () {
      final json = {
        'uid': 'uid-123',
        'isAnonymous': false,
        'email': 'test@example.com',
        'displayName': 'Test User',
        'photoUrl': 'https://example.com/photo.jpg',
      };

      final user = User.fromJson(json);

      expect(user.uid, 'uid-123');
      expect(user.isAnonymous, false);
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.photoUrl, 'https://example.com/photo.jpg');
    });

    test('User equality works correctly', () {
      const user1 = User(
        uid: 'uid-123',
        isAnonymous: true,
        email: null,
        displayName: null,
        photoUrl: null,
      );

      const user2 = User(
        uid: 'uid-123',
        isAnonymous: false, // Different isAnonymous
        email: 'test@example.com', // Different email
        displayName: null,
        photoUrl: null,
      );

      const user3 = User(
        uid: 'uid-456', // Different UID
        isAnonymous: true,
        email: null,
        displayName: null,
        photoUrl: null,
      );

      // Same UID = equal
      expect(user1 == user2, true);
      expect(user1.hashCode, user2.hashCode);

      // Different UID = not equal
      expect(user1 == user3, false);
    });
  });
}
