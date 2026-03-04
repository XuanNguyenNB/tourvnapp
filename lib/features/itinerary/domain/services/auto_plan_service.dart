import 'package:flutter/foundation.dart';

import '../models/auto_plan_request.dart';
import '../models/itinerary_constraints.dart';
import '../utils/geo_utils.dart';
import 'itinerary_service.dart';

import '../../../destination/domain/entities/location.dart';
import '../../../recommendation/domain/entities/user_profile.dart';
import '../../../recommendation/domain/services/recommendation_service.dart';

import '../../../trip/domain/entities/activity.dart';
import '../../../trip/domain/entities/trip_day.dart';

String _emojiForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'food':
      return '🍜';
    case 'cafe':
      return '☕';
    case 'stay':
      return '🏨';
    case 'places':
      return '📸';
    case 'nature':
      return '🌄';
    case 'culture':
      return '🏛️';
    case 'shopping':
      return '🛍️';
    case 'nightlife':
      return '🎉';
    default:
      return '📍';
  }
}

// ─── Schedule table (cách A preview) ───────────────────────────────

@immutable
class AiScheduleRow {
  final String timeLabel;
  final List<String> dayCells;
  const AiScheduleRow({required this.timeLabel, required this.dayCells});
}

@immutable
class AiScheduleTable {
  final List<String> dayHeaders;
  final List<AiScheduleRow> rows;
  const AiScheduleTable({required this.dayHeaders, required this.rows});
}

@immutable
class AutoPlanWarning {
  final String code;
  final String message;
  const AutoPlanWarning(this.code, this.message);
}

// ─── Travel leg ────────────────────────────────────────────────────

@immutable
class TravelLeg {
  final double distanceKm;
  final int travelMinutes;

  const TravelLeg({required this.distanceKm, required this.travelMinutes});

  String get formattedDistance {
    if (distanceKm < 1) return '${(distanceKm * 1000).round()}m';
    return '${distanceKm.toStringAsFixed(1)}km';
  }

  String get formattedTravelTime {
    if (travelMinutes < 60) return '~$travelMinutes phút';
    final h = travelMinutes ~/ 60;
    final m = travelMinutes % 60;
    return m > 0 ? '~${h}h${m}p' : '~${h}h';
  }
}

// ─── AutoPlanStop ──────────────────────────────────────────────────

@immutable
class AutoPlanStop {
  final Location location;
  final String timeSlotName;
  final int startMinute;
  final int durationMin;
  final List<String> reasons;
  final TravelLeg? travelFromPrevious;
  final String? aiDescription;

  const AutoPlanStop({
    required this.location,
    required this.timeSlotName,
    required this.startMinute,
    required this.durationMin,
    this.reasons = const [],
    this.travelFromPrevious,
    this.aiDescription,
  });

  String get startTimeLabel => _minutesToLabel(startMinute);
  String get endTimeLabel => _minutesToLabel(startMinute + durationMin);

  static String _minutesToLabel(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  AutoPlanStop copyWith({String? aiDescription}) {
    return AutoPlanStop(
      location: location,
      timeSlotName: timeSlotName,
      startMinute: startMinute,
      durationMin: durationMin,
      reasons: reasons,
      travelFromPrevious: travelFromPrevious,
      aiDescription: aiDescription ?? this.aiDescription,
    );
  }
}

// ─── AutoPlanDay ───────────────────────────────────────────────────

@immutable
class AutoPlanDay {
  final int dayIndex;
  final List<AutoPlanStop> stops;
  final String? dayTheme;
  final String? dayDescription;

  const AutoPlanDay({
    required this.dayIndex,
    required this.stops,
    this.dayTheme,
    this.dayDescription,
  });

  AutoPlanDay copyWith({
    List<AutoPlanStop>? stops,
    String? dayTheme,
    String? dayDescription,
  }) {
    return AutoPlanDay(
      dayIndex: dayIndex,
      stops: stops ?? this.stops,
      dayTheme: dayTheme ?? this.dayTheme,
      dayDescription: dayDescription ?? this.dayDescription,
    );
  }
}

// ─── AutoPlanResult ────────────────────────────────────────────────

@immutable
class AutoPlanResult {
  final AutoPlanRequest request;
  final List<AutoPlanDay> days;

  /// Preview dạng bảng giờ cố định (08:00 / 11:00 / 13-17 / 18:00 / 19:00+).
  final AiScheduleTable table;

  final List<AutoPlanWarning> warnings;

  /// Populated by LlmEnrichmentService after initial generation.
  final String? tripTitle;
  final String? tripDescription;

  const AutoPlanResult({
    required this.request,
    required this.days,
    required this.table,
    this.warnings = const [],
    this.tripTitle,
    this.tripDescription,
  });

  int get totalStops => days.fold<int>(0, (sum, d) => sum + d.stops.length);

  int get totalTravelTimeMin {
    int total = 0;
    for (final day in days) {
      for (final stop in day.stops) {
        total += stop.travelFromPrevious?.travelMinutes ?? 0;
      }
    }
    return total;
  }

  /// Convert to TripDay/Activity list for PendingTrip or Firestore save.
  List<TripDay> toTripDays() {
    return days.map((day) {
      final activities = day.stops.asMap().entries.map((e) {
        final stop = e.value;
        return Activity(
          id: '${day.dayIndex}_${e.key}_${stop.location.id}',
          locationId: stop.location.id,
          locationName: stop.location.name,
          emoji: _emojiForCategory(stop.location.category),
          imageUrl: stop.location.image,
          timeSlot: stop.timeSlotName,
          sortOrder: e.key,
          estimatedDurationMin: stop.durationMin,
          estimatedDuration: _durationLabel(stop.durationMin),
          destinationId: stop.location.destinationId,
          destinationName: stop.location.resolvedDestinationName,
        );
      }).toList();

      return TripDay(dayNumber: day.dayIndex + 1, activities: activities);
    }).toList();
  }

  AutoPlanResult copyWith({
    List<AutoPlanDay>? days,
    String? tripTitle,
    String? tripDescription,
  }) {
    return AutoPlanResult(
      request: request,
      days: days ?? this.days,
      table: table,
      warnings: warnings,
      tripTitle: tripTitle ?? this.tripTitle,
      tripDescription: tripDescription ?? this.tripDescription,
    );
  }

  static String? _durationLabel(int min) {
    if (min < 60) return '${min}m';
    final h = min ~/ 60;
    final m = min % 60;
    return m > 0 ? '${h}h${m}m' : '${h}h';
  }
}

// ─── AutoPlanService (Cách A: fixed time blocks) ───────────────────

class AutoPlanService {
  final RecommendationService _recommender;
  final ItineraryService _itinerary;

  const AutoPlanService({
    RecommendationService recommender = const RecommendationService(),
    ItineraryService itinerary = const ItineraryService(),
  })  : _recommender = recommender,
       _itinerary = itinerary;

  /// Main entry point: produce an [AutoPlanResult] with fixed time blocks.
  ///
  /// Pipeline:
  /// 1. Recommend locations via [RecommendationService]
  /// 2. Pick fixed blocks: stay (check-in), food (meals), cafe (nightlife)
  /// 3. Route sightseeing via [ItineraryService] (K-Means + 2-opt)
  /// 4. Compose [AutoPlanDay]/[AutoPlanStop] with fixed time slots
  /// 5. Build [AiScheduleTable] preview
  AutoPlanResult plan({
    required AutoPlanRequest request,
    required List<Location> allLocations,
    UserProfile? profile,
    Map<String, double> categoryInterests = const {},
    Map<String, double> tagInterests = const {},
    Set<String> interactedLocationIds = const {},
  }) {
    final warnings = <AutoPlanWarning>[];

    // 0) Candidates cho destination
    final candidates = allLocations
        .where((l) => l.destinationId == request.destinationId)
        .where((l) => l.status == 'published')
        .toList();

    if (candidates.isEmpty) {
      warnings.add(const AutoPlanWarning(
        'NO_CANDIDATES',
        'Không có địa điểm nào cho điểm đến này.',
      ));
      final emptyDays = List.generate(
        request.numberOfDays,
        (i) => AutoPlanDay(dayIndex: i, stops: const []),
      );
      return AutoPlanResult(
        request: request,
        days: emptyDays,
        table: _buildTable(request, emptyDays),
        warnings: warnings,
      );
    }

    final locationById = {for (final l in candidates) l.id: l};

    // 1) Effective profile (merge request override)
    final effectiveProfile = _buildEffectiveProfile(profile, request);

    // 2) Target sightseeing per day
    final targets = List.generate(
      request.numberOfDays,
      (d) => _targetSightseeingForDay(
        dayIndex: d,
        totalDays: request.numberOfDays,
        pace: request.pace,
        endEarlyOnLastDay: request.endEarlyOnLastDay,
      ),
    );
    final totalSightseeingNeeded = targets.fold<int>(0, (a, b) => a + b);

    // 3) Recommend: pool đủ lớn cho fixed blocks + sightseeing
    final fixedNeedRough = request.numberOfDays * 3 + 2;
    final topN = _clampInt(
      (totalSightseeingNeeded + fixedNeedRough) * 3,
      30,
      120,
    );

    final recItems = _recommender.recommend(
      candidates: candidates,
      profile: effectiveProfile,
      categoryInterests:
          request.useBehaviorSignals ? categoryInterests : const {},
      tagInterests: request.useBehaviorSignals ? tagInterests : const {},
      interactedLocationIds:
          request.useBehaviorSignals ? interactedLocationIds : const {},
      userLat: request.userLat,
      userLng: request.userLng,
      topN: topN,
      diversify: request.diversify,
    );

    final ranked = <Location>[];
    final reasonsById = <String, List<String>>{};
    for (final r in recItems) {
      final loc = locationById[r.locationId];
      if (loc == null) continue;
      if (ranked.any((x) => x.id == loc.id)) continue;
      ranked.add(loc);
      reasonsById[loc.id] = r.reasons;
    }

    // 4) Build pools cho fixed blocks
    List<Location> byCat(String cat) =>
        ranked.where((l) => l.category.toLowerCase() == cat).toList();

    final stayPool = byCat('stay');
    final foodPool = byCat('food');
    final cafePool = ranked.where((l) {
      final c = l.category.toLowerCase();
      if (c == 'cafe' || c == 'nightlife') return true;
      return l.tags.any((t) => t.toLowerCase() == 'nightlife');
    }).toList();

    final breakfastPool = ranked.where((l) {
      final c = l.category.toLowerCase();
      return c == 'food' || c == 'cafe';
    }).toList();

    if (stayPool.isEmpty) {
      warnings.add(const AutoPlanWarning(
        'NO_STAY',
        'Không tìm thấy địa điểm category=stay (bỏ block Check-in khách sạn).',
      ));
    }
    if (foodPool.isEmpty) {
      warnings.add(const AutoPlanWarning(
        'NO_FOOD',
        'Không tìm thấy địa điểm category=food (các block ăn uống có thể trống).',
      ));
    }
    if (cafePool.isEmpty) {
      warnings.add(const AutoPlanWarning(
        'NO_CAFE',
        'Không tìm thấy địa điểm category=cafe/nightlife (block 19:00+ có thể trống).',
      ));
    }

    // 5) Pick fixed blocks (unique nếu được)
    final usedFixed = <String>{};

    Location? pickUniqueOrFirst(List<Location> pool) {
      for (final l in pool) {
        if (!usedFixed.contains(l.id)) {
          usedFixed.add(l.id);
          return l;
        }
      }
      return pool.isNotEmpty ? pool.first : null;
    }

    final checkInStay = pickUniqueOrFirst(stayPool);
    final breakfasts = List<Location?>.filled(request.numberOfDays, null);
    final lunches = List<Location?>.filled(request.numberOfDays, null);
    final dinners = List<Location?>.filled(request.numberOfDays, null);
    final nights = List<Location?>.filled(request.numberOfDays, null);

    for (int d = 0; d < request.numberOfDays; d++) {
      final isLast = d == request.numberOfDays - 1;

      if (d > 0) {
        breakfasts[d] = pickUniqueOrFirst(breakfastPool);
      }

      final skipMealsToday = isLast && request.endEarlyOnLastDay;

      if (!skipMealsToday) {
        lunches[d] = pickUniqueOrFirst(foodPool);
        dinners[d] = pickUniqueOrFirst(foodPool);
        nights[d] = pickUniqueOrFirst(cafePool);
      }
    }

    // Reserved IDs
    final reserved = <String>{...usedFixed};
    if (checkInStay != null) reserved.add(checkInStay.id);
    for (final x in breakfasts) {
      if (x != null) reserved.add(x.id);
    }
    for (final x in lunches) {
      if (x != null) reserved.add(x.id);
    }
    for (final x in dinners) {
      if (x != null) reserved.add(x.id);
    }
    for (final x in nights) {
      if (x != null) reserved.add(x.id);
    }

    // 6) Select sightseeing list, exclude reserved + stay
    final sightseeing = <Location>[];
    for (final loc in ranked) {
      if (sightseeing.length >= totalSightseeingNeeded) break;
      if (reserved.contains(loc.id)) continue;
      if (loc.category.toLowerCase() == 'stay') continue;
      if (!loc.hasCoordinates) continue;
      sightseeing.add(loc);
    }

    if (sightseeing.length < totalSightseeingNeeded) {
      warnings.add(AutoPlanWarning(
        'NOT_ENOUGH_SIGHTSEEING',
        'Chỉ đủ ${sightseeing.length}/$totalSightseeingNeeded điểm tham quan theo nhịp độ.',
      ));
    }

    // 7) Run ItineraryService for sightseeing route optimization
    final constraints = ItineraryConstraints(
      numberOfDays: request.numberOfDays,
      pace: request.pace,
    );

    final generated = _itinerary.generate(
      candidates: sightseeing,
      constraints: constraints,
    );

    final sightseeingByDay = <int, List<Location>>{};
    for (final gd in generated) {
      final ordered = List.of(gd.slots)
        ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
      sightseeingByDay[gd.dayIndex] =
          ordered.map((s) => s.location).toList();
    }

    // 8) Compose AutoPlanDays with fixed time slots
    final planDays = <AutoPlanDay>[];

    for (int d = 0; d < request.numberOfDays; d++) {
      final isFirst = d == 0;
      final isLast = d == request.numberOfDays - 1;
      final skipMealsToday = isLast && request.endEarlyOnLastDay;

      final daySight = sightseeingByDay[d] ?? const <Location>[];
      final target = targets[d];

      final morningSightCount =
          (isFirst && checkInStay != null) ? 0 : (target > 0 ? 1 : 0);
      final afternoonSightCount = (target - morningSightCount).clamp(0, 99);

      final morningSight = daySight.take(morningSightCount).toList();
      final afternoonSight =
          daySight.skip(morningSightCount).take(afternoonSightCount).toList();

      final stops = <AutoPlanStop>[];
      int morningMinute = 480; // 08:00

      // ── 08:00 block (morning) ──
      if (isFirst && checkInStay != null) {
        final dur = checkInStay.estimatedDurationMin ?? 30;
        stops.add(AutoPlanStop(
          location: checkInStay,
          timeSlotName: 'morning',
          startMinute: morningMinute,
          durationMin: dur,
          reasons: reasonsById[checkInStay.id] ?? const [],
        ));
        morningMinute += dur + 15;
      } else {
        final b = breakfasts[d];
        if (b != null) {
          final dur = b.estimatedDurationMin ?? 45;
          stops.add(AutoPlanStop(
            location: b,
            timeSlotName: 'morning',
            startMinute: morningMinute,
            durationMin: dur,
            reasons: reasonsById[b.id] ?? const [],
          ));
          morningMinute += dur + 15;
        }
      }

      for (final loc in morningSight) {
        final tl = _computeTravelLeg(
          stops.isNotEmpty ? stops.last.location : null,
          loc,
        );
        morningMinute += tl?.travelMinutes ?? 15;
        final dur = loc.estimatedDurationMin ?? 60;
        stops.add(AutoPlanStop(
          location: loc,
          timeSlotName: 'morning',
          startMinute: morningMinute,
          durationMin: dur,
          reasons: reasonsById[loc.id] ?? const [],
          travelFromPrevious: tl,
        ));
        morningMinute += dur;
      }

      // ── 11:00 lunch (noon) ──
      if (!skipMealsToday) {
        final l = lunches[d];
        if (l != null) {
          stops.add(AutoPlanStop(
            location: l,
            timeSlotName: 'noon',
            startMinute: 660, // 11:00
            durationMin: l.estimatedDurationMin ?? 60,
            reasons: reasonsById[l.id] ?? const [],
          ));
        }
      }

      // ── 13:00-17:00 sightseeing (afternoon) ──
      int afternoonMinute = 780; // 13:00
      for (int i = 0; i < afternoonSight.length; i++) {
        final loc = afternoonSight[i];
        TravelLeg? tl;
        if (i > 0) {
          tl = _computeTravelLeg(afternoonSight[i - 1], loc);
          afternoonMinute += tl?.travelMinutes ?? 15;
        }
        final dur = loc.estimatedDurationMin ?? 60;
        stops.add(AutoPlanStop(
          location: loc,
          timeSlotName: 'afternoon',
          startMinute: afternoonMinute,
          durationMin: dur,
          reasons: reasonsById[loc.id] ?? const [],
          travelFromPrevious: tl,
        ));
        afternoonMinute += dur;
      }

      // ── 18:00 dinner + 19:00+ cafe (evening) ──
      if (!skipMealsToday) {
        final din = dinners[d];
        if (din != null) {
          stops.add(AutoPlanStop(
            location: din,
            timeSlotName: 'evening',
            startMinute: 1080, // 18:00
            durationMin: din.estimatedDurationMin ?? 60,
            reasons: reasonsById[din.id] ?? const [],
          ));
        }
        final night = nights[d];
        if (night != null) {
          stops.add(AutoPlanStop(
            location: night,
            timeSlotName: 'evening',
            startMinute: 1140, // 19:00
            durationMin: night.estimatedDurationMin ?? 60,
            reasons: reasonsById[night.id] ?? const [],
          ));
        }
      }

      planDays.add(AutoPlanDay(dayIndex: d, stops: stops));
    }

    // 9) Build preview table
    final table = _buildTable(request, planDays);

    return AutoPlanResult(
      request: request,
      days: planDays,
      table: table,
      warnings: warnings,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

  UserProfile _buildEffectiveProfile(
    UserProfile? existing,
    AutoPlanRequest r,
  ) {
    final base = existing ??
        UserProfile(userId: 'auto_plan', updatedAt: DateTime.now());

    return base.copyWith(
      preferredCategoryIds: r.preferredCategoryIds.isNotEmpty
          ? r.preferredCategoryIds
          : base.preferredCategoryIds,
      preferredTags:
          r.preferredTags.isNotEmpty ? r.preferredTags : base.preferredTags,
      travelPace: r.pace,
      budgetLevel: r.budgetLevel,
      groupType: r.groupType,
      updatedAt: DateTime.now(),
    );
  }

  static int _targetSightseeingForDay({
    required int dayIndex,
    required int totalDays,
    required TravelPace pace,
    required bool endEarlyOnLastDay,
  }) {
    final isFirst = dayIndex == 0;
    final isLast = dayIndex == totalDays - 1;

    if (totalDays == 1) {
      switch (pace) {
        case TravelPace.relaxed:
          return 2;
        case TravelPace.normal:
          return 4;
        case TravelPace.packed:
          return 6;
      }
    }

    if (isLast && !endEarlyOnLastDay) {
      // fallthrough → middle rule
    } else {
      if (isFirst || isLast) {
        switch (pace) {
          case TravelPace.relaxed:
            return 2;
          case TravelPace.normal:
            return 3;
          case TravelPace.packed:
            return 4;
        }
      }
    }

    switch (pace) {
      case TravelPace.relaxed:
        return 3;
      case TravelPace.normal:
        return 4;
      case TravelPace.packed:
        return 6;
    }
  }

  static int _clampInt(int v, int min, int max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }

  static TravelLeg? _computeTravelLeg(Location? from, Location to) {
    if (from == null || !from.hasCoordinates || !to.hasCoordinates) return null;
    final km = GeoUtils.haversineKm(
      from.latitude!,
      from.longitude!,
      to.latitude!,
      to.longitude!,
    );
    final min = GeoUtils.estimateTravelMinutes(
      from.latitude!,
      from.longitude!,
      to.latitude!,
      to.longitude!,
    );
    return TravelLeg(distanceKm: km, travelMinutes: min);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build bảng giờ preview
  // ─────────────────────────────────────────────────────────────────────────

  AiScheduleTable _buildTable(
    AutoPlanRequest request,
    List<AutoPlanDay> days,
  ) {
    final headers = List.generate(days.length, (i) => 'Ngày ${i + 1}');

    List<AutoPlanStop> stopsForSlot(AutoPlanDay d, String slot) => d.stops
        .where((s) => s.timeSlotName.toLowerCase() == slot)
        .toList()
      ..sort((a, b) => a.startMinute.compareTo(b.startMinute));

    String afternoonChain(int dayIndex, List<AutoPlanStop> acts) {
      if (acts.isEmpty) return '-';

      final parts = <String>[];
      for (int i = 0; i < acts.length; i++) {
        final s = acts[i];
        parts.add('${_emojiForCategory(s.location.category)} ${s.location.name}');

        if (i < acts.length - 1) {
          final from = acts[i].location;
          final to = acts[i + 1].location;
          if (from.hasCoordinates && to.hasCoordinates) {
            final min = GeoUtils.estimateTravelMinutes(
              from.latitude!,
              from.longitude!,
              to.latitude!,
              to.longitude!,
            );
            parts.add('→ (~${min}p)');
          } else {
            parts.add('→');
          }
        }
      }

      final isLast = dayIndex == days.length - 1;
      if (isLast && request.endEarlyOnLastDay) {
        parts.add('→ 🏁 Về');
      }

      return parts.join(' ');
    }

    String morningCell(int dayIndex, List<AutoPlanStop> morning) {
      if (morning.isEmpty) return '-';

      final stay = morning.firstWhere(
        (s) => s.location.category.toLowerCase() == 'stay',
        orElse: () => morning.first,
      );
      if (stay.location.category.toLowerCase() == 'stay') {
        return '🏨 Check-in: ${stay.location.name}';
      }

      final breakfast = morning.firstWhere((s) {
        final cat = s.location.category.toLowerCase();
        return cat == 'food' || cat == 'cafe';
      }, orElse: () => morning.first);

      final catB = breakfast.location.category.toLowerCase();
      if (catB == 'food' || catB == 'cafe') {
        if (morning.length >= 2) {
          final next = morning[1];
          return '🍜 Ăn sáng: ${breakfast.location.name}\n'
              '→ ${_emojiForCategory(next.location.category)} ${next.location.name}';
        }
        return '🍜 Ăn sáng: ${breakfast.location.name}';
      }

      return morning
          .take(2)
          .map((s) =>
              '${_emojiForCategory(s.location.category)} ${s.location.name}')
          .join('\n');
    }

    String noonCell(List<AutoPlanStop> noon) {
      if (noon.isEmpty) return '-';
      return '🍜 Ăn trưa: ${noon.first.location.name}';
    }

    String evening18Cell(List<AutoPlanStop> evening) {
      if (evening.isEmpty) return '-';
      final dinner = evening.firstWhere(
        (s) => s.location.category.toLowerCase() == 'food',
        orElse: () => evening.first,
      );
      return '🍜 Ăn tối: ${dinner.location.name}';
    }

    String evening19Cell(List<AutoPlanStop> evening) {
      if (evening.length <= 1) return '-';
      final rest = evening.skip(1);
      return rest
          .map((s) =>
              '${_emojiForCategory(s.location.category)} ${s.location.name}')
          .join('\n');
    }

    final rows = <AiScheduleRow>[
      AiScheduleRow(
        timeLabel: '08:00',
        dayCells: List.generate(
          days.length,
          (i) => morningCell(i, stopsForSlot(days[i], 'morning')),
        ),
      ),
      AiScheduleRow(
        timeLabel: '11:00',
        dayCells:
            days.map((d) => noonCell(stopsForSlot(d, 'noon'))).toList(),
      ),
      AiScheduleRow(
        timeLabel: '13:00-17:00',
        dayCells: List.generate(
          days.length,
          (i) => afternoonChain(i, stopsForSlot(days[i], 'afternoon')),
        ),
      ),
      AiScheduleRow(
        timeLabel: '18:00',
        dayCells: days
            .map((d) => evening18Cell(stopsForSlot(d, 'evening')))
            .toList(),
      ),
      AiScheduleRow(
        timeLabel: '19:00+',
        dayCells: days
            .map((d) => evening19Cell(stopsForSlot(d, 'evening')))
            .toList(),
      ),
    ];

    return AiScheduleTable(dayHeaders: headers, rows: rows);
  }
}
