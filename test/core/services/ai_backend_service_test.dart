import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tour_vn/core/services/ai_backend_service.dart';

class _MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}

class _MockFirebaseUser extends Mock implements firebase_auth.User {}

void main() {
  group('AiBackendService.getHealth', () {
    late _MockFirebaseAuth auth;
    late _MockFirebaseUser user;

    setUp(() {
      auth = _MockFirebaseAuth();
      user = _MockFirebaseUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.getIdToken()).thenAnswer((_) async => 'demo-token');
    });

    test('parse đúng response /health', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'https://ai.example.com/health');
        expect(request.headers['Authorization'], 'Bearer demo-token');
        return http.Response(
          jsonEncode({
            'status': 'ok',
            'model': 'gemini-3-flash',
            'upstream': 'CLIProxyAPI',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AiBackendService(
        auth: auth,
        client: client,
        baseUrl: 'https://ai.example.com',
      );

      final health = await service.getHealth();

      expect(health, isNotNull);
      expect(health!.isOnline, isTrue);
      expect(health.status, 'ok');
      expect(health.model, 'gemini-3-flash');
      expect(health.upstream, 'CLIProxyAPI');
    });

    test('trả trạng thái offline khi chưa cấu hình backend', () async {
      when(() => auth.currentUser).thenReturn(null);

      final service = AiBackendService(
        auth: auth,
        client: MockClient((_) async {
          fail('Không nên gọi HTTP khi chưa có base URL');
        }),
        baseUrl: '',
      );

      final health = await service.getHealth();

      expect(health, isNotNull);
      expect(health!.isOnline, isFalse);
      expect(health.message, contains('AI_BACKEND_BASE_URL'));
    });
  });
  group('AiBackendService.expandReviewDraft', () {
    late _MockFirebaseAuth auth;
    late _MockFirebaseUser user;

    setUp(() {
      auth = _MockFirebaseAuth();
      user = _MockFirebaseUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.getIdToken()).thenAnswer((_) async => 'demo-token');
    });

    test('gọi đúng endpoint expandReviewDraft và parse map kết quả', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://ai.example.com/expandReviewDraft',
        );
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer demo-token');

        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['draftReview']['id'], 'review-1');
        expect(payload['existingLocations'], isNotEmpty);

        return http.Response(
          jsonEncode({
            'data': {
              'id': 'review-1',
              'status': 'preview_ai',
              'title': 'Bài preview hoàn chỉnh',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AiBackendService(
        auth: auth,
        client: client,
        baseUrl: 'https://ai.example.com',
      );

      final result = await service.expandReviewDraft(
        draftReview: const {'id': 'review-1', 'title': 'Bản nháp'},
        existingLocations: const [
          {
            'id': 'loc-1',
            'name': 'Cầu Rồng',
            'category': 'places',
            'tags': ['check-in'],
          },
        ],
      );

      expect(result['id'], 'review-1');
      expect(result['status'], 'preview_ai');
      expect(result['title'], 'Bài preview hoàn chỉnh');
    });
  });
}
