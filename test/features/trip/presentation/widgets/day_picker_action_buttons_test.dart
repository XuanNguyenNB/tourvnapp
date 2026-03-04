import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/domain/entities/schedule_validation_result.dart';
import 'package:tour_vn/features/trip/presentation/widgets/day_picker_action_buttons.dart';

void main() {
  group('DayPickerActionButtons', () {
    late bool confirmCalled;
    late bool acceptSuggestionCalled;

    setUp(() {
      confirmCalled = false;
      acceptSuggestionCalled = false;
    });

    Widget buildTestWidget({
      bool canConfirm = true,
      int selectedDayIndex = 0,
      ScheduleValidationResult? validationResult,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: DayPickerActionButtons(
            canConfirm: canConfirm,
            selectedDayIndex: selectedDayIndex,
            validationResult: validationResult,
            onConfirm: () => confirmCalled = true,
            onAcceptSuggestion: () => acceptSuggestionCalled = true,
          ),
        ),
      );
    }

    group('Single Button Mode (No Warning)', () {
      testWidgets(
        'should show single confirm button when no validation result',
        (tester) async {
          await tester.pumpWidget(buildTestWidget());

          expect(find.text('Thêm vào lịch trình'), findsOneWidget);
          expect(find.byType(GestureDetector), findsOneWidget);
        },
      );

      testWidgets('should show single confirm button when valid result', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(validationResult: ScheduleValidationResult.valid()),
        );

        expect(find.text('Thêm vào lịch trình'), findsOneWidget);
      });

      testWidgets('should call onConfirm when tapped', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        await tester.tap(find.text('Thêm vào lịch trình'));
        await tester.pump();

        expect(confirmCalled, isTrue);
      });

      testWidgets('should be disabled when canConfirm is false', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(canConfirm: false));

        await tester.tap(find.text('Thêm vào lịch trình'));
        await tester.pump();

        expect(confirmCalled, isFalse);
      });
    });

    group('Single Button with Warning (No Suggestion)', () {
      testWidgets(
        'should show warning indicator when has warning but no suggestion',
        (tester) async {
          final result = ScheduleValidationResult.differentWarning(
            message: 'Test',
            distanceKm: 100,
            travelTimeMin: 180,
            suggestedDayIndex: null, // No suggestion
          );

          await tester.pumpWidget(
            buildTestWidget(selectedDayIndex: 0, validationResult: result),
          );

          expect(find.textContaining('Thêm vào Ngày 1 ⚠️'), findsOneWidget);
        },
      );
    });

    group('Dual Button Mode (With Suggestion)', () {
      testWidgets('should show two buttons when has warning with suggestion', (
        tester,
      ) async {
        final result = ScheduleValidationResult.differentWarning(
          message: 'Test',
          distanceKm: 100,
          travelTimeMin: 180,
          suggestedDayIndex: 2,
        );

        await tester.pumpWidget(
          buildTestWidget(selectedDayIndex: 0, validationResult: result),
        );

        // Primary: Accept suggestion (Day 3 = index 2 + 1)
        expect(
          find.textContaining('✓ Thêm vào Ngày 3 (gợi ý)'),
          findsOneWidget,
        );
        // Secondary: Keep original (Day 1 = index 0 + 1)
        expect(find.textContaining('Giữ nguyên Ngày 1 ⚠️'), findsOneWidget);
      });

      testWidgets('should call onAcceptSuggestion when primary button tapped', (
        tester,
      ) async {
        final result = ScheduleValidationResult.differentWarning(
          message: 'Test',
          distanceKm: 100,
          travelTimeMin: 180,
          suggestedDayIndex: 1,
        );

        await tester.pumpWidget(buildTestWidget(validationResult: result));

        await tester.tap(find.textContaining('✓ Thêm vào Ngày 2 (gợi ý)'));
        await tester.pump();

        expect(acceptSuggestionCalled, isTrue);
        expect(confirmCalled, isFalse);
      });

      testWidgets('should call onConfirm when secondary button tapped', (
        tester,
      ) async {
        final result = ScheduleValidationResult.differentWarning(
          message: 'Test',
          distanceKm: 100,
          travelTimeMin: 180,
          suggestedDayIndex: 1,
        );

        await tester.pumpWidget(
          buildTestWidget(selectedDayIndex: 0, validationResult: result),
        );

        await tester.tap(find.textContaining('Giữ nguyên Ngày 1 ⚠️'));
        await tester.pump();

        expect(confirmCalled, isTrue);
        expect(acceptSuggestionCalled, isFalse);
      });
    });

    group('Day Number Display', () {
      testWidgets('should display correct day numbers (1-indexed)', (
        tester,
      ) async {
        final result = ScheduleValidationResult.differentWarning(
          message: 'Test',
          distanceKm: 100,
          travelTimeMin: 180,
          suggestedDayIndex: 4, // Day 5
        );

        await tester.pumpWidget(
          buildTestWidget(
            selectedDayIndex: 2, // Day 3
            validationResult: result,
          ),
        );

        expect(find.textContaining('Ngày 5 (gợi ý)'), findsOneWidget);
        expect(find.textContaining('Giữ nguyên Ngày 3'), findsOneWidget);
      });
    });

    group('Button Styling', () {
      testWidgets('primary button should have gradient when enabled', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(canConfirm: true));

        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.gradient, isNotNull);
      });

      testWidgets('button should have gray background when disabled', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(canConfirm: false));

        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, const Color(0xFFE2E8F0));
      });
    });
  });
}
