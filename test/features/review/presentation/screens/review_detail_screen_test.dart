import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'package:tour_vn/features/review/presentation/screens/review_detail_screen.dart';
import 'package:tour_vn/features/home/domain/entities/review_preview.dart';

/// Mocks HTTP calls to allow CachedNetworkImage to work in tests
class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  // Set up mock HTTP for network images
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  group('ReviewDetailScreen', () {
    late ReviewPreview mockPreview;

    setUp(() {
      mockPreview = const ReviewPreview(
        title: 'Test Review',
        id: 'r1',
        authorName: 'Test Author',
        authorAvatar: 'https://via.placeholder.com/50',
        shortText: 'This is a short review text for testing.',
        heroImage: 'https://via.placeholder.com/400',
        likeCount: 1234,
        commentCount: 56,
      );
    });

    Widget buildTestWidget({ReviewPreview? preview}) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ReviewDetailScreen(reviewId: 'r1', reviewPreview: preview),
          ),
        ),
      );
    }

    testWidgets('should have back button icon', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(preview: mockPreview));
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('should display CTA button text', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(preview: mockPreview));
      await tester.pump();

      expect(find.text('Thêm vào Trip'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('should use CustomScrollView structure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(preview: mockPreview));
      await tester.pump();

      expect(find.byType(CustomScrollView), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('should use SliverAppBar for hero header', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(preview: mockPreview));
      await tester.pump();

      expect(find.byType(SliverAppBar), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('should show loading state without preview', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(preview: null));
      await tester.pump();

      expect(find.byType(CustomScrollView), findsOneWidget);

      await tester.pumpAndSettle();
    });
  });
}
