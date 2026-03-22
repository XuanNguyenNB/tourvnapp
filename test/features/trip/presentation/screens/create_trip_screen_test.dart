import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/core/widgets/gradient_button.dart';
import 'package:tour_vn/features/destination/domain/entities/destination.dart';
import 'package:tour_vn/features/destination/presentation/providers/destination_provider.dart';
import 'package:tour_vn/features/trip/presentation/screens/create_trip_screen.dart';
import 'package:tour_vn/features/trip/presentation/widgets/day_count_selector.dart';
import 'package:tour_vn/features/trip/presentation/widgets/destination_selection_grid.dart';

void main() {
  final mockDestinations = const [
    Destination(
      id: 'da-nang',
      name: 'Đà Nẵng',
      heroImage: 'https://example.com/da-nang.jpg',
      description: 'City',
    ),
  ];

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        allDestinationsProvider.overrideWith((ref) async => mockDestinations),
      ],
      child: const MaterialApp(home: CreateTripScreen()),
    );
  }

  testWidgets('CreateTripScreen renders current sections and inputs', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Tạo chuyến đi mới'), findsOneWidget);
    expect(find.textContaining('BƯỚC 1'), findsOneWidget);
    expect(find.textContaining('BƯỚC 2'), findsOneWidget);
    expect(find.textContaining('BƯỚC 3'), findsOneWidget);

    expect(find.byType(DestinationSelectionGrid), findsOneWidget);
    expect(find.byType(DayCountSelector), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    final button = tester.widget<GradientButton>(find.byType(GradientButton));
    expect(button.onPressed, isNull);
  });
}
