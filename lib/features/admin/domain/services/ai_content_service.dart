import '../../../../core/services/ai_backend_service.dart';

/// Thin client wrapper around backend AI generation endpoints.
class AiContentService {
  const AiContentService({required AiBackendService backendService})
    : _backendService = backendService;

  final AiBackendService _backendService;

  /// Article styles supported by the AI writer.
  static const List<String> articleStyles = [
    'review',
    'guide',
    'top-list',
    'tips',
  ];

  Future<Map<String, dynamic>> generateDestination(String prompt) {
    return _backendService.generateDestination(prompt: prompt);
  }

  Future<List<Map<String, dynamic>>> generateLocations({
    required String destinationId,
    required String destinationName,
    required String prompt,
    int count = 5,
  }) {
    return _backendService.generateLocations(
      destinationId: destinationId,
      destinationName: destinationName,
      prompt: prompt,
      count: count,
    );
  }

  Future<Map<String, dynamic>> generateReview({
    required String prompt,
    String? destinationId,
    String? destinationName,
    List<Map<String, dynamic>>? existingLocations,
    String articleStyle = 'review',
  }) {
    return _backendService.generateReview(
      prompt: prompt,
      destinationId: destinationId,
      destinationName: destinationName,
      existingLocations: existingLocations,
      articleStyle: articleStyle,
    );
  }

  Future<List<Map<String, dynamic>>> generateMultipleReviews({
    required String prompt,
    required String destinationName,
    required String destinationId,
    required List<Map<String, dynamic>> existingLocations,
    String articleStyle = 'review',
    int count = 3,
  }) {
    return _backendService.generateMultipleReviews(
      prompt: prompt,
      destinationName: destinationName,
      destinationId: destinationId,
      existingLocations: existingLocations,
      articleStyle: articleStyle,
      count: count,
    );
  }
}
