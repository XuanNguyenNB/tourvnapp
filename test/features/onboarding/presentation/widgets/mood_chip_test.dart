import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/features/onboarding/domain/entities/mood.dart';
import 'package:tour_vn/features/onboarding/presentation/widgets/mood_chip.dart';

void main() {
  group('MoodChip Widget', () {
    Widget createTestWidget({
      required Mood mood,
      required bool isSelected,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: MoodChip(
              mood: mood,
              isSelected: isSelected,
              onTap: onTap ?? () {},
            ),
          ),
        ),
      );
    }

    group('Rendering', () {
      testWidgets('renders mood emoji correctly', (tester) async {
        await tester.pumpWidget(
          createTestWidget(mood: Mood.healing, isSelected: false),
        );

        expect(find.text('🧘'), findsOneWidget);
      });

      testWidgets('renders Vietnamese mood label correctly', (tester) async {
        await tester.pumpWidget(
          createTestWidget(mood: Mood.adventure, isSelected: false),
        );

        expect(find.text('Phiêu lưu'), findsOneWidget);
      });

      testWidgets('renders mood subtitle correctly', (tester) async {
        await tester.pumpWidget(
          createTestWidget(mood: Mood.adventure, isSelected: false),
        );

        expect(find.text('Khám phá, mạo hiểm'), findsOneWidget);
      });

      testWidgets('renders all mood types correctly', (tester) async {
        for (final mood in Mood.all) {
          await tester.pumpWidget(
            createTestWidget(mood: mood, isSelected: false),
          );

          expect(find.text(mood.emoji), findsOneWidget);
          expect(find.text(mood.label), findsOneWidget);
          expect(find.text(mood.subtitle), findsOneWidget);
        }
      });
    });

    group('Selected State Visual', () {
      testWidgets('selected chip has purple border with width 2', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(mood: Mood.foodie, isSelected: true),
        );

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );

        final decoration = animatedContainer.decoration as BoxDecoration;
        final border = decoration.border as Border;

        expect(border.top.width, equals(2.0));
        expect(border.top.color, equals(AppColors.primary));
      });

      testWidgets('selected chip has purple background with alpha', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(mood: Mood.photography, isSelected: true),
        );

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );

        final decoration = animatedContainer.decoration as BoxDecoration;

        // Verify background color has alpha (15% opacity)
        expect(decoration.color, isNotNull);
        expect(decoration.color!.a, lessThan(1.0));
      });

      testWidgets('selected chip shows check icon', (tester) async {
        await tester.pumpWidget(
          createTestWidget(mood: Mood.healing, isSelected: true),
        );

        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      });

      testWidgets('selected chip has box shadow', (tester) async {
        await tester.pumpWidget(
          createTestWidget(mood: Mood.foodie, isSelected: true),
        );

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );

        final decoration = animatedContainer.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow, isNotEmpty);
      });
    });

    group('Unselected State Visual', () {
      testWidgets('unselected chip has thin white/translucent border', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(mood: Mood.party, isSelected: false),
        );

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );

        final decoration = animatedContainer.decoration as BoxDecoration;
        final border = decoration.border as Border;

        expect(border.top.width, equals(1.0));
      });

      testWidgets('unselected chip has translucent background', (tester) async {
        await tester.pumpWidget(
          createTestWidget(mood: Mood.healing, isSelected: false),
        );

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );

        final decoration = animatedContainer.decoration as BoxDecoration;

        expect(decoration.color, isNotNull);
        expect(decoration.color!.a, lessThan(1.0));
      });

      testWidgets('unselected chip has no box shadow', (tester) async {
        await tester.pumpWidget(
          createTestWidget(mood: Mood.party, isSelected: false),
        );

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );

        final decoration = animatedContainer.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNull);
      });
    });

    group('Tap Callback', () {
      testWidgets('onTap callback is called when tapped', (tester) async {
        bool wasTapped = false;

        await tester.pumpWidget(
          createTestWidget(
            mood: Mood.party,
            isSelected: false,
            onTap: () => wasTapped = true,
          ),
        );

        await tester.tap(find.byType(MoodChip));
        await tester.pump();

        expect(wasTapped, isTrue);
      });

      testWidgets('onTap callback works when chip is selected', (tester) async {
        int tapCount = 0;

        await tester.pumpWidget(
          createTestWidget(
            mood: Mood.healing,
            isSelected: true,
            onTap: () => tapCount++,
          ),
        );

        await tester.tap(find.byType(MoodChip));
        await tester.pump();
        await tester.tap(find.byType(MoodChip));
        await tester.pump();

        expect(tapCount, equals(2));
      });
    });

    group('Animation', () {
      testWidgets('uses AnimatedContainer for smooth transitions', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(mood: Mood.foodie, isSelected: false),
        );

        expect(find.byType(AnimatedContainer), findsOneWidget);
      });

      testWidgets('uses AnimatedScale for selection animation', (tester) async {
        await tester.pumpWidget(
          createTestWidget(mood: Mood.foodie, isSelected: true),
        );

        final animatedScale = tester.widget<AnimatedScale>(
          find.byType(AnimatedScale),
        );
        expect(animatedScale.scale, equals(1.05));
      });

      testWidgets('unselected has scale 1.0', (tester) async {
        await tester.pumpWidget(
          createTestWidget(mood: Mood.foodie, isSelected: false),
        );

        final animatedScale = tester.widget<AnimatedScale>(
          find.byType(AnimatedScale),
        );
        expect(animatedScale.scale, equals(1.0));
      });

      testWidgets('has 250ms animation duration for container', (tester) async {
        await tester.pumpWidget(
          createTestWidget(mood: Mood.adventure, isSelected: false),
        );

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );

        expect(
          animatedContainer.duration,
          equals(const Duration(milliseconds: 250)),
        );
      });

      testWidgets('uses easeOutCubic curve for animation', (tester) async {
        await tester.pumpWidget(
          createTestWidget(mood: Mood.photography, isSelected: false),
        );

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );

        expect(animatedContainer.curve, equals(Curves.easeOutCubic));
      });
    });

    group('State Transition', () {
      testWidgets('visual transition from unselected to selected', (
        tester,
      ) async {
        // Start unselected
        await tester.pumpWidget(
          createTestWidget(mood: Mood.healing, isSelected: false),
        );

        var animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        var decoration = animatedContainer.decoration as BoxDecoration;
        var border = decoration.border as Border;

        expect(border.top.width, equals(1.0)); // Unselected

        // Rebuild with selected state
        await tester.pumpWidget(
          createTestWidget(mood: Mood.healing, isSelected: true),
        );
        await tester.pumpAndSettle(); // Wait for animation

        animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        decoration = animatedContainer.decoration as BoxDecoration;
        border = decoration.border as Border;

        expect(border.top.width, equals(2.0)); // Selected
        expect(border.top.color, equals(AppColors.primary));
      });

      testWidgets('visual transition from selected to unselected', (
        tester,
      ) async {
        // Start selected
        await tester.pumpWidget(
          createTestWidget(mood: Mood.party, isSelected: true),
        );

        var animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        var decoration = animatedContainer.decoration as BoxDecoration;
        var border = decoration.border as Border;

        expect(border.top.width, equals(2.0)); // Selected

        // Rebuild with unselected state
        await tester.pumpWidget(
          createTestWidget(mood: Mood.party, isSelected: false),
        );
        await tester.pumpAndSettle(); // Wait for animation

        animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        decoration = animatedContainer.decoration as BoxDecoration;
        border = decoration.border as Border;

        expect(border.top.width, equals(1.0)); // Unselected
      });
    });
  });
}
