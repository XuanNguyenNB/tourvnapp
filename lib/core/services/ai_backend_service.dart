import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/firebase_providers.dart';

class AiBackendService {
  AiBackendService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> generateDestination({
    required String prompt,
  }) async {
    final data = await _call('generateDestinationDraft', {'prompt': prompt});
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<Map<String, dynamic>>> generateLocations({
    required String destinationId,
    required String destinationName,
    required String prompt,
    int count = 5,
  }) async {
    final data = await _call('generateLocationDrafts', {
      'destinationId': destinationId,
      'destinationName': destinationName,
      'prompt': prompt,
      'count': count,
    });

    final list = data as List<dynamic>;
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> generateReview({
    required String prompt,
    String? destinationId,
    String? destinationName,
    List<Map<String, dynamic>>? existingLocations,
    String articleStyle = 'review',
  }) async {
    final data = await _call('generateReviewDraft', {
      'prompt': prompt,
      'destinationId': destinationId,
      'destinationName': destinationName,
      'existingLocations': existingLocations ?? const [],
      'articleStyle': articleStyle,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<Map<String, dynamic>>> generateMultipleReviews({
    required String destinationName,
    required String destinationId,
    required List<Map<String, dynamic>> existingLocations,
    int count = 3,
  }) async {
    final data = await _call('generateReviewDrafts', {
      'destinationName': destinationName,
      'destinationId': destinationId,
      'existingLocations': existingLocations,
      'count': count,
    });

    final list = data as List<dynamic>;
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> enrichAutoPlan({required String prompt}) async {
    final data = await _call('enrichAutoPlan', {'prompt': prompt});
    return Map<String, dynamic>.from(data as Map);
  }

  Future<String> generateStopTip({
    required String locationName,
    required String category,
    required String startTimeLabel,
    required String endTimeLabel,
    required int durationMin,
  }) async {
    final data = await _call('generateStopTip', {
      'locationName': locationName,
      'category': category,
      'startTimeLabel': startTimeLabel,
      'endTimeLabel': endTimeLabel,
      'durationMin': durationMin,
    });
    return data as String;
  }

  Future<dynamic> _call(String functionName, Map<String, dynamic> data) async {
    try {
      final callable = _functions.httpsCallable(functionName);
      final result = await callable.call<dynamic>(data);
      return result.data;
    } on FirebaseFunctionsException catch (error) {
      throw Exception(_friendlyErrorMessage(error));
    } catch (error) {
      throw Exception('Khong the ket noi den dich vu AI: $error');
    }
  }

  String _friendlyErrorMessage(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'resource-exhausted':
        return 'Dich vu AI tam thoi het quota. Vui long thu lai sau it phut.';
      case 'permission-denied':
        return 'Ban khong co quyen su dung tinh nang AI nay.';
      case 'unauthenticated':
        return 'Can dang nhap de su dung tinh nang AI.';
      case 'invalid-argument':
        return error.message ?? 'Yeu cau AI khong hop le.';
      case 'deadline-exceeded':
      case 'unavailable':
        return 'Dich vu AI dang cham hoac tam thoi khong san sang. Vui long thu lai.';
      default:
        return error.message ?? 'Khong the tao noi dung AI luc nay.';
    }
  }
}

final aiBackendServiceProvider = Provider<AiBackendService>((ref) {
  return AiBackendService(functions: ref.watch(firebaseFunctionsProvider));
});
