import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/destination/domain/entities/destination.dart';
import 'package:tour_vn/features/destination/presentation/providers/destination_provider.dart';
import 'package:tour_vn/features/onboarding/domain/entities/mood.dart';
import 'package:tour_vn/features/onboarding/presentation/providers/mood_selection_provider.dart';
import 'package:tour_vn/features/onboarding/presentation/screens/mood_selection_screen.dart';
import 'package:tour_vn/features/onboarding/presentation/widgets/mood_chip.dart';

void main() {
  final mockDestinations = const [
    Destination(
      id: 'da-nang',
      name: 'Đà Nẵng',
      heroImage: 'https://example.com/da-nang.jpg',
      description: 'City',
    ),
    Destination(
      id: 'hue',
      name: 'Huế',
      heroImage: 'https://example.com/hue.jpg',
      description: 'Ancient capital',
    ),
  ];

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        allDestinationsProvider.overrideWith((ref) async => mockDestinations),
      ],
      child: const MaterialApp(home: MoodSelectionScreen()),
    );
  }

  Future<void> goToSelectionPage(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bắt đầu khám phá'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Để sau, không cần vị trí'));
    await tester.tap(find.text('Để sau, không cần vị trí'));
    await tester.pumpAndSettle();
  }

  group('MoodSelectionScreen', () {
    testWidgets('shows welcome page content', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Chào bạn! 👋'), findsOneWidget);
      expect(find.textContaining('TourVN giúp bạn khám phá'), findsOneWidget);
      expect(find.text('Bắt đầu khám phá'), findsOneWidget);
    });

    testWidgets('navigates from welcome page to GPS page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bắt đầu khám phá'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Bật vị trí để'), findsOneWidget);
      expect(find.text('📍 Cho phép truy cập vị trí'), findsOneWidget);
    });

    testWidgets('shows selection page with current mood chips', (tester) async {
      await goToSelectionPage(tester);

      expect(find.text('Cá nhân hóa trải nghiệm'), findsOneWidget);
      expect(find.text('Phong cách du lịch'), findsOneWidget);
      expect(find.text('Bạn muốn đi đâu?'), findsOneWidget);
      expect(find.byType(MoodChip), findsNWidgets(Mood.all.length));
      for (final mood in Mood.all) {
        expect(find.text(mood.label), findsOneWidget);
      }
    });

    testWidgets('shows CTA hint when nothing is selected', (tester) async {
      await goToSelectionPage(tester);

      expect(find.text('Chọn ít nhất 1 mục'), findsOneWidget);
    });

    testWidgets('tapping mood chip toggles selection', (tester) async {
      await goToSelectionPage(tester);

      await tester.tap(find.text('Chữa lành'));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MoodSelectionScreen)),
      );
      final state = container.read(moodSelectionProvider);

      expect(state.isSelected(Mood.healing), isTrue);
      expect(find.text('Đã chọn 1'), findsOneWidget);
      expect(find.text('Khám phá ngay! 🚀'), findsOneWidget);
    });

    testWidgets('multiple moods can be selected and deselected', (tester) async {
      await goToSelectionPage(tester);

      await tester.tap(find.text('Ẩm thực'));
      await tester.pump();
      await tester.tap(find.text('Chụp ảnh'));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MoodSelectionScreen)),
      );
      var state = container.read(moodSelectionProvider);
      expect(state.selectionCount, equals(2));
      expect(state.isSelected(Mood.foodie), isTrue);
      expect(state.isSelected(Mood.photography), isTrue);

      await tester.tap(find.text('Ẩm thực'));
      await tester.pump();

      state = container.read(moodSelectionProvider);
      expect(state.selectionCount, equals(1));
      expect(state.isSelected(Mood.foodie), isFalse);
    });

    testWidgets('shows login link on selection page', (tester) async {
      await goToSelectionPage(tester);

      expect(find.text('Đã có tài khoản? Đăng nhập'), findsOneWidget);
    });
  });
}
