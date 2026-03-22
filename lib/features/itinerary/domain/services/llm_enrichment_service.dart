import 'dart:developer';

import '../../../../core/services/ai_backend_service.dart';
import 'auto_plan_service.dart';

/// Service that asks the backend AI layer to enrich an AutoPlanResult.
class LlmEnrichmentService {
  const LlmEnrichmentService({required AiBackendService backendService})
    : _backendService = backendService;

  final AiBackendService _backendService;

  /// Takes a raw computer-generated [AutoPlanResult] and asks the backend AI
  /// layer to write a title, overview, and descriptions for each day/stop.
  Future<AutoPlanResult> enrich(AutoPlanResult rawResult) async {
    try {
      final prompt = _buildPrompt(rawResult);
      log(
        'LlmEnrichmentService: Sending prompt to backend AI...',
        name: 'LlmEnrichment',
      );

      final parsed = await _backendService.enrichAutoPlan(prompt: prompt);
      return _applyLlmData(rawResult, parsed);
    } catch (error, stackTrace) {
      log(
        'LlmEnrichmentService Error: $error',
        name: 'LlmEnrichment',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      return rawResult;
    }
  }

  /// Convert the raw result to a compact prompt for the backend AI layer.
  String _buildPrompt(AutoPlanResult result) {
    final destId = result.request.destinationId;
    final pace = result.request.pace.name;
    final group = result.request.groupType.name;

    final buffer = StringBuffer();
    buffer.writeln('Act as an expert local Vietnamese tour guide.');
    buffer.writeln(
      'I am providing you a machine-generated trip itinerary for a destination (ID: $destId).',
    );
    buffer.writeln(
      'The user is traveling in a "$pace" pace with group type "$group".',
    );
    buffer.writeln('The itinerary follows a realistic travel flow:');
    buffer.writeln(
      '  - Day 1: Arrive, check in hotel, lunch, sightseeing, dinner, return to room.',
    );
    buffer.writeln(
      '  - Middle days: Breakfast, sightseeing, lunch, more sightseeing, dinner, evening outing, return to room.',
    );
    buffer.writeln('  - Last day: Checkout, breakfast, sightseeing, return.');
    buffer.writeln(
      'Please write a catchy Vietnamese title, a short overall description, and for each day a theme plus a short description.',
    );
    buffer.writeln(
      'Also provide a one-line description for each stop. For hotels mention check-in or luggage drop. For restaurants mention a signature dish when appropriate.',
    );
    buffer.writeln();
    buffer.writeln('Here is the raw itinerary:');

    for (final day in result.days) {
      buffer.writeln('Day ${day.dayIndex + 1}:');
      for (final stop in day.stops) {
        final location = stop.location;
        buffer.writeln(
          ' - Stop: ${location.name} (${location.category}). Time: ${stop.startTimeLabel} to ${stop.endTimeLabel}.',
        );
        if (stop.reasons.isNotEmpty) {
          buffer.writeln('   Why: ${stop.reasons.join(", ")}');
        }
      }
    }

    buffer.writeln();
    buffer.writeln('''
You MUST return ONLY a raw JSON object matching this EXACT schema, with NO markdown fences:
{
  "tripTitle": "Catchy Vietnamese title",
  "tripDescription": "2-3 sentence overview in Vietnamese.",
  "days": [
    {
      "dayIndex": 0,
      "dayTheme": "Theme for day 1",
      "dayDescription": "1-2 sentences about the day.",
      "stops": [
        {
          "locationName": "Match the exact name from the raw itinerary",
          "aiDescription": "1 short sentence describing what to do here."
        }
      ]
    }
  ]
}
''');

    return buffer.toString();
  }

  AutoPlanResult _applyLlmData(
    AutoPlanResult raw,
    Map<String, dynamic> llmData,
  ) {
    final tripTitle = llmData['tripTitle'] as String?;
    final tripDesc = llmData['tripDescription'] as String?;

    final newDays = <AutoPlanDay>[];
    final llmDays =
        (llmData['days'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    for (final rawDay in raw.days) {
      final matchedLlmDay = llmDays.firstWhere(
        (day) => day['dayIndex'] == rawDay.dayIndex,
        orElse: () => <String, dynamic>{},
      );

      final llmStops =
          (matchedLlmDay['stops'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      final newStops = <AutoPlanStop>[];
      for (final rawStop in rawDay.stops) {
        final matchedLlmStop = llmStops.firstWhere(
          (stop) => stop['locationName'] == rawStop.location.name,
          orElse: () => <String, dynamic>{},
        );

        final aiDescription = matchedLlmStop['aiDescription'] as String?;
        if (aiDescription != null && aiDescription.isNotEmpty) {
          newStops.add(rawStop.copyWith(aiDescription: aiDescription));
        } else {
          newStops.add(rawStop);
        }
      }

      newDays.add(
        rawDay.copyWith(
          stops: newStops,
          dayTheme: matchedLlmDay['dayTheme'] as String?,
          dayDescription: matchedLlmDay['dayDescription'] as String?,
        ),
      );
    }

    return raw.copyWith(
      days: newDays,
      tripTitle: tripTitle,
      tripDescription: tripDesc,
    );
  }
}
