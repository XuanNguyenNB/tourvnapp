import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/schedule_validation_result.dart';

void main() {
  group('ScheduleValidationResult', () {
    test('should create with required fields', () {
      const result = ScheduleValidationResult(
        isValid: true,
        warningType: ScheduleWarningType.none,
      );

      expect(result.isValid, true);
      expect(result.warningType, ScheduleWarningType.none);
      expect(result.warningMessage, isNull);
      expect(result.suggestedDayIndex, isNull);
      expect(result.distanceKm, isNull);
      expect(result.travelTimeMin, isNull);
    });

    test('factory valid should create no-warning result', () {
      final result = ScheduleValidationResult.valid();

      expect(result.isValid, true);
      expect(result.warningType, ScheduleWarningType.none);
      expect(result.hasWarning, false);
    });

    test('factory adjacentWarning should create adjacent result', () {
      final result = ScheduleValidationResult.adjacentWarning(
        message: 'Test message',
        distanceKm: 30,
        travelTimeMin: 45,
        suggestedDayIndex: 1,
      );

      expect(result.isValid, true);
      expect(result.warningType, ScheduleWarningType.adjacentDestination);
      expect(result.warningMessage, 'Test message');
      expect(result.distanceKm, 30);
      expect(result.travelTimeMin, 45);
      expect(result.suggestedDayIndex, 1);
      expect(result.hasWarning, true);
    });

    test('factory differentWarning should create different result', () {
      final result = ScheduleValidationResult.differentWarning(
        message: 'Different message',
        distanceKm: 100,
        travelTimeMin: 180,
      );

      expect(result.isValid, true);
      expect(result.warningType, ScheduleWarningType.differentDestination);
      expect(result.distanceKm, 100);
      expect(result.travelTimeMin, 180);
      expect(result.hasWarning, true);
    });

    test('factory distantWarning should create distant result', () {
      final result = ScheduleValidationResult.distantWarning(
        message: 'Distant message',
        distanceKm: 500,
        travelTimeMin: 90,
      );

      expect(result.isValid, true);
      expect(result.warningType, ScheduleWarningType.distantDestination);
      expect(result.distanceKm, 500);
      expect(result.travelTimeMin, 90);
      expect(result.hasWarning, true);
    });

    test('hasWarning should return false for none type', () {
      final result = ScheduleValidationResult.valid();
      expect(result.hasWarning, false);
    });

    test('hasWarning should return true for any warning type', () {
      final adjacent = ScheduleValidationResult.adjacentWarning(
        message: 'msg',
        distanceKm: 30,
        travelTimeMin: 45,
      );
      final different = ScheduleValidationResult.differentWarning(
        message: 'msg',
        distanceKm: 100,
        travelTimeMin: 180,
      );
      final distant = ScheduleValidationResult.distantWarning(
        message: 'msg',
        distanceKm: 500,
        travelTimeMin: 90,
      );

      expect(adjacent.hasWarning, true);
      expect(different.hasWarning, true);
      expect(distant.hasWarning, true);
    });

    test('equality should work correctly', () {
      const result1 = ScheduleValidationResult(
        isValid: true,
        warningType: ScheduleWarningType.none,
      );
      const result2 = ScheduleValidationResult(
        isValid: true,
        warningType: ScheduleWarningType.none,
      );
      const result3 = ScheduleValidationResult(
        isValid: true,
        warningType: ScheduleWarningType.adjacentDestination,
        distanceKm: 30,
        travelTimeMin: 45,
      );

      expect(result1, equals(result2));
      expect(result1.hashCode, equals(result2.hashCode));
      expect(result1, isNot(equals(result3)));
    });

    test('toString should return readable format', () {
      const result = ScheduleValidationResult(
        isValid: true,
        warningType: ScheduleWarningType.differentDestination,
        distanceKm: 100,
        travelTimeMin: 180,
      );

      final str = result.toString();
      expect(str, contains('isValid: true'));
      expect(str, contains('differentDestination'));
      expect(str, contains('100'));
    });
  });

  group('ScheduleWarningType', () {
    test('should have all expected values', () {
      expect(ScheduleWarningType.values, hasLength(4));
      expect(
        ScheduleWarningType.values,
        containsAll([
          ScheduleWarningType.none,
          ScheduleWarningType.adjacentDestination,
          ScheduleWarningType.differentDestination,
          ScheduleWarningType.distantDestination,
        ]),
      );
    });
  });
}
