import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/trip_day.dart';
import 'package:tour_vn/features/trip/domain/entities/activity.dart';

void main() {
  group('TripDay', () {
    test('should create empty day', () {
      const day = TripDay(dayNumber: 1);

      expect(day.dayNumber, 1);
      expect(day.activities, isEmpty);
      expect(day.isEmpty, true);
      expect(day.isNotEmpty, false);
      expect(day.activityCount, 0);
      expect(day.label, 'Ngày 1');
    });

    test('should create day with activities', () {
      const activity = Activity(
        id: 'act-1',
        locationId: 'loc-1',
        locationName: 'Test Location',
        timeSlot: 'morning',
        sortOrder: 0,
      );

      final day = TripDay(dayNumber: 2, activities: [activity]);

      expect(day.dayNumber, 2);
      expect(day.activityCount, 1);
      expect(day.isEmpty, false);
      expect(day.isNotEmpty, true);
      expect(day.label, 'Ngày 2');
    });

    test('should serialize to map correctly', () {
      const activity = Activity(
        id: 'act-1',
        locationId: 'loc-1',
        locationName: 'Test',
        timeSlot: 'morning',
        sortOrder: 0,
      );

      final day = TripDay(dayNumber: 1, activities: [activity]);
      final map = day.toMap();

      expect(map['dayNumber'], 1);
      expect(map['activities'], isList);
      expect((map['activities'] as List).length, 1);
    });

    test('should deserialize from map correctly', () {
      final map = {
        'dayNumber': 3,
        'activities': [
          {
            'id': 'act-1',
            'locationId': 'loc-1',
            'locationName': 'Test',
            'emoji': null,
            'imageUrl': null,
            'timeSlot': 'noon',
            'sortOrder': 0,
          },
        ],
      };

      final day = TripDay.fromMap(map);

      expect(day.dayNumber, 3);
      expect(day.activityCount, 1);
      expect(day.activities.first.timeSlot, 'noon');
    });

    test('should add activity immutably', () {
      const original = TripDay(dayNumber: 1);
      const activity = Activity(
        id: 'act-1',
        locationId: 'loc-1',
        locationName: 'Test',
        timeSlot: 'morning',
        sortOrder: 0,
      );

      final updated = original.addActivity(activity);

      expect(original.activityCount, 0); // Original unchanged
      expect(updated.activityCount, 1);
      expect(updated.activities.first.id, 'act-1');
    });

    test('should remove activity immutably', () {
      const activity = Activity(
        id: 'act-1',
        locationId: 'loc-1',
        locationName: 'Test',
        timeSlot: 'morning',
        sortOrder: 0,
      );

      final original = TripDay(dayNumber: 1, activities: [activity]);
      final updated = original.removeActivity('act-1');

      expect(original.activityCount, 1); // Original unchanged
      expect(updated.activityCount, 0);
    });

    test('should have correct equality based on dayNumber', () {
      const day1 = TripDay(dayNumber: 1);
      const day2 = TripDay(dayNumber: 1);
      const day3 = TripDay(dayNumber: 2);

      expect(day1, equals(day2));
      expect(day1, isNot(equals(day3)));
    });
  });
}
