import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/schedule_optimization_result.dart';
import 'package:tour_vn/features/trip/domain/entities/trip_day.dart';
import 'package:tour_vn/features/trip/presentation/widgets/optimization_result_dialog.dart';

void main() {
  group('OptimizationResultDialog', () {
    testWidgets('renders correctly when there are changes', (tester) async {
      bool applyClicked = false;
      bool cancelClicked = false;

      final result = ScheduleOptimizationResult(
        optimizedDays: const [TripDay(dayNumber: 1, activities: [])],
        totalTravelTimeSavedMin: 120,
        totalDistanceSavedKm: 50.5,
        originalTravelTimeMin: 300,
        optimizedTravelTimeMin: 180,
        changes: const [
          OptimizationChange(
            fromDay: 2,
            toDay: 1,
            activityName: 'Bà Nà Hills',
            reason: 'Grouping with Da Nang activities',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => OptimizationResultDialog(
                      result: result,
                      onApply: () {
                        applyClicked = true;
                      },
                      onCancel: () {
                        cancelClicked = true;
                      },
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Check content
      expect(find.text('Tối ưu Lịch trình bằng AI'), findsOneWidget);
      expect(find.text('50 km'), findsOneWidget);
      expect(find.text('120 phút'), findsOneWidget);
      expect(find.textContaining('Bà Nà Hills'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(cancelClicked, isTrue);
      expect(applyClicked, isFalse);
    });

    testWidgets('calls onApply when Apply is clicked', (tester) async {
      bool applyClicked = false;
      bool cancelClicked = false;

      final result = ScheduleOptimizationResult(
        optimizedDays: const [TripDay(dayNumber: 1, activities: [])],
        totalTravelTimeSavedMin: 120,
        totalDistanceSavedKm: 50.5,
        originalTravelTimeMin: 300,
        optimizedTravelTimeMin: 180,
        changes: const [
          OptimizationChange(
            fromDay: 2,
            toDay: 1,
            activityName: 'Test Activity',
            reason: 'Test Reason',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => OptimizationResultDialog(
                      result: result,
                      onApply: () {
                        applyClicked = true;
                      },
                      onCancel: () {
                        cancelClicked = true;
                      },
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      expect(applyClicked, isTrue);
      expect(cancelClicked, isFalse);
    });
  });
}
