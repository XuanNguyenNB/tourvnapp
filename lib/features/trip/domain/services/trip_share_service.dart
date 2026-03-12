import 'package:share_plus/share_plus.dart';

import '../entities/trip.dart';

/// Service for sharing trip itineraries via the device's native share sheet.
///
/// Formats trip data into a human-readable text with emojis
/// and shares it using the system share dialog.
class TripShareService {
  const TripShareService();

  /// Share a trip itinerary as formatted text.
  Future<void> shareTrip(Trip trip) async {
    final text = formatTripAsText(trip);
    await Share.share(text);
  }

  /// Format a trip into a readable text summary with emojis.
  ///
  /// Example output:
  /// ```
  /// 🗺️ Khám phá Đà Lạt — 3 ngày
  ///
  /// 📅 Ngày 1:
  /// ☀️ Sáng: 🍜 Bánh mì Đà Lạt → 📸 Hồ Xuân Hương
  /// 🌙 Chiều: 🏨 Check-in khách sạn
  ///
  /// Tạo bởi TourVN 🇻🇳
  /// ```
  String formatTripAsText(Trip trip) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln(
      '🗺️ Khám phá ${trip.destinationName} — ${trip.totalDays} ngày',
    );
    buffer.writeln();

    // Days
    for (int i = 0; i < trip.days.length; i++) {
      final day = trip.days[i];
      buffer.writeln('📅 Ngày ${i + 1}:');

      if (day.activities.isEmpty) {
        buffer.writeln('   Chưa có hoạt động');
      } else {
        // Group activities by time slot
        final morningActivities = <String>[];
        final afternoonActivities = <String>[];
        final eveningActivities = <String>[];

        for (final activity in day.activities) {
          final emoji = _getCategoryEmoji(activity.emoji);
          final name = activity.locationName;
          final formatted = '$emoji $name';

          final slot = activity.timeSlot.toLowerCase();
          if (slot.contains('morning') || slot.contains('sáng')) {
            morningActivities.add(formatted);
          } else if (slot.contains('afternoon') || slot.contains('chiều')) {
            afternoonActivities.add(formatted);
          } else {
            eveningActivities.add(formatted);
          }
        }

        if (morningActivities.isNotEmpty) {
          buffer.writeln('   ☀️ Sáng: ${morningActivities.join(' → ')}');
        }
        if (afternoonActivities.isNotEmpty) {
          buffer.writeln('   🌤️ Chiều: ${afternoonActivities.join(' → ')}');
        }
        if (eveningActivities.isNotEmpty) {
          buffer.writeln('   🌙 Tối: ${eveningActivities.join(' → ')}');
        }
      }

      buffer.writeln();
    }

    // Footer
    buffer.writeln('Tạo bởi TourVN 🇻🇳');

    return buffer.toString().trimRight();
  }

  /// Get emoji for a category, with fallback.
  String _getCategoryEmoji(String? emoji) {
    if (emoji != null && emoji.isNotEmpty) return emoji;
    return '📍';
  }
}
