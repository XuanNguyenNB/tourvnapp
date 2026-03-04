import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/features/admin/presentation/providers/admin_stats_provider.dart';
import 'package:tour_vn/features/admin/presentation/screens/admin_overview_screen.dart';

void main() {
  final mockStats = AdminStats(
    totalUsers: 42,
    totalDestinations: 5,
    totalLocations: 120,
    totalReviews: 300,
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
      child: const MaterialApp(home: AdminOverviewScreen()),
    );
  }

  testWidgets('Should display stat cards with correct values', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest(mockStats));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Overview'), findsOneWidget);
    expect(find.text('42'), findsOneWidget); // Users
    expect(find.text('5'), findsOneWidget); // Destinations
    expect(find.text('120'), findsOneWidget); // Locations
    expect(find.text('300'), findsOneWidget); // Reviews
    expect(find.text('Total Users'), findsOneWidget);
    expect(find.text('Destinations'), findsOneWidget);
    expect(find.text('Locations'), findsOneWidget);
    expect(find.text('Reviews'), findsOneWidget);
  });

  testWidgets('Should display recent activities', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest(mockStats));
    await tester.pumpAndSettle();

    expect(find.text('Recent Activities'), findsOneWidget);
    expect(find.text('Review Da Lat'), findsOneWidget);
    expect(find.text('Review Ninh Binh'), findsOneWidget);
  });

  testWidgets('Should show empty message when no activities', (
    WidgetTester tester,
  ) async {
    final emptyStats = AdminStats(
      totalUsers: 0,
      totalDestinations: 0,
      totalLocations: 0,
      totalReviews: 0,
      recentActivities: [],
    );
    await tester.pumpWidget(createWidgetUnderTest(emptyStats));
    await tester.pumpAndSettle();

    expect(find.text('No recent activities'), findsOneWidget);
  });
}
