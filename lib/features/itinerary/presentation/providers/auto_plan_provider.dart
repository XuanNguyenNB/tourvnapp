import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/models/auto_plan_request.dart';
import '../../domain/services/auto_plan_service.dart';
import '../../domain/services/llm_enrichment_service.dart';
import '../../../destination/presentation/providers/location_provider.dart';
import '../../../recommendation/data/repositories/user_profile_repository.dart';
import '../../../recommendation/data/repositories/user_event_repository.dart';
import '../../../recommendation/domain/entities/user_profile.dart';

// ──── Service Provider ────

/// Provider for AutoPlanService (stateless singleton).
final autoPlanServiceProvider = Provider<AutoPlanService>((ref) {
  return const AutoPlanService();
});

/// Provider for LlmEnrichmentService
final llmEnrichmentServiceProvider = Provider<LlmEnrichmentService>((ref) {
  return const LlmEnrichmentService(apiKey: AppConfig.geminiApiKey);
});

// ──── State ────

/// State class for auto plan generation.
class AutoPlanState {
  final bool isGenerating;
  final bool isEnriching;
  final AutoPlanResult? result;
  final String? errorMessage;

  const AutoPlanState({
    this.isGenerating = false,
    this.isEnriching = false,
    this.result,
    this.errorMessage,
  });

  AutoPlanState copyWith({
    bool? isGenerating,
    bool? isEnriching,
    AutoPlanResult? result,
    String? errorMessage,
  }) {
    return AutoPlanState(
      isGenerating: isGenerating ?? this.isGenerating,
      isEnriching: isEnriching ?? this.isEnriching,
      result: result ?? this.result,
      errorMessage: errorMessage,
    );
  }
}

// ──── Notifier ────

/// Orchestrator for the "AI Lập Kế Hoạch Tự Động" flow.
///
/// 1. Loads locations for destination
/// 2. Loads user profile + behavior signals (if available)
/// 3. Calls [AutoPlanService.plan] to produce [AutoPlanResult]
/// 4. Exposes result for UI preview + "Áp dụng" into PendingTrip
class AutoPlanNotifier extends Notifier<AutoPlanState> {
  @override
  AutoPlanState build() => const AutoPlanState();

  /// Generate an AI plan with the given request.
  Future<void> generate(AutoPlanRequest request) async {
    state = const AutoPlanState(isGenerating: true);

    try {
      // 1. Load all locations for the destination.
      final locations = await ref.read(
        locationsForDestinationProvider(request.destinationId).future,
      );

      if (locations.isEmpty) {
        state = const AutoPlanState(
          errorMessage: 'Không tìm thấy địa điểm nào cho điểm đến này',
        );
        return;
      }

      // 2. Load user context (profile + behavior signals).
      final user = FirebaseAuth.instance.currentUser;

      UserProfile? profile;
      Map<String, double> catInterests = {};
      Map<String, double> tagInterests = {};
      Set<String> interacted = {};

      if (user != null && !user.isAnonymous && request.useBehaviorSignals) {
        final profileRepo = ref.read(userProfileRepositoryProvider);
        final eventRepo = ref.read(userEventRepositoryProvider);

        profile = await profileRepo.getProfile(user.uid);
        catInterests = await eventRepo.computeCategoryInterests(user.uid);
        tagInterests = await eventRepo.computeTagInterests(user.uid);
        interacted = await eventRepo.getInteractedLocationIds(user.uid);
      }

      // 3. Run the auto-plan pipeline.
      final service = ref.read(autoPlanServiceProvider);
      final rawResult = service.plan(
        request: request,
        allLocations: locations,
        profile: profile,
        categoryInterests: catInterests,
        tagInterests: tagInterests,
        interactedLocationIds: interacted,
      );

      if (rawResult.totalStops == 0) {
        state = const AutoPlanState(
          errorMessage:
              'Không đủ điểm đến có tọa độ GPS để tạo lịch trình.\n'
              'Hãy thử giảm số ngày hoặc mở rộng sở thích.',
        );
        return;
      }

      // Display raw result early while waiting for LLM
      state = AutoPlanState(result: rawResult, isEnriching: true);

      // 4. Enrich with LLM
      final enrichService = ref.read(llmEnrichmentServiceProvider);
      final enrichedResult = await enrichService.enrich(rawResult);

      state = AutoPlanState(result: enrichedResult);
    } catch (e) {
      state = AutoPlanState(errorMessage: 'Lỗi khi tạo lịch trình: $e');
    }
  }

  /// Clear result and reset state.
  void clear() {
    state = const AutoPlanState();
  }
}

// ──── Provider ────

/// Provider for auto plan generation state.
final autoPlanProvider = NotifierProvider<AutoPlanNotifier, AutoPlanState>(
  AutoPlanNotifier.new,
);
