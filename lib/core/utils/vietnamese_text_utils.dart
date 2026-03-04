/// Utilities for handling Vietnamese text in search operations.
///
/// Provides methods for:
/// - Removing diacritics from Vietnamese text
/// - Generating search keywords for Firestore array-contains queries
///
/// Story 8-6: Implement Location Search Provider
abstract class VietnameseTextUtils {
  // Vietnamese diacritics mapping - carefully counted for each vowel group
  // a (17): à á ạ ả ã â ầ ấ ậ ẩ ẫ ă ằ ắ ặ ẳ ẵ
  // e (11): è é ẹ ẻ ẽ ê ề ế ệ ể ễ
  // i (5):  ì í ị ỉ ĩ
  // o (17): ò ó ọ ỏ õ ô ồ ố ộ ổ ỗ ơ ờ ớ ợ ở ỡ
  // u (11): ù ú ụ ủ ũ ư ừ ứ ự ử ữ
  // y (5):  ỳ ý ỵ ỷ ỹ
  // d (1):  đ

  /// Vietnamese lowercase characters with diacritics (67 chars total)
  static const String _vietnameseLower =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';

  /// Vietnamese uppercase characters with diacritics (67 chars total)
  static const String _vietnameseUpper =
      'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';

  /// Corresponding non-diacritic lowercase characters (67 chars total)
  /// 17 a's + 11 e's + 5 i's + 17 o's + 11 u's + 5 y's + 1 d = 67
  static const String _nonVietnameseLower =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

  /// Convert Vietnamese text to non-diacritics version.
  ///
  /// Example: "Đà Nẵng" → "da nang"
  /// Example: "Bà Nà Hills" → "ba na hills"
  static String removeDiacritics(String text) {
    if (text.isEmpty) return text;

    var result = text;

    // First handle uppercase characters (before toLowerCase)
    for (var i = 0; i < _vietnameseUpper.length; i++) {
      result = result.replaceAll(_vietnameseUpper[i], _nonVietnameseLower[i]);
    }

    // Then convert to lowercase and handle lowercase chars
    result = result.toLowerCase();
    for (var i = 0; i < _vietnameseLower.length; i++) {
      result = result.replaceAll(_vietnameseLower[i], _nonVietnameseLower[i]);
    }

    return result;
  }

  /// Check if text contains Vietnamese diacritics.
  static bool hasDiacritics(String text) {
    final lowerText = text.toLowerCase();
    for (var i = 0; i < _vietnameseLower.length; i++) {
      if (lowerText.contains(_vietnameseLower[i])) {
        return true;
      }
    }
    // Also check uppercase in original text
    for (var i = 0; i < _vietnameseUpper.length; i++) {
      if (text.contains(_vietnameseUpper[i])) {
        return true;
      }
    }
    return false;
  }

  /// Generate search keywords from a location name.
  ///
  /// Creates multiple variations for Firestore array-contains queries:
  /// - Original lowercase name
  /// - No-diacritics version
  /// - Individual words (minimum 2 characters)
  /// - Individual words without diacritics
  ///
  /// Example: "Bà Nà Hills"
  /// Returns: ["bà nà hills", "ba na hills", "bà", "nà", "hills", "ba", "na"]
  static List<String> generateSearchKeywords(String name) {
    if (name.isEmpty) return [];

    final keywords = <String>{};
    final lowerName = name.toLowerCase().trim();
    final noDiacritics = removeDiacritics(lowerName);

    // Add full name versions
    keywords.add(lowerName);
    if (noDiacritics != lowerName) {
      keywords.add(noDiacritics);
    }

    // Add individual words (minimum 2 characters)
    final words = lowerName.split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.length >= 2) {
        keywords.add(word);
        final wordNoDiacritics = removeDiacritics(word);
        if (wordNoDiacritics != word) {
          keywords.add(wordNoDiacritics);
        }
      }
    }

    return keywords.toList()..sort();
  }

  /// Check if query matches text using Vietnamese-aware comparison.
  ///
  /// Matches if:
  /// - Text contains query (case-insensitive)
  /// - Text without diacritics contains query without diacritics
  static bool matchesVietnamese(String text, String query) {
    if (query.isEmpty) return false;

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase().trim();

    // Direct match
    if (lowerText.contains(lowerQuery)) {
      return true;
    }

    // Match without diacritics
    final textNoDiacritics = removeDiacritics(lowerText);
    final queryNoDiacritics = removeDiacritics(lowerQuery);

    return textNoDiacritics.contains(queryNoDiacritics);
  }

  /// Normalize text for consistent search matching.
  ///
  /// Converts to lowercase, trims whitespace, and optionally removes diacritics.
  static String normalize(String text, {bool removeDiacritics = false}) {
    var result = text.toLowerCase().trim();
    if (removeDiacritics) {
      result = VietnameseTextUtils.removeDiacritics(result);
    }
    return result;
  }
}
