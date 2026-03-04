import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/schedule_validation_result.dart';
import 'package:tour_vn/features/trip/presentation/widgets/schedule_warning_banner.dart';

void main() {
  group('ScheduleWarningBanner', () {
    Widget buildTestWidget({
      required ScheduleValidationResult validationResult,
      int selectedDayNumber = 1,
      String existingDestinationName = 'Đà Nẵng',
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ScheduleWarningBanner(
            validationResult: validationResult,
            selectedDayNumber: selectedDayNumber,
            existingDestinationName: existingDestinationName,
          ),
        ),
      );
    }

    group('No Warning Display', () {
      testWidgets('should not display anything when warningType is none', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(validationResult: ScheduleValidationResult.valid()),
        );

        // Should render empty SizedBox
        expect(find.byType(SizedBox), findsOneWidget);
        expect(find.text('⚠️'), findsNothing);
        expect(find.text('ℹ️'), findsNothing);
      });
    });

    group('Adjacent Destination Warning', () {
      testWidgets('should display info icon and soft message', (tester) async {
        final result = ScheduleValidationResult.adjacentWarning(
          message: 'Hội An cách Đà Nẵng 30 km',
          distanceKm: 30,
          travelTimeMin: 45,
          suggestedDayIndex: 1,
        );

        await tester.pumpWidget(
          buildTestWidget(
            validationResult: result,
            selectedDayNumber: 1,
            existingDestinationName: 'Đà Nẵng',
          ),
        );

        expect(find.text('ℹ️'), findsOneWidget);
        expect(
          find.textContaining('Ngày 1 có hoạt động ở Đà Nẵng'),
          findsOneWidget,
        );
        expect(find.textContaining('📏 Khoảng cách:'), findsOneWidget);
        expect(find.textContaining('⏱️ Di chuyển:'), findsOneWidget);
      });

      testWidgets('should display suggestion when available', (tester) async {
        final result = ScheduleValidationResult.adjacentWarning(
          message: 'Hội An cách Đà Nẵng 30 km',
          distanceKm: 30,
          travelTimeMin: 45,
          suggestedDayIndex: 2,
        );

        await tester.pumpWidget(buildTestWidget(validationResult: result));

        expect(
          find.textContaining('💡 Gợi ý: Thêm vào Ngày 3'),
          findsOneWidget,
        );
      });
    });

    group('Different Destination Warning', () {
      testWidgets('should display warning icon and message', (tester) async {
        final result = ScheduleValidationResult.differentWarning(
          message: 'Huế cách Đà Nẵng 100 km',
          distanceKm: 100,
          travelTimeMin: 180,
          suggestedDayIndex: 1,
        );

        await tester.pumpWidget(
          buildTestWidget(
            validationResult: result,
            selectedDayNumber: 1,
            existingDestinationName: 'Đà Nẵng',
          ),
        );

        expect(find.text('⚠️'), findsOneWidget);
        expect(
          find.textContaining('Ngày 1 đã có hoạt động ở Đà Nẵng'),
          findsOneWidget,
        );
      });

      testWidgets('should format travel time correctly for hours', (
        tester,
      ) async {
        final result = ScheduleValidationResult.differentWarning(
          message: 'Test',
          distanceKm: 100,
          travelTimeMin: 180,
          suggestedDayIndex: null,
        );

        await tester.pumpWidget(buildTestWidget(validationResult: result));

        expect(find.textContaining('3 tiếng'), findsOneWidget);
      });
    });

    group('Distant Destination Warning', () {
      testWidgets('should display strong warning message', (tester) async {
        final result = ScheduleValidationResult.distantWarning(
          message: 'Phú Quốc cách Hà Nội 1800 km',
          distanceKm: 1800,
          travelTimeMin: 1440, // 24 hours
          suggestedDayIndex: 2,
        );

        await tester.pumpWidget(buildTestWidget(validationResult: result));

        expect(find.text('⚠️'), findsOneWidget);
        expect(
          find.textContaining('Lịch trình có thể không thực tế'),
          findsOneWidget,
        );
      });
    });

    group('Distance and Time Formatting', () {
      testWidgets('should format distance in km', (tester) async {
        final result = ScheduleValidationResult.differentWarning(
          message: 'Test',
          distanceKm: 150,
          travelTimeMin: 120,
          suggestedDayIndex: null,
        );

        await tester.pumpWidget(buildTestWidget(validationResult: result));

        expect(find.textContaining('~150 km'), findsOneWidget);
      });

      testWidgets('should format time with hours and minutes', (tester) async {
        final result = ScheduleValidationResult.differentWarning(
          message: 'Test',
          distanceKm: 100,
          travelTimeMin: 150, // 2h 30m
          suggestedDayIndex: null,
        );

        await tester.pumpWidget(buildTestWidget(validationResult: result));

        expect(find.textContaining('2 tiếng 30 phút'), findsOneWidget);
      });

      testWidgets('should format time in minutes only when less than 1 hour', (
        tester,
      ) async {
        final result = ScheduleValidationResult.adjacentWarning(
          message: 'Test',
          distanceKm: 10,
          travelTimeMin: 45,
          suggestedDayIndex: null,
        );

        await tester.pumpWidget(buildTestWidget(validationResult: result));

        expect(find.textContaining('45 phút'), findsOneWidget);
      });
    });

    group('Styling', () {
      testWidgets('should have blue background for adjacent warning', (
        tester,
      ) async {
        final result = ScheduleValidationResult.adjacentWarning(
          message: 'Test',
          distanceKm: 30,
          travelTimeMin: 45,
          suggestedDayIndex: null,
        );

        await tester.pumpWidget(buildTestWidget(validationResult: result));

        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, Colors.blue.shade50);
      });

      testWidgets('should have amber background for different warning', (
        tester,
      ) async {
        final result = ScheduleValidationResult.differentWarning(
          message: 'Test',
          distanceKm: 100,
          travelTimeMin: 180,
          suggestedDayIndex: null,
        );

        await tester.pumpWidget(buildTestWidget(validationResult: result));

        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, Colors.amber.shade50);
      });

      testWidgets('should have red background for distant warning', (
        tester,
      ) async {
        final result = ScheduleValidationResult.distantWarning(
          message: 'Test',
          distanceKm: 500,
          travelTimeMin: 600,
          suggestedDayIndex: null,
        );

        await tester.pumpWidget(buildTestWidget(validationResult: result));

        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, Colors.red.shade50);
      });
    });
  });
}
