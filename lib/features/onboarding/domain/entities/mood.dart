/// Mood - Phong cách du lịch cho cá nhân hóa onboarding
///
/// Mỗi mood đại diện cho một phong cách du lịch mà người dùng có thể chọn.
/// Người dùng có thể chọn nhiều mood để cá nhân hóa nội dung feed.
///
/// Features:
/// - Label tiếng Việt cho hiển thị
/// - Subtitle mô tả ngắn gọn
/// - Emoji cho biểu diễn trực quan
/// - ID cho persistence (giữ nguyên tên enum tiếng Anh)
///
/// Example:
/// ```dart
/// final mood = Mood.healing;
/// print(mood.label); // 'Chữa lành'
/// print(mood.emoji); // '🧘'
/// print(mood.subtitle); // 'Nghỉ dưỡng, thư giãn'
/// ```
enum Mood {
  /// Nghỉ dưỡng, thư giãn, wellness
  healing('Chữa lành', '🧘', 'Nghỉ dưỡng, thư giãn'),

  /// Hoạt động ngoài trời, trải nghiệm mạo hiểm
  adventure('Phiêu lưu', '🏔️', 'Khám phá, mạo hiểm'),

  /// Ẩm thực, khám phá món ăn địa phương
  foodie('Ẩm thực', '🍜', 'Ăn uống, đặc sản'),

  /// Chụp ảnh, check-in, địa điểm đẹp
  photography('Chụp ảnh', '📸', 'Check-in, sống ảo'),

  /// Vui chơi, lễ hội, nightlife
  party('Vui chơi', '🎉', 'Lễ hội, giải trí');

  const Mood(this.label, this.emoji, this.subtitle);

  /// Label hiển thị tiếng Việt (e.g., 'Chữa lành', 'Phiêu lưu')
  final String label;

  /// Emoji đại diện (e.g., '🧘', '🏔️')
  final String emoji;

  /// Mô tả ngắn gọn (e.g., 'Nghỉ dưỡng, thư giãn')
  final String subtitle;

  /// Returns the mood ID for persistence (lowercase enum name)
  String get id => name;

  /// Creates a Mood from its string ID
  ///
  /// Returns null if the ID doesn't match any mood
  static Mood? fromId(String id) {
    try {
      return Mood.values.firstWhere((mood) => mood.id == id);
    } catch (_) {
      return null;
    }
  }

  /// All available moods as a list
  static List<Mood> get all => Mood.values;
}
