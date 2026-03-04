import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/activity.dart';
import 'package:tour_vn/features/trip/domain/entities/time_slot.dart';
import 'package:tour_vn/features/trip/domain/entities/pending_activity.dart';

void main() {
  group('Activity', () {
    test('should create activity with required fields', () {
      const activity = Activity(
        id: 'act-1',
        locationId: 'loc-1',
        locationName: 'Test Location',
        timeSlot: 'morning',
        sortOrder: 0,
      );

      expect(activity.id, 'act-1');
      expect(activity.locationId, 'loc-1');
      expect(activity.locationName, 'Test Location');
      expect(activity.timeSlot, 'morning');
      expect(activity.sortOrder, 0);
      expect(activity.emoji, isNull);
      expect(activity.imageUrl, isNull);
      expect(activity.estimatedDuration, isNull);
    });

    test('should serialize to map correctly', () {
      const activity = Activity(
        id: 'act-1',
        locationId: 'loc-1',
        locationName: 'Test Location',
        emoji: '🍜',
        imageUrl: 'https://example.com/image.jpg',
        timeSlot: 'afternoon',
        sortOrder: 2,
        estimatedDuration: '1h30m',
      );

      final map = activity.toMap();

      expect(map['id'], 'act-1');
      expect(map['locationId'], 'loc-1');
      expect(map['locationName'], 'Test Location');
      expect(map['emoji'], '🍜');
      expect(map['imageUrl'], 'https://example.com/image.jpg');
      expect(map['timeSlot'], 'afternoon');
      expect(map['sortOrder'], 2);
      expect(map['estimatedDuration'], '1h30m');
    });

    test('should deserialize from map correctly', () {
      final map = {
        'id': 'act-1',
        'locationId': 'loc-1',
        'locationName': 'Test Location',
        'emoji': '🏔️',
        'imageUrl': null,
        'timeSlot': 'evening',
        'sortOrder': 1,
        'estimatedDuration': '2h',
      };

      final activity = Activity.fromMap(map);

      expect(activity.id, 'act-1');
      expect(activity.locationName, 'Test Location');
      expect(activity.emoji, '🏔️');
      expect(activity.timeSlot, 'evening');
      expect(activity.estimatedDuration, '2h');
    });

    test('should create from PendingActivity', () {
      final pending = PendingActivity(
        id: 'pending-1',
        dayIndex: 0,
        timeSlot: TimeSlot.morning,
        locationId: 'loc-1',
        locationName: 'Test Location',
        emoji: '🍜',
        imageUrl: 'https://example.com/image.jpg',
        estimatedDuration: '30m',
        destinationId: 'da-lat',
        destinationName: 'Đà Lạt',
        addedAt: DateTime.now(),
      );

      final activity = Activity.fromPendingActivity(pending, 3);

      expect(activity.id, 'pending-1');
      expect(activity.locationId, 'loc-1');
      expect(activity.locationName, 'Test Location');
      expect(activity.emoji, '🍜');
      expect(activity.timeSlot, 'morning');
      expect(activity.sortOrder, 3);
      expect(activity.estimatedDuration, '30m');
      expect(activity.destinationId, 'da-lat');
      expect(activity.destinationName, 'Đà Lạt');
    });

    test('should support copyWith', () {
      const original = Activity(
        id: 'act-1',
        locationId: 'loc-1',
        locationName: 'Original',
        timeSlot: 'morning',
        sortOrder: 0,
      );

      final copied = original.copyWith(locationName: 'Updated', sortOrder: 5);

      expect(copied.id, 'act-1'); // unchanged
      expect(copied.locationName, 'Updated');
      expect(copied.sortOrder, 5);
    });

    test('should have correct equality', () {
      const a1 = Activity(
        id: 'act-1',
        locationId: 'loc-1',
        locationName: 'Test',
        timeSlot: 'morning',
        sortOrder: 0,
      );

      const a2 = Activity(
        id: 'act-1',
        locationId: 'loc-1',
        locationName: 'Different Name',
        timeSlot: 'morning',
        sortOrder: 1,
      );

      const a3 = Activity(
        id: 'act-2',
        locationId: 'loc-1',
        locationName: 'Test',
        timeSlot: 'morning',
        sortOrder: 0,
      );

      expect(a1, equals(a2)); // Same id, locationId, timeSlot
      expect(a1, isNot(equals(a3))); // Different id
    });
  });
}
