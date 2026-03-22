import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/admin/presentation/providers/admin_stats_provider.dart';
import 'package:tour_vn/features/admin/presentation/screens/admin_overview_screen.dart';

void main() {
  final mockStats = AdminStats(
    totalUsers: 42,
    totalDestinations: 5,
    totalLocations: 120,
    totalReviews: 300,
    pendingComments: 3,
    pendingAiDrafts: 0,
    recentActivities: [
      {
        'id': 'rev-1',
        'title': 'Review Da Lat',
        'type': 'review',
        'createdAt': null,
      },
      {
        'id': 'rev-2',
        'title': 'Review Ninh Binh',
        'type': 'review',
        'createdAt': null,
      },
    ],
  );

  Widget createWidgetUnderTest(AdminStats stats) {
    return ProviderScope(
      overrides: [adminStatsProvider.overrideWith((_) async => stats)],
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1200, 900)),
          child: const AdminOverviewScreen(),
        ),
      ),
    );
  }

  testWidgets('Should display stat cards with correct values', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(mockStats));
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng trở lại, Admin'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(find.text('Người dùng'), findsOneWidget);
    expect(find.text('Điểm đến'), findsOneWidget);
    expect(find.text('Địa điểm'), findsOneWidget);
    expect(find.text('Bài viết'), findsOneWidget);
  });

  testWidgets('Should display recent activities', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(mockStats));
    await tester.pumpAndSettle();

    expect(find.text('Hoạt động gần đây'), findsOneWidget);
    expect(find.text('Review Da Lat'), findsOneWidget);
    expect(find.text('Review Ninh Binh'), findsOneWidget);
  });

  testWidgets('Should show empty message when no activities', (tester) async {
    final emptyStats = AdminStats(
      totalUsers: 0,
      totalDestinations: 0,
      totalLocations: 0,
      totalReviews: 0,
      pendingComments: 0,
      pendingAiDrafts: 0,
      recentActivities: const [],
    );
    await tester.pumpWidget(createWidgetUnderTest(emptyStats));
    await tester.pumpAndSettle();

    expect(find.text('Không có hoạt động nào gần đây'), findsOneWidget);
  });
}
