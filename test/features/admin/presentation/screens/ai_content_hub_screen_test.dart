import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/core/services/ai_backend_service.dart';
import 'package:tour_vn/features/admin/presentation/providers/admin_ai_content_provider.dart';
import 'package:tour_vn/features/admin/presentation/providers/admin_reference_data_provider.dart';
import 'package:tour_vn/features/admin/presentation/screens/ai_content_hub_screen.dart';
import 'package:tour_vn/features/destination/domain/entities/destination.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';
import 'package:tour_vn/features/review/domain/entities/review.dart';

class _FakeAiContentNotifier extends AiContentNotifier {
  _FakeAiContentNotifier(this._state);

  final AiContentState _state;
  var reviewGenerateCallCount = 0;
  var reviewGenerateManyCallCount = 0;

  @override
  AiContentState build() => _state;

  @override
  Future<void> generateReview({
    required String prompt,
    String? destinationId,
    String? destinationName,
    String articleStyle = 'review',
    Set<String> focusLocationIds = const {},
  }) async {
    reviewGenerateCallCount += 1;
  }

  @override
  Future<void> generateMultipleReviews({
    required String prompt,
    required String destinationId,
    required String destinationName,
    String articleStyle = 'review',
    Set<String> focusLocationIds = const {},
    int count = 3,
  }) async {
    reviewGenerateManyCallCount += 1;
  }
}

void _runValidationTests(
  Destination destination,
  Location location,
) {
  testWidgets('chặn tạo bài viết AI khi chưa chọn điểm đến', (tester) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final notifier = _FakeAiContentNotifier(const AiContentState());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiBackendHealthProvider.overrideWith(
            (_) async => const AiBackendHealth(
              status: 'ok',
              model: 'sonar:sonar-pro',
              upstream: 'https://api.perplexity.ai',
            ),
          ),
          aiContentNotifierProvider.overrideWith(() => notifier),
          adminDestinationLookupProvider.overrideWith((_) async => [destination]),
          adminLocationLookupProvider.overrideWith((_) async => [location]),
          pendingDestinationsProvider.overrideWith((_) async => const []),
          pendingLocationsProvider.overrideWith((_) async => const []),
          pendingDraftReviewsProvider.overrideWith((_) async => const []),
          pendingPreviewReviewsProvider.overrideWith((_) async => const []),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1280, 900)),
            child: const AiContentHubScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bài viết'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'Viết một bài review ngắn, nhiều thông tin và hợp demo.',
    );
    await tester.tap(find.text('Tạo bằng AI'));
    await tester.pump();

    expect(
      find.text('Vui lòng chọn điểm đến trước khi tạo bài viết AI'),
      findsOneWidget,
    );
    expect(notifier.reviewGenerateCallCount, 0);
    expect(notifier.reviewGenerateManyCallCount, 0);
  });
}

void main() {
  final destination = Destination(
    id: 'da-nang',
    name: 'Đà Nẵng',
    heroImage: 'https://example.com/hero.jpg',
    description: 'Điểm đến biển nổi bật',
    status: 'published',
  );

  final location = Location(
    id: 'loc-1',
    destinationId: 'da-nang',
    destinationName: 'Đà Nẵng',
    name: 'Cầu Rồng',
    image: 'https://example.com/location.jpg',
    category: 'places',
    status: 'draft_ai',
  );

  final previewReview = Review(
    id: 'review-2',
    heroImage: 'https://example.com/review-preview.jpg',
    title: 'Top trai nghiem cuoi tuan o Da Nang',
    authorId: 'ai',
    authorName: 'AI Writer',
    authorAvatar: 'https://example.com/avatar.jpg',
    fullText: '## Mo dau\nBan preview hoan chinh de kiem tra giao dien.',
    createdAt: DateTime(2026, 4, 8),
    likeCount: 0,
    commentCount: 0,
    saveCount: 0,
    destinationId: 'da-nang',
    destinationName: 'Đà Nẵng',
    status: 'preview_ai',
    aiSummary: 'Bai preview hoan chinh voi phan tom tat ngan.',
  );

  final review = Review(
    id: 'review-1',
    heroImage: 'https://example.com/review.jpg',
    title: 'Một ngày ở Đà Nẵng',
    authorId: 'ai',
    authorName: 'AI Writer',
    authorAvatar: 'https://example.com/avatar.jpg',
    fullText: 'Nội dung review mẫu để chờ duyệt.',
    createdAt: DateTime(2026, 4, 8),
    likeCount: 0,
    commentCount: 0,
    saveCount: 0,
    destinationId: 'da-nang',
    destinationName: 'Đà Nẵng',
    status: 'draft_ai',
  );

  Widget createWidget({AiContentState? state}) {
    return ProviderScope(
      overrides: [
        aiBackendHealthProvider.overrideWith(
          (_) async => const AiBackendHealth(
            status: 'ok',
             model: 'sonar:sonar-pro',
             upstream: 'https://api.perplexity.ai',
          ),
        ),
        aiContentNotifierProvider.overrideWith(
          () => _FakeAiContentNotifier(
            state ??
                const AiContentState(
                  demoPackStep: DemoPackStep.reviews,
                  successMessage: 'Đã tạo 8 AI drafts',
                  highlightedLocationIds: {'loc-1'},
                  highlightedReviewIds: {'review-1'},
                ),
          ),
        ),
        adminDestinationLookupProvider.overrideWith((_) async => [destination]),
        adminLocationLookupProvider.overrideWith((_) async => [location]),
        pendingDestinationsProvider.overrideWith((_) async => [destination]),
        pendingLocationsProvider.overrideWith((_) async => [location]),
        pendingDraftReviewsProvider.overrideWith((_) async => [review]),
        pendingPreviewReviewsProvider.overrideWith(
          (_) async => [previewReview],
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1280, 900)),
          child: const AiContentHubScreen(),
        ),
      ),
    );
  }

  _runValidationTests(destination, location);

  testWidgets('hiển thị badge AI và stepper gói demo', (tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.text('Nội dung AI'), findsOneWidget);
    expect(find.text('AI online • sonar:sonar-pro'), findsOneWidget);
    expect(find.text('Đang tạo địa điểm'), findsOneWidget);
    expect(find.text('Đang tạo bài viết'), findsOneWidget);
    expect(find.text('Hoàn tất'), findsOneWidget);
  });
}
