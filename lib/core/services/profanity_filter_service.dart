/// Client-side profanity filter for Vietnamese text.
///
/// Checks comment text against a curated list of Vietnamese profanity words
/// and common variations (abbreviated, leetspeak, no-diacritics).
///
/// Usage:
/// ```dart
/// const filter = ProfanityFilterService();
/// final result = filter.check('some text');
/// if (result.isFlagged) {
///   print('Matched: ${result.matchedWords}');
/// }
/// ```
class ProfanityFilterService {
  const ProfanityFilterService();

  /// Check text for profanity.
  ///
  /// Returns [ProfanityCheckResult] with flag status and matched words.
  ProfanityCheckResult check(String text) {
    if (text.trim().isEmpty) {
      return const ProfanityCheckResult(isFlagged: false, matchedWords: []);
    }

    final normalizedText = _normalize(text);
    final matchedWords = <String>[];

    for (final word in _profanityList) {
      final normalizedWord = _normalize(word);
      if (_containsWord(normalizedText, normalizedWord)) {
        matchedWords.add(word);
      }
    }

    return ProfanityCheckResult(
      isFlagged: matchedWords.isNotEmpty,
      matchedWords: matchedWords,
    );
  }

  /// Normalize Vietnamese text: lowercase + remove diacritics.
  ///
  /// This catches variations like "đụ" → "du", "địt" → "dit", etc.
  String _normalize(String text) {
    String result = text.toLowerCase();

    // Vietnamese diacritics mapping
    const diacriticsMap = {
      'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
      'đ': 'd',
    };

    final buffer = StringBuffer();
    for (final char in result.runes) {
      final c = String.fromCharCode(char);
      buffer.write(diacriticsMap[c] ?? c);
    }

    return buffer.toString();
  }

  /// Check if normalized text contains a profanity word as a standalone word
  /// or as a significant substring.
  bool _containsWord(String normalizedText, String normalizedWord) {
    // For short words (<=3 chars), require word boundary matching
    // to avoid false positives (e.g., "đi" matching inside "đi chơi")
    if (normalizedWord.length <= 3) {
      final pattern = RegExp(r'(?<!\w)' + RegExp.escape(normalizedWord) + r'(?!\w)');
      return pattern.hasMatch(normalizedText);
    }

    // For longer words/phrases, substring match is sufficient
    return normalizedText.contains(normalizedWord);
  }

  /// Curated list of Vietnamese profanity words and common variations.
  ///
  /// Includes: explicit vulgar words, slurs, abbreviations, and leetspeak.
  /// Maintained as a static list for simplicity. Can be extended to
  /// fetch from Firestore for dynamic updates.
  static const _profanityList = <String>[
    // ── Explicit vulgar words ──
    'đụ', 'địt', 'đĩ', 'đỹ',
    'cặc', 'buồi', 'lồn', 'vú',
    'đéo', 'đếch', 'đệt',
    'mẹ mày', 'má mày', 'bố mày',
    'con đĩ', 'con điếm',
    'thằng ngu', 'con ngu',
    'ngu lồn', 'ngu vãi',
    'vãi lồn', 'vãi cả lồn',
    'cái lồn', 'cái đĩ',

    // ── Common abbreviations ──
    'vcl', 'vkl', 'vl', 'vcc',
    'clm', 'clgt',
    'dmm', 'đmm', 'dcm', 'đcm',
    'dkm', 'đkm', 'dml', 'đml',
    'wtf',

    // ── Slang and variations ──
    'cc', 'cl', 'dm',
    'lol mày', 'cứt',
    'chó', 'chó đẻ',
    'khốn nạn', 'đồ chó',
    'thằng chó', 'con chó',

    // ── Insults and slurs ──
    'ngu như chó', 'ngu như bò',
    'đồ ngu', 'đồ xuẩn',
    'mặt lồn', 'mặt đĩ',
    'đồ rác', 'đồ rác rưởi',
    'thằng khốn', 'con khốn',
    'đồ khốn',
    'mất dạy', 'vô học',
    'đồ điên', 'thần kinh',

    // ── Sexual/explicit ──
    'chịch', 'đè', 'hiếp',
    'sục', 'thủ dâm',
    'cave', 'gái gọi',

    // ── Leetspeak / obfuscated ──
    'd1t', 'l0n', 'c4c',
    'duma', 'du ma',
    'dit me', 'dit con me',
  ];
}

/// Result of a profanity check on text.
class ProfanityCheckResult {
  /// Whether the text was flagged as containing profanity.
  final bool isFlagged;

  /// List of matched profanity words found in the text.
  final List<String> matchedWords;

  const ProfanityCheckResult({
    required this.isFlagged,
    required this.matchedWords,
  });

  @override
  String toString() =>
      'ProfanityCheckResult(isFlagged: $isFlagged, matchedWords: $matchedWords)';
}
