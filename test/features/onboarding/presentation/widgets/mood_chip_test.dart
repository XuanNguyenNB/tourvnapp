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

    testWidgets('renders mood emoji and label', (tester) async {
      await tester.pumpWidget(
        createTestWidget(mood: Mood.foodie, isSelected: false),
      );

      expect(find.text('🍜'), findsOneWidget);
      expect(find.text('Ẩm thực'), findsOneWidget);
    });

    testWidgets('does not render subtitle in compact layout', (tester) async {
      await tester.pumpWidget(
        createTestWidget(mood: Mood.foodie, isSelected: false),
      );

      expect(find.text(Mood.foodie.subtitle), findsNothing);
    });

    testWidgets('renders all current mood types', (tester) async {
      for (final mood in Mood.all) {
        await tester.pumpWidget(
          createTestWidget(mood: mood, isSelected: false),
        );

        expect(find.text(mood.emoji), findsOneWidget);
        expect(find.text(mood.label), findsOneWidget);
      }
    });

    testWidgets('selected chip shows check icon and primary border', (tester) async {
      await tester.pumpWidget(
        createTestWidget(mood: Mood.healing, isSelected: true),
      );

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = animatedContainer.decoration as BoxDecoration;
      final border = decoration.border as Border;

      expect(border.top.width, equals(2.0));
      expect(border.top.color, equals(AppColors.primary));
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('unselected chip keeps thin border and no check icon', (tester) async {
      await tester.pumpWidget(
        createTestWidget(mood: Mood.party, isSelected: false),
      );

      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = animatedContainer.decoration as BoxDecoration;
      final border = decoration.border as Border;

      expect(border.top.width, equals(1.0));
      expect(decoration.boxShadow, isNull);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      var wasTapped = false;

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
  });
}
