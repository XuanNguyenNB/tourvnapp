import 'package:flutter_test/flutter_test.dart';

import 'package:tour_vn/features/trip/domain/entities/pending_activity.dart';
import 'package:tour_vn/features/trip/domain/entities/time_slot.dart';
import 'package:tour_vn/features/trip/domain/entities/day_picker_selection.dart';
import 'package:tour_vn/features/trip/presentation/widgets/add_to_trip_gesture_wrapper.dart';

void main() {
  group('PendingActivity', () {
    test('should create with required fields', () {
      final activity = PendingActivity(
        id: 'test-id',
        dayIndex: 0,
        timeSlot: TimeSlot.morning,
        locationId: 'loc-123',
        locationName: 'Test Location',
        destinationId: 'da-lat',
        destinationName: 'Đà Lạt',
        addedAt: DateTime(2026, 1, 27),
      );

      expect(activity.id, equals('test-id'));
      expect(activity.dayIndex, equals(0));
      expect(activity.timeSlot, equals(TimeSlot.morning));
      expect(activity.locationId, equals('loc-123'));
      expect(activity.locationName, equals('Test Location'));
      expect(activity.destinationId, equals('da-lat'));
      expect(activity.destinationName, equals('Đà Lạt'));
      expect(activity.emoji, isNull);
      expect(activity.imageUrl, isNull);
    });

    test('should create with optional fields', () {
      final activity = PendingActivity(
        id: 'test-id',
        dayIndex: 1,
        timeSlot: TimeSlot.evening,
        locationId: 'loc-456',
        locationName: 'Coffee Shop',
        destinationId: 'da-nang',
        destinationName: 'Đà Nẵng',
        emoji: '☕',
        imageUrl: 'https://example.com/image.jpg',
        addedAt: DateTime(2026, 1, 27),
      );

      expect(activity.emoji, equals('☕'));
      expect(activity.imageUrl, equals('https://example.com/image.jpg'));
    });

    test('dayLabel should return 1-based day number', () {
      final activity0 = _createActivity(dayIndex: 0);
      final activity1 = _createActivity(dayIndex: 1);
      final activity2 = _createActivity(dayIndex: 2);

      expect(activity0.dayLabel, equals('Ngày 1'));
      expect(activity1.dayLabel, equals('Ngày 2'));
      expect(activity2.dayLabel, equals('Ngày 3'));
    });

    test('timeSlotLabel should return Vietnamese time slot name', () {
      expect(
        _createActivity(timeSlot: TimeSlot.morning).timeSlotLabel,
        equals('Sáng'),
      );
      expect(
        _createActivity(timeSlot: TimeSlot.noon).timeSlotLabel,
        equals('Trưa'),
      );
      expect(
        _createActivity(timeSlot: TimeSlot.afternoon).timeSlotLabel,
        equals('Chiều'),
      );
      expect(
        _createActivity(timeSlot: TimeSlot.evening).timeSlotLabel,
        equals('Tối'),
      );
    });

    group('fromSelection', () {
      test('should create from DayPickerSelection', () {
        final itemData = TripItemData(
          id: 'item-123',
          name: 'Da Lat Coffee',
          type: 'location',
          emoji: '☕',
          imageUrl: 'https://example.com/coffee.jpg',
          destinationId: 'da-lat',
          destinationName: 'Đà Lạt',
        );

        final selection = DayPickerSelection(
          dayIndex: 1,
          timeSlot: TimeSlot.afternoon,
          itemData: itemData,
        );

        final activity = PendingActivity.fromSelection(selection);

        expect(activity.id, isNotEmpty);
        expect(activity.dayIndex, equals(1));
        expect(activity.timeSlot, equals(TimeSlot.afternoon));
        expect(activity.locationId, equals('item-123'));
        expect(activity.locationName, equals('Da Lat Coffee'));
        expect(activity.emoji, equals('☕'));
        expect(activity.imageUrl, equals('https://example.com/coffee.jpg'));
        expect(activity.destinationId, equals('da-lat'));
        expect(activity.destinationName, equals('Đà Lạt'));
        expect(activity.addedAt, isNotNull);
      });

      test('should generate unique IDs for each activity', () {
        final itemData = TripItemData(
          id: 'item-123',
          name: 'Test Location',
          type: 'location',
          destinationId: 'test-dest',
          destinationName: 'Test Destination',
        );

        final selection = DayPickerSelection(
          dayIndex: 0,
          timeSlot: TimeSlot.morning,
          itemData: itemData,
        );

        final activity1 = PendingActivity.fromSelection(selection);
        final activity2 = PendingActivity.fromSelection(selection);

        expect(activity1.id, isNot(equals(activity2.id)));
      });
    });

    group('copyWith', () {
      test('should return same values when no overrides', () {
        final original = _createActivity();
        final copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.dayIndex, equals(original.dayIndex));
        expect(copy.timeSlot, equals(original.timeSlot));
        expect(copy.locationName, equals(original.locationName));
      });

      test('should override specified values', () {
        final original = _createActivity(dayIndex: 0);
        final copy = original.copyWith(dayIndex: 2, timeSlot: TimeSlot.evening);

        expect(copy.dayIndex, equals(2));
        expect(copy.timeSlot, equals(TimeSlot.evening));
        expect(copy.id, equals(original.id)); // unchanged
      });
    });

    group('equality', () {
      test('should be equal if same id, dayIndex, timeSlot, locationId', () {
        final activity1 = _createActivity();
        final activity2 = _createActivity();

        expect(activity1, equals(activity2));
        expect(activity1.hashCode, equals(activity2.hashCode));
      });

      test('should not be equal if different id', () {
        final activity1 = _createActivity(id: 'id-1');
        final activity2 = _createActivity(id: 'id-2');

        expect(activity1, isNot(equals(activity2)));
      });
    });

    test('toString should return readable representation', () {
      final activity = _createActivity(
        id: 'act-123',
        dayIndex: 1,
        timeSlot: TimeSlot.morning,
        name: 'Coffee Shop',
      );

      final str = activity.toString();

      expect(str, contains('act-123'));
      expect(str, contains('Ngày 2'));
      expect(str, contains('Sáng'));
      expect(str, contains('Coffee Shop'));
    });
  });
}

/// Helper to create test PendingActivity
PendingActivity _createActivity({
  String id = 'test-id',
  int dayIndex = 0,
  TimeSlot timeSlot = TimeSlot.morning,
  String locationId = 'loc-123',
  String name = 'Test Location',
  String? emoji,
  String? imageUrl,
  String destinationId = 'test-destination',
  String destinationName = 'Test Destination',
}) {
  return PendingActivity(
    id: id,
    dayIndex: dayIndex,
    timeSlot: timeSlot,
    locationId: locationId,
    locationName: name,
    emoji: emoji,
    imageUrl: imageUrl,
    destinationId: destinationId,
    destinationName: destinationName,
    addedAt: DateTime(2026, 1, 27),
  );
}
