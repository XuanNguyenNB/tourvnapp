import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'auto_plan_service.dart';

/// Service connecting to Google Gemini API (model gemini-3-flash-preview)
/// to generate engaging texts (titles, themes, descriptions) for an AutoPlanResult.
class LlmEnrichmentService {
  static const String _defaultEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';

  final String apiKey;
  final String endpoint;

  const LlmEnrichmentService({
    required this.apiKey,
    this.endpoint = _defaultEndpoint,
  });

  /// Takes a raw computer-generated [AutoPlanResult] and asks Gemini to
  /// write a catchy trip title, an overall description, and themes/descriptions
  /// for each day.
  ///
  /// Returns a new [AutoPlanResult] with the nullable text fields populated.
  Future<AutoPlanResult> enrich(AutoPlanResult rawResult) async {
    try {
      final prompt = _buildPrompt(rawResult);
      log(
        'LlmEnrichmentService: Sending prompt to Gemini...',
        name: 'LlmEnrichment',
      );

      final payload = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        // Ask Gemini to strictly return JSON
        'generationConfig': {'responseMimeType': 'application/json'},
      };

      final uri = Uri.parse('$endpoint?key=$apiKey');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        log(
          'LlmEnrichmentService: Failed. HTTP ${response.statusCode} - ${response.body}',
          name: 'LlmEnrichment',
          level: 900,
        );
        return rawResult; // Return raw if failed
      }

      final data = jsonDecode(response.body);
      final jsonResponseString =
          data['candidates']?[0]['content']?['parts']?[0]['text'];

      if (jsonResponseString == null) {
        log(
          'LlmEnrichmentService: Could not find text in response',
          name: 'LlmEnrichment',
          level: 900,
        );
        return rawResult;
      }

      final parsed = jsonDecode(jsonResponseString) as Map<String, dynamic>;
      return _applyLlmData(rawResult, parsed);
    } catch (e, st) {
      log(
        'LlmEnrichmentService Error: $e',
        name: 'LlmEnrichment',
        error: e,
        stackTrace: st,
        level: 1000,
      );
      return rawResult;
    }
  }

  /// Convert the raw result to a compact JSON-like string to feed into LLM.
  String _buildPrompt(AutoPlanResult result) {
    final destId = result.request.destinationId;
    final pace = result.request.pace.name;
    final group = result.request.groupType?.name ?? 'unknown';

    final buffer = StringBuffer();
    buffer.writeln('Act as an expert local Vietnamese tour guide.');
    buffer.writeln(
      'I am providing you a machine-generated trip itinerary for a Destination (ID: $destId).',
    );
    buffer.writeln(
      'The user is traveling in a "$pace" pace with group type "$group".',
    );
    buffer.writeln('The itinerary follows a realistic travel flow:');
    buffer.writeln(
      '  - Day 1: Arrive → Check-in hotel/gửi đồ → Ăn trưa → Tham quan → Ăn tối → Về phòng.',
    );
    buffer.writeln(
      '  - Middle days: Ăn sáng → Tham quan → Ăn trưa → Tham quan tiếp → Ăn tối → Đi chơi tối → Về phòng.',
    );
    buffer.writeln('  - Last day: Checkout → Ăn sáng → Tham quan → Về.');
    buffer.writeln(
      'Please write a VERY catchy title, a short overall description in Vietnamese, and for each day, write a thematic title and a brief description that follows the natural flow above.',
    );
    buffer.writeln(
      'Also, provide a short 1-line description for what to do at each stop. For hotels, mention checking in/dropping luggage. For restaurants, describe the signature dish.',
    );
    buffer.writeln();
    buffer.writeln('Here is the raw itinerary:');

    for (final day in result.days) {
      buffer.writeln('Day ${day.dayIndex + 1}:');
      for (final stop in day.stops) {
        final loc = stop.location;
        buffer.writeln(
          ' - Stop: ${loc.name} (${loc.category}). Time: ${stop.startTimeLabel} to ${stop.endTimeLabel}.',
        );
        if (stop.reasons.isNotEmpty) {
          buffer.writeln('   Why: ${stop.reasons.join(", ")}');
        }
      }
    }

    buffer.writeln();
    buffer.writeln('''
You MUST return ONLY a raw JSON object matching this EXACt schema, with NO markdown formatting wraps like ```json:
{
  "tripTitle": "Catchy Vietnamese title (e.g. 3 Ngày Khám Phá Đà Nẵng Rực Rỡ)",
  "tripDescription": "2-3 sentences overview of the trip in Vietnamese.",
  "days": [
    {
      "dayIndex": 0,
      "dayTheme": "Theme for day 1 (e.g. Ngày 1: Hành trình di sản)",
      "dayDescription": "1-2 sentences about today.",
      "stops": [
        {
          "locationName": "Match the exact name provided in the raw itinerary",
          "aiDescription": "1 short sentence describing what to do here."
        }
      ]
    }
  ]
}
''');

    return buffer.toString();
  }

  /// Appends the parsed Map back into a new [AutoPlanResult]
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
      // Find matching day in LLM input by dayIndex
      final matchedLlmDay = llmDays.firstWhere(
        (d) => d['dayIndex'] == rawDay.dayIndex,
        orElse: () => <String, dynamic>{}, // empty map
      );

      final llmStops =
          (matchedLlmDay['stops'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      final newStops = <AutoPlanStop>[];
      for (final rawStop in rawDay.stops) {
        // Find matching stop by name
        final matchedLlmStop = llmStops.firstWhere(
          (s) => s['locationName'] == rawStop.location.name,
          orElse: () => <String, dynamic>{},
        );

        final aiDesc = matchedLlmStop['aiDescription'] as String?;

        if (aiDesc != null && aiDesc.isNotEmpty) {
          newStops.add(rawStop.copyWith(aiDescription: aiDesc));
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
