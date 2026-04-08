import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/core/services/ai_backend_service.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';
import 'package:tour_vn/features/itinerary/domain/models/auto_plan_request.dart';
import 'package:tour_vn/features/itinerary/domain/services/auto_plan_service.dart';
import 'package:tour_vn/features/itinerary/presentation/providers/auto_plan_provider.dart';
import 'package:tour_vn/features/itinerary/presentation/screens/ai_plan_screen.dart';
import 'package:tour_vn/features/recommendation/domain/entities/user_profile.dart';

class _FakeAutoPlanNotifier extends AutoPlanNotifier {
  _FakeAutoPlanNotifier(this._state);

  final AutoPlanState _state;

  @override
  AutoPlanState build() => _state;

  @override
  Future<void> generate(AutoPlanRequest request) async {
    state = _state;
  }
}

AutoPlanResult _buildResult() {
  const request = AutoPlanRequest(
    destinationId: 'da-nang',
    destinationName: 'Đà Nẵng',
    numberOfDays: 3,
    preferredCategoryIds: ['food', 'places'],
    preferredTags: ['local-favorite', 'instagram-worthy'],
    pace: TravelPace.normal,
    budgetLevel: BudgetLevel.medium,
    groupType: GroupType.friends,
    useBehaviorSignals: true,
  );

  const location = Location(
    id: 'loc-1',
    destinationId: 'da-nang',
    destinationName: 'Đà Nẵng',
    name: 'Cầu Rồng',
    image: 'https://example.com/cau-rong.jpg',
    category: 'places',
    rating: 4.7,
  );

  return const AutoPlanResult(
    request: request,
    tripTitle: 'Đà Nẵng rực sáng trong 3 ngày',
    tripDescription:
        'Hành trình cân bằng giữa ăn ngon, check-in đẹp và nhịp đi vừa phải.',
    table: AiScheduleTable(
      dayHeaders: ['Ngày 1'],
      rows: [
        AiScheduleRow(timeLabel: '08:00', dayCells: ['Cầu Rồng']),
      ],
    ),
    days: [
      AutoPlanDay(
        dayIndex: 0,
        dayTheme: 'Biển, cầu và nhịp sống trẻ',
        dayDescription:
            'Ngày đầu ưu tiên các điểm biểu tượng và trải nghiệm mở màn dễ gây ấn tượng.',
        stops: [
          AutoPlanStop(
            location: location,
            timeSlotName: 'Sáng',
            startMinute: 480,
            durationMin: 60,
            reasons: ['Được đánh giá cao'],
            aiDescription:
                'Điểm check-in mở màn giúp chuyến đi lên mood rất nhanh.',
          ),
        ],
      ),
    ],
  );
}

Widget _buildWidget({
  required AutoPlanState state,
  required AiBackendHealth health,
}) {
  return ProviderScope(
    overrides: [
      autoPlanProvider.overrideWith(() => _FakeAutoPlanNotifier(state)),
      aiBackendHealthProvider.overrideWith((_) async => health),
    ],
    child: const MaterialApp(
      home: AiPlanScreen(
        initialDestinationId: 'da-nang',
        initialDestinationName: 'Đà Nẵng',
      ),
    ),
  );
}

Future<void> _goToPreview(WidgetTester tester) async {
  await tester.tap(find.text('Tiếp tục'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Tiếp tục'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('✨ Tạo lịch trình'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('preview hiển thị narrative AI ngay trên card', (tester) async {
    await tester.pumpWidget(
      _buildWidget(
        state: AutoPlanState(result: _buildResult()),
        health: const AiBackendHealth(
          status: 'ok',
          model: 'gemini-3-flash',
          upstream: 'CLIProxyAPI',
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _goToPreview(tester);

    expect(find.text('AI online • gemini-3-flash'), findsNWidgets(2));
    expect(find.text('Đà Nẵng rực sáng trong 3 ngày'), findsOneWidget);
    expect(find.text('Biển, cầu và nhịp sống trẻ'), findsOneWidget);
    expect(
      find.text('Điểm check-in mở màn giúp chuyến đi lên mood rất nhanh.'),
      findsOneWidget,
    );
    expect(find.text('Vì sao lịch này hợp với bạn'), findsOneWidget);
  });

  testWidgets('hiển thị banner degrade mode khi AI fallback', (tester) async {
    await tester.pumpWidget(
      _buildWidget(
        state: AutoPlanState(
          result: _buildResult(),
          usedAlgorithmFallback: true,
          aiMessage:
              'AI chưa viết được phần mô tả. Lịch trình vẫn được tạo bằng thuật toán.',
        ),
        health: const AiBackendHealth(
          status: 'offline',
          message: 'AI backend đang tạm thời không phản hồi.',
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _goToPreview(tester);

    expect(find.text('AI offline • chế độ thuật toán'), findsNWidgets(2));
    expect(
      find.text(
        'AI chưa viết được phần mô tả. Lịch trình vẫn được tạo bằng thuật toán.',
      ),
      findsOneWidget,
    );
  });
}
