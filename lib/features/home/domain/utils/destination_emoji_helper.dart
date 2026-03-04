/// Helper class for mapping destinations to their representative emojis.
///
/// Story 8-7: Provides emoji mapping for destination pills display.
/// Emojis represent the character/type of each destination.
abstract class DestinationEmojiHelper {
  // Private constructor - this class should not be instantiated
  DestinationEmojiHelper._();

  /// Emoji mapping for known destination IDs.
  /// Each destination gets a unique emoji representing its character.
  static const Map<String, String> _emojiMapping = {
    'da-nang': '🏖️', // Beach destination
    'hoi-an': '🏮', // Lantern (ancient town)
    'da-lat': '🏔️', // Mountain/highlands
    'hue': '🏛️', // Historical/imperial
    'nha-trang': '🌊', // Ocean waves
    'phu-quoc': '🏝️', // Island paradise
    'ha-noi': '🕌', // Temple/cultural
    'sai-gon': '🌆', // City skyline
    'ho-chi-minh': '🌆', // City skyline (alias)
    'sapa': '⛰️', // Mountain/terraced fields
    'ha-long': '🛶', // Bay/boat
    'mui-ne': '🏜️', // Sand dunes
    'can-tho': '🚣', // Mekong Delta boats
    'vung-tau': '⛱️', // Beach resort
    'quy-nhon': '🌅', // Sunrise coast
    'ninh-binh': '🚣', // River/boat caves
  };

  /// Default emoji for destinations not in the mapping.
  static const String defaultEmoji = '📍';

  /// Get the representative emoji for a destination ID.
  ///
  /// Returns the mapped emoji if found, otherwise returns default location pin.
  ///
  /// Example:
  /// ```dart
  /// DestinationEmojiHelper.getEmoji('da-nang') // Returns '🏖️'
  /// DestinationEmojiHelper.getEmoji('unknown') // Returns '📍'
  /// ```
  static String getEmoji(String destinationId) {
    final normalizedId = destinationId.toLowerCase().trim();
    return _emojiMapping[normalizedId] ?? defaultEmoji;
  }

  /// Format the display text for a destination pill.
  ///
  /// Combines emoji and destination name for display.
  ///
  /// Example:
  /// ```dart
  /// DestinationEmojiHelper.formatPillText('da-nang', 'Đà Nẵng')
  /// // Returns '🏖️ Đà Nẵng'
  /// ```
  static String formatPillText(String destinationId, String destinationName) {
    final emoji = getEmoji(destinationId);
    return '$emoji $destinationName';
  }

  /// Check if a destination has a custom emoji mapping.
  ///
  /// Returns true if the destination has a specific emoji,
  /// false if it would use the default emoji.
  static bool hasCustomEmoji(String destinationId) {
    final normalizedId = destinationId.toLowerCase().trim();
    return _emojiMapping.containsKey(normalizedId);
  }

  /// Get all known destination IDs that have emoji mappings.
  static List<String> get knownDestinationIds => _emojiMapping.keys.toList();
}
