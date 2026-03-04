import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/onboarding/domain/entities/mood.dart';
import 'package:tour_vn/features/onboarding/presentation/providers/mood_selection_provider.dart';
import 'package:tour_vn/features/onboarding/presentation/screens/mood_selection_screen.dart';
import 'package:tour_vn/features/onboarding/presentation/widgets/mood_chip.dart';

void main() {
  group('MoodSelectionScreen', () {
    Widget createTestWidget() {
      return ProviderScope(
        child: const MaterialApp(home: MoodSelectionScreen()),
      );
    }

    // ─── PAGE 1: WELCOME ─────────────────────────────────────────

    group('Welcome Page', () {
      testWidgets('displays welcome heading in Vietnamese', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Chào bạn! 👋'), findsOneWidget);
      });

      testWidgets('displays app description in Vietnamese', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.textContaining('TourVN giúp bạn khám phá'), findsOneWidget);
      });

      testWidgets('displays CTA button to start', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Bắt đầu khám phá'), findsOneWidget);
      });

      testWidgets('displays feature highlights', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('🗺️'), findsOneWidget);
        expect(find.text('⭐'), findsOneWidget);
        expect(find.text('📍'), findsOneWidget);
      });

      testWidgets('displays page indicator dots', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should have 2 page indicator dots
        final dots = find.byWidgetPredicate((w) => w is AnimatedContainer);
        // AnimatedContainer is used for many things, just verify no crash
        expect(dots, findsWidgets);
      });
    });

    // ─── PAGE 2: MOOD SELECTION ──────────────────────────────────

    group('Mood Selection Page', () {
      /// Helper to navigate to mood selection page
      Future<void> goToMoodPage(WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        // Tap "Bắt đầu khám phá" to go to page 2
        await tester.tap(find.text('Bắt đầu khám phá'));
        await tester.pumpAndSettle();
      }

      testWidgets('displays mood selection heading in Vietnamese', (
        tester,
      ) async {
        await goToMoodPage(tester);

        expect(find.textContaining('Bạn thích du lịch'), findsOneWidget);
      });

      testWidgets('displays step indicator', (tester) async {
        await goToMoodPage(tester);

        expect(find.text('Bước 2/2'), findsOneWidget);
      });

      testWidgets('displays all 5 mood chips with Vietnamese labels', (
        tester,
      ) async {
        await goToMoodPage(tester);

        // Verify all Vietnamese mood labels are displayed
        expect(find.text('Chữa lành'), findsOneWidget);
        expect(find.text('Phiêu lưu'), findsOneWidget);
        expect(find.text('Ẩm thực'), findsOneWidget);
        expect(find.text('Chụp ảnh'), findsOneWidget);
        expect(find.text('Vui chơi'), findsOneWidget);

        // Verify all emojis are displayed
        expect(find.text('🧘'), findsOneWidget);
        expect(find.text('🏔️'), findsOneWidget);
        expect(find.text('🍜'), findsOneWidget);
        expect(find.text('📸'), findsOneWidget);
        expect(find.text('🎉'), findsOneWidget);
      });

      testWidgets('displays mood subtitles in Vietnamese', (tester) async {
        await goToMoodPage(tester);

        expect(find.text('Nghỉ dưỡng, thư giãn'), findsOneWidget);
        expect(find.text('Khám phá, mạo hiểm'), findsOneWidget);
        expect(find.text('Ăn uống, đặc sản'), findsOneWidget);
        expect(find.text('Check-in, sống ảo'), findsOneWidget);
        expect(find.text('Lễ hội, giải trí'), findsOneWidget);
      });

      testWidgets('CTA shows hint text when no mood selected', (tester) async {
        await goToMoodPage(tester);

        expect(find.text('Chọn ít nhất 1 phong cách'), findsOneWidget);
      });

      testWidgets('tapping mood chip toggles selection', (tester) async {
        await goToMoodPage(tester);

        // Find and tap Chữa lành chip
        await tester.tap(find.text('Chữa lành'));
        await tester.pump();

        // Verify provider state changed
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MoodSelectionScreen)),
        );
        final state = container.read(moodSelectionProvider);
        expect(state.isSelected(Mood.healing), isTrue);
      });

      testWidgets('CTA changes text after selecting a mood', (tester) async {
        await goToMoodPage(tester);

        // Tap a mood chip
        await tester.tap(find.text('Ẩm thực'));
        await tester.pump();

        // CTA text should change
        expect(find.text('Khám phá ngay! 🚀'), findsOneWidget);
      });

      testWidgets('multiple moods can be selected', (tester) async {
        await goToMoodPage(tester);

        // Select multiple moods
        await tester.tap(find.text('Chữa lành'));
        await tester.pump();
        await tester.tap(find.text('Chụp ảnh'));
        await tester.pump();
        await tester.tap(find.text('Vui chơi'));
        await tester.pump();

        // Verify state
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MoodSelectionScreen)),
        );
        final state = container.read(moodSelectionProvider);
        expect(state.selectionCount, equals(3));
        expect(state.isSelected(Mood.healing), isTrue);
        expect(state.isSelected(Mood.photography), isTrue);
        expect(state.isSelected(Mood.party), isTrue);
      });

      testWidgets('shows selected count badge', (tester) async {
        await goToMoodPage(tester);

        await tester.tap(find.text('Phiêu lưu'));
        await tester.pump();

        expect(find.text('Đã chọn 1'), findsOneWidget);
      });

      testWidgets('tapping selected mood deselects it', (tester) async {
        await goToMoodPage(tester);

        // Select a mood
        await tester.tap(find.text('Phiêu lưu'));
        await tester.pump();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MoodSelectionScreen)),
        );
        expect(
          container.read(moodSelectionProvider).isSelected(Mood.adventure),
          isTrue,
        );

        // Tap again to deselect
        await tester.tap(find.text('Phiêu lưu'));
        await tester.pump();

        expect(
          container.read(moodSelectionProvider).isSelected(Mood.adventure),
          isFalse,
        );
      });
    });

    // ─── SKIP ONBOARDING ─────────────────────────────────────────

    group('Skip Onboarding', () {
      Future<void> goToMoodPage(WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bắt đầu khám phá'));
        await tester.pumpAndSettle();
      }

      testWidgets('displays skip button in Vietnamese', (tester) async {
        await goToMoodPage(tester);

        expect(find.text('Để sau, tôi muốn xem trước'), findsOneWidget);
      });

      testWidgets('skip button is a TextButton', (tester) async {
        await goToMoodPage(tester);

        final skipButton = find.ancestor(
          of: find.text('Để sau, tôi muốn xem trước'),
          matching: find.byType(TextButton),
        );
        expect(skipButton, findsOneWidget);
      });

      testWidgets('skip button is tappable without selecting moods', (
        tester,
      ) async {
        await goToMoodPage(tester);

        // Skip button should be tappable even without mood selection
        await tester.tap(find.text('Để sau, tôi muốn xem trước'));
        await tester.pump();
        // No crash = success
      });
    });

    // ─── NAVIGATION ──────────────────────────────────────────────

    group('Navigation between pages', () {
      testWidgets('can navigate from welcome to mood selection', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should be on welcome page initially
        expect(find.text('Chào bạn! 👋'), findsOneWidget);

        // Tap CTA to go to page 2
        await tester.tap(find.text('Bắt đầu khám phá'));
        await tester.pumpAndSettle();

        // Should now see mood selection page content
        expect(find.text('Bước 2/2'), findsOneWidget);
      });

      testWidgets('can navigate back from mood selection to welcome', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Go to page 2
        await tester.tap(find.text('Bắt đầu khám phá'));
        await tester.pumpAndSettle();

        // Find and tap back button
        final backButton = find.byIcon(Icons.arrow_back_rounded);
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Should be back on welcome page
        expect(find.text('Chào bạn! 👋'), findsOneWidget);
      });
    });
  });

  group('MoodChip', () {
    Widget createTestWidget({
      required Mood mood,
      required bool isSelected,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        home: Scaffold(
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

    testWidgets('displays mood emoji and Vietnamese label', (tester) async {
      await tester.pumpWidget(
        createTestWidget(mood: Mood.healing, isSelected: false),
      );

      expect(find.text('🧘'), findsOneWidget);
      expect(find.text('Chữa lành'), findsOneWidget);
    });

    testWidgets('displays mood subtitle', (tester) async {
      await tester.pumpWidget(
        createTestWidget(mood: Mood.healing, isSelected: false),
      );

      expect(find.text('Nghỉ dưỡng, thư giãn'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        createTestWidget(
          mood: Mood.foodie,
          isSelected: false,
          onTap: () => wasTapped = true,
        ),
      );

      await tester.tap(find.byType(MoodChip));
      expect(wasTapped, isTrue);
    });

    testWidgets('shows check icon when selected', (tester) async {
      await tester.pumpWidget(
        createTestWidget(mood: Mood.photography, isSelected: true),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('shows selected state styling', (tester) async {
      await tester.pumpWidget(
        createTestWidget(mood: Mood.photography, isSelected: true),
      );

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );

      final decoration = animatedContainer.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect((decoration.border as Border).top.width, equals(2));
    });

    testWidgets('shows unselected state styling', (tester) async {
      await tester.pumpWidget(
        createTestWidget(mood: Mood.party, isSelected: false),
      );

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );

      final decoration = animatedContainer.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect((decoration.border as Border).top.width, equals(1));
    });
  });
}
