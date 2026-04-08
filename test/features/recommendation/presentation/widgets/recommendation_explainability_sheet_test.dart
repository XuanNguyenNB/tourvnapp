import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';
import 'package:tour_vn/features/recommendation/domain/entities/recommendation_item.dart';
import 'package:tour_vn/features/recommendation/presentation/widgets/recommendation_explainability_sheet.dart';

void main() {
  testWidgets('mở bottom sheet explainability và hiển thị lý do', (
    tester,
  ) async {
    const location = Location(
      id: 'loc-1',
      destinationId: 'da-nang',
      destinationName: 'Đà Nẵng',
      name: 'Cầu Rồng',
      image: 'https://example.com/cau-rong.jpg',
      category: 'places',
    );

    const recommendation = RecommendationItem(
      locationId: 'loc-1',
      score: 1.25,
      reasons: ['Được đánh giá cao', 'Phù hợp phong cách', '📍 Cách 1.2km'],
      scoreBreakdown: RecommendationScoreBreakdown(
        category: 0.3,
        quality: 0.4,
        proximity: 0.2,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showRecommendationExplainabilitySheet(
                  context: context,
                  location: location,
                  recommendation: recommendation,
                );
              },
              child: const Text('Mở'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();

    expect(find.text('Vì sao được gợi ý?'), findsOneWidget);
    expect(find.text('Top lý do'), findsOneWidget);
    expect(find.text('Được đánh giá cao'), findsOneWidget);
    expect(find.text('Lập lịch AI cho điểm đến này'), findsOneWidget);
  });
}
