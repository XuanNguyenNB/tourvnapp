import '../../../recommendation/domain/entities/user_profile.dart';

/// Constraints and parameters for smart itinerary generation.
///
/// Encapsulates all user preferences and time budgets that
/// the itinerary algorithm uses to plan each day.
class ItineraryConstraints {
  /// Number of trip days.
  final int numberOfDays;

  /// Travel pace (affects locations per day).
  final TravelPace pace;

  /// Morning slot: start and end hour (24h format).
  final int morningStart;
  final int morningEnd;

  /// Afternoon slot: start and end hour.
  final int afternoonStart;
  final int afternoonEnd;

  /// Evening slot: start and end hour.
  final int eveningStart;
  final int eveningEnd;

  /// Default estimated duration per location (minutes) if not specified.
  final int defaultDurationMin;

  /// Maximum travel time between consecutive locations (minutes).
  /// If exceeded, the algorithm will try to find a closer alternative.
  final int maxTravelMinutes;

  const ItineraryConstraints({
    required this.numberOfDays,
    this.pace = TravelPace.normal,
    this.morningStart = 8,
    this.morningEnd = 12,
    this.afternoonStart = 13,
    this.afternoonEnd = 17,
    this.eveningStart = 18,
    this.eveningEnd = 21,
    this.defaultDurationMin = 60,
    this.maxTravelMinutes = 45,
  });

  /// Total minutes available in the morning slot.
  int get morningBudget => (morningEnd - morningStart) * 60;

  /// Total minutes available in the afternoon slot.
  int get afternoonBudget => (afternoonEnd - afternoonStart) * 60;

  /// Total minutes available in the evening slot.
  int get eveningBudget => (eveningEnd - eveningStart) * 60;

  /// Total minutes available per day.
  int get dailyBudget => morningBudget + afternoonBudget + eveningBudget;

  /// Max locations per day based on travel pace.
  int get maxLocationsPerDay => pace.locationsPerDay;

  /// Slot time ranges for display.
  List<({String name, String emoji, int startHour, int endHour})>
  get timeSlots => [
    (name: 'Sáng', emoji: '🌅', startHour: morningStart, endHour: morningEnd),
    (
      name: 'Chiều',
      emoji: '☀️',
      startHour: afternoonStart,
      endHour: afternoonEnd,
    ),
    (name: 'Tối', emoji: '🌙', startHour: eveningStart, endHour: eveningEnd),
  ];

  @override
  String toString() =>
      'ItineraryConstraints(days: $numberOfDays, pace: ${pace.name}, '
      'maxLoc/day: $maxLocationsPerDay)';
}

/// Category-to-slot preference mapping for time assignment heuristic.
///
/// Defines which time slots are preferred for each category.
/// Score: 1.0 = perfect fit, 0.5 = acceptable, 0.0 = avoid.
const Map<String, Map<String, double>> categorySlotPreferences = {
  'food': {'morning': 0.5, 'afternoon': 0.8, 'evening': 1.0},
  'places': {'morning': 1.0, 'afternoon': 0.8, 'evening': 0.3},
  'stay': {'morning': 0.2, 'afternoon': 0.3, 'evening': 1.0},
  'nature': {'morning': 1.0, 'afternoon': 0.7, 'evening': 0.2},
  'nightlife': {'morning': 0.0, 'afternoon': 0.2, 'evening': 1.0},
  'culture': {'morning': 0.9, 'afternoon': 0.8, 'evening': 0.4},
  'shopping': {'morning': 0.3, 'afternoon': 1.0, 'evening': 0.7},
};
