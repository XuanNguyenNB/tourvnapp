import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_runtime_config.dart';
import '../providers/firebase_providers.dart';

class AiBackendHealth {
  const AiBackendHealth({
    required this.status,
    this.model,
    this.upstream,
    this.message,
  });

  final String status;
  final String? model;
  final String? upstream;
  final String? message;

  bool get isOnline {
    final normalized = status.trim().toLowerCase();
    return normalized == 'ok' || normalized == 'online';
  }

  factory AiBackendHealth.fromJson(Map<String, dynamic> json) {
    return AiBackendHealth(
      status: (json['status'] as String?)?.trim().isNotEmpty == true
          ? (json['status'] as String).trim()
          : 'unknown',
      model: (json['model'] as String?)?.trim(),
      upstream: (json['upstream'] as String?)?.trim(),
      message: (json['message'] as String?)?.trim(),
    );
  }

  factory AiBackendHealth.offline([String? message]) {
    return AiBackendHealth(status: 'offline', message: message?.trim());
  }
}

class AiBackendService {
  AiBackendService({
    required FirebaseAuth auth,
    http.Client? client,
    String? baseUrl,
  }) : _auth = auth,
       _client = client ?? http.Client(),
       _baseUrl = _normalizeBaseUrl(
         baseUrl ?? AppRuntimeConfig.aiBackendBaseUrl,
       );

  final FirebaseAuth _auth;
  final http.Client _client;
  final String? _baseUrl;

  bool get isConfigured => _baseUrl != null;

  Future<AiBackendHealth?> getHealth() async {
    final baseUrl = _baseUrl;
    if (baseUrl == null) {
      return AiBackendHealth.offline(_missingBackendMessage);
    }

    final uri = Uri.parse('$baseUrl/').resolve('health');
    final headers = await _buildHeaders();

    http.Response response;
    try {
      response = await _client.get(uri, headers: headers);
    } on http.ClientException catch (error) {
      return AiBackendHealth.offline(
        'Không thể kết nối đến AI backend: $error',
      );
    } catch (error) {
      return AiBackendHealth.offline('Lỗi mạng khi gọi AI backend: $error');
    }

    if (response.statusCode == 404 || response.statusCode == 405) {
      return null;
    }

    final decodedBody = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return AiBackendHealth.offline(
        _extractErrorMessage(decodedBody, response.statusCode),
      );
    }

    if (decodedBody is Map<String, dynamic>) {
      return AiBackendHealth.fromJson(decodedBody);
    }

    if (decodedBody is Map) {
      return AiBackendHealth.fromJson(
        decodedBody.map(
          (key, dynamic value) => MapEntry(key.toString(), value),
        ),
      );
    }

    return const AiBackendHealth(status: 'unknown');
  }

  Future<Map<String, dynamic>> generateDestination({
    required String prompt,
  }) async {
    final data = await _postJson(
      endpoint: 'generateDestinationDraft',
      payload: {'prompt': prompt},
    );
    return _expectMap(data, endpoint: 'generateDestinationDraft');
  }

  Future<List<Map<String, dynamic>>> generateLocations({
    required String destinationId,
    required String destinationName,
    required String prompt,
    int count = 5,
  }) async {
    final data = await _postJson(
      endpoint: 'generateLocationDrafts',
      payload: {
        'destinationId': destinationId,
        'destinationName': destinationName,
        'prompt': prompt,
        'count': count,
      },
    );
    return _expectList(data, endpoint: 'generateLocationDrafts');
  }

  Future<Map<String, dynamic>> generateReview({
    required String prompt,
    String? destinationId,
    String? destinationName,
    List<Map<String, dynamic>>? existingLocations,
    String articleStyle = 'review',
  }) async {
    final data = await _postJson(
      endpoint: 'generateReviewDraft',
      payload: {
        'prompt': prompt,
        'destinationId': destinationId,
        'destinationName': destinationName,
        'existingLocations': existingLocations ?? const [],
        'articleStyle': articleStyle,
      },
    );
    return _expectMap(data, endpoint: 'generateReviewDraft');
  }

  Future<List<Map<String, dynamic>>> generateMultipleReviews({
    required String prompt,
    required String destinationName,
    required String destinationId,
    required List<Map<String, dynamic>> existingLocations,
    String articleStyle = 'review',
    int count = 3,
  }) async {
    final data = await _postJson(
      endpoint: 'generateReviewDrafts',
      payload: {
        'prompt': prompt,
        'destinationName': destinationName,
        'destinationId': destinationId,
        'existingLocations': existingLocations,
        'articleStyle': articleStyle,
        'count': count,
      },
    );
    return _expectList(data, endpoint: 'generateReviewDrafts');
  }

  Future<Map<String, dynamic>> expandReviewDraft({
    required Map<String, dynamic> draftReview,
    required List<Map<String, dynamic>> existingLocations,
    String? prompt,
    String? destinationId,
    String? destinationName,
    String articleStyle = 'review',
  }) async {
    final data = await _postJson(
      endpoint: 'expandReviewDraft',
      payload: {
        'draftReview': draftReview,
        'existingLocations': existingLocations,
        'prompt': prompt,
        'destinationId': destinationId,
        'destinationName': destinationName,
        'articleStyle': articleStyle,
      },
    );
    return _expectMap(data, endpoint: 'expandReviewDraft');
  }

  Future<Map<String, dynamic>> enrichAutoPlan({required String prompt}) async {
    final data = await _postJson(
      endpoint: 'enrichAutoPlan',
      payload: {'prompt': prompt},
    );
    return _expectMap(data, endpoint: 'enrichAutoPlan');
  }

  Future<String> generateStopTip({
    required String locationName,
    required String category,
    required String startTimeLabel,
    required String endTimeLabel,
    required int durationMin,
  }) async {
    final data = await _postJson(
      endpoint: 'generateStopTip',
      payload: {
        'locationName': locationName,
        'category': category,
        'startTimeLabel': startTimeLabel,
        'endTimeLabel': endTimeLabel,
        'durationMin': durationMin,
      },
    );

    if (data is String) {
      return data.trim();
    }

    if (data is Map<String, dynamic>) {
      final text = data['text'];
      if (text is String && text.trim().isNotEmpty) {
        return text.trim();
      }
    }

    throw Exception(
      'AI backend trả về dữ liệu không hợp lệ cho generateStopTip.',
    );
  }

  Future<dynamic> _postJson({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    final baseUrl = _baseUrl;
    if (baseUrl == null) {
      throw Exception(_missingBackendMessage);
    }

    final uri = Uri.parse('$baseUrl/').resolve(endpoint);
    final headers = await _buildHeaders();
    headers['Content-Type'] = 'application/json';

    http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(payload),
      );
    } on http.ClientException catch (error) {
      throw Exception('Không thể kết nối đến AI backend: $error');
    } catch (error) {
      throw Exception('Lỗi mạng khi gọi AI backend: $error');
    }

    final decodedBody = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(decodedBody, response.statusCode));
    }

    if (decodedBody is Map<String, dynamic> &&
        decodedBody.containsKey('data')) {
      return decodedBody['data'];
    }

    return decodedBody;
  }

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{'Accept': 'application/json, text/plain'};

    final idToken = await _auth.currentUser?.getIdToken();
    if (idToken != null && idToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $idToken';
    }

    return headers;
  }

  dynamic _decodeBody(http.Response response) {
    final raw = utf8.decode(response.bodyBytes).trim();
    if (raw.isEmpty) return null;

    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('application/json')) {
      return jsonDecode(raw);
    }

    if (raw.startsWith('{') || raw.startsWith('[') || raw.startsWith('"')) {
      try {
        return jsonDecode(raw);
      } catch (_) {
        return raw;
      }
    }

    return raw;
  }

  String _extractErrorMessage(dynamic decodedBody, int statusCode) {
    if (decodedBody is Map<String, dynamic>) {
      final directMessage = decodedBody['message'];
      if (directMessage is String && directMessage.trim().isNotEmpty) {
        return directMessage.trim();
      }

      final error = decodedBody['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error.trim();
      }

      if (error is Map<String, dynamic>) {
        final nestedMessage = error['message'];
        if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
          return nestedMessage.trim();
        }
      }
    }

    if (decodedBody is String && decodedBody.trim().isNotEmpty) {
      return decodedBody.trim();
    }

    return 'AI backend trả về lỗi HTTP $statusCode.';
  }

  Map<String, dynamic> _expectMap(dynamic value, {required String endpoint}) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, dynamic item) => MapEntry(key.toString(), item));
    }

    throw Exception('AI backend trả về dữ liệu không hợp lệ cho $endpoint.');
  }

  List<Map<String, dynamic>> _expectList(
    dynamic value, {
    required String endpoint,
  }) {
    if (value is! List) {
      throw Exception('AI backend trả về dữ liệu không hợp lệ cho $endpoint.');
    }

    return value.map((item) {
      if (item is Map<String, dynamic>) {
        return item;
      }
      if (item is Map) {
        return item.map(
          (key, dynamic nestedValue) => MapEntry(key.toString(), nestedValue),
        );
      }
      throw Exception(
        'AI backend trả về danh sách không hợp lệ cho $endpoint.',
      );
    }).toList();
  }

  static String? _normalizeBaseUrl(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  static const String _missingBackendMessage =
      'Tính năng AI đã được tách khỏi Firebase. '
      'Hãy cấu hình --dart-define=AI_BACKEND_BASE_URL=https://your-ai-host '
      'để sử dụng lại các tính năng AI.';
}

final aiBackendConfiguredProvider = Provider<bool>((_) {
  return AppRuntimeConfig.hasAiBackend;
});

final aiBackendServiceProvider = Provider<AiBackendService>((ref) {
  return AiBackendService(auth: ref.watch(firebaseAuthProvider));
});

final aiBackendHealthProvider = FutureProvider<AiBackendHealth?>((ref) async {
  return ref.watch(aiBackendServiceProvider).getHealth();
});
