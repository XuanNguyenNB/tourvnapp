import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/home/domain/entities/review_preview.dart';
import 'package:tour_vn/features/review/domain/entities/review.dart';
import 'package:tour_vn/features/review/presentation/providers/review_provider.dart';
import 'package:tour_vn/features/review/presentation/screens/review_detail_screen.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  group('ReviewDetailScreen', () {
    late ReviewPreview mockPreview;
    late Future<Review> loadingFuture;

    setUp(() {
      mockPreview = const ReviewPreview(
        id: 'r1',
        title: 'Test Review',
        authorName: 'Test Author',
        authorAvatar: 'https://via.placeholder.com/50',
        shortText: 'This is a short review text for testing.',
        heroImage: 'https://via.placeholder.com/400',
        likeCount: 1234,
        commentCount: 56,
      );
      loadingFuture = Completer<Review>().future;
    });

    Widget buildTestWidget({ReviewPreview? preview, Future<Review>? future}) {
      return ProviderScope(
        overrides: [
          reviewByIdProvider('r1').overrideWith((ref) => future ?? loadingFuture),
        ],
        child: MaterialApp(
          home: ReviewDetailScreen(reviewId: 'r1', reviewPreview: preview),
        ),
      );
    }

    testWidgets('shows preview-based back button while loading', (tester) async {
      await tester.pumpWidget(buildTestWidget(preview: mockPreview));
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows CTA button text in preview mode', (tester) async {
      await tester.pumpWidget(buildTestWidget(preview: mockPreview));
      await tester.pump();

      expect(find.text('Thêm vào Trip'), findsOneWidget);
    });

    testWidgets('uses CustomScrollView structure in preview mode', (tester) async {
      await tester.pumpWidget(buildTestWidget(preview: mockPreview));
      await tester.pump();

      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('uses SliverAppBar for the hero header', (tester) async {
      await tester.pumpWidget(buildTestWidget(preview: mockPreview));
      await tester.pump();

      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('shows loading skeleton when preview is not provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(preview: null));
      await tester.pump();

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SliverAppBar), findsOneWidget);
    });
  });
}
