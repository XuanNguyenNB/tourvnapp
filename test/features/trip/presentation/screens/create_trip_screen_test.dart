import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/presentation/screens/create_trip_screen.dart';
import 'package:tour_vn/features/trip/presentation/widgets/day_count_selector.dart';
import 'package:tour_vn/features/trip/presentation/widgets/destination_selection_grid.dart';
import 'package:tour_vn/core/widgets/gradient_button.dart';

void main() {
  Widget createTestWidget() {
    return const ProviderScope(child: MaterialApp(home: CreateTripScreen()));
  }

  testWidgets('CreateTripScreen should render all 3 sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify app bar title
    expect(find.text('Tạo chuyến đi mới'), findsOneWidget);

    // Verify sections
    expect(find.text('BƯỚC 1: Bạn muốn đi đâu?'), findsOneWidget);
    expect(
      find.text('BƯỚC 2: Đi mấy ngày?'),
      findsWidgets,
    ); // Wait, text contains "BƯỚC 2: Đi mấy ngày?" might be tricky to scroll
    expect(find.text('BƯỚC 3: Tên chuyến đi (tuỳ chọn)'), findsOneWidget);

    // Verify widgets
    expect(find.byType(DestinationSelectionGrid), findsOneWidget);
    expect(find.byType(DayCountSelector), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Ensure button is presented and disabled initially (destination must be selected)
    final button = tester.widget<GradientButton>(find.byType(GradientButton));
    expect(button.onPressed, isNull);
  });
}
