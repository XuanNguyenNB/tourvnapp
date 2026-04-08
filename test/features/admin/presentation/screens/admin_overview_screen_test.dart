import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/admin/presentation/providers/admin_stats_provider.dart';
import 'package:tour_vn/features/admin/presentation/screens/admin_overview_screen.dart';

void main() {
  final mockStats = AdminStats(
    totalUsers: 42,
    publishedDestinations: 5,
    publishedLocations: 120,
    publishedReviews: 300,
    pendingComments: 3,
    flaggedComments: 4,
    pendingAiDrafts: 0,
    contentMissingImage: 2,
    contentMissingCoordinates: 7,
    recentActivities: const [
      AdminRecentActivity(
        id: 'rev-1',
        title: 'Review Da Lat',
        subtitle: 'Bài viết mẫu',
        type: 'review',
        route: '/admin/reviews',
      ),
      AdminRecentActivity(
        id: 'rev-2',
        title: 'Review Ninh Binh',
        subtitle: 'Bài viết mẫu',
        type: 'review',
        route: '/admin/reviews',
      ),
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

    expect(find.text('Xin chào quản trị viên'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(find.text('Người dùng'), findsOneWidget);
    expect(find.text('Điểm đến đang public'), findsOneWidget);
    expect(find.text('Địa điểm đang public'), findsOneWidget);
    expect(find.text('Bài viết đang public'), findsOneWidget);
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
      publishedDestinations: 0,
      publishedLocations: 0,
      publishedReviews: 0,
      pendingComments: 0,
      flaggedComments: 0,
      pendingAiDrafts: 0,
      contentMissingImage: 0,
      contentMissingCoordinates: 0,
      recentActivities: const [],
    );
    await tester.pumpWidget(createWidgetUnderTest(emptyStats));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có hoạt động vận hành gần đây'), findsOneWidget);
  });
}
