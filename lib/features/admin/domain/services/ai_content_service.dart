import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

/// Service for generating travel content using Gemini API (REST HTTP).
///
/// Cách phổ biến và thực chiến nhất: GỌI TRỰC TIẾP REST API!
/// Tránh lỗi CORS và SDK version khi chạy Flutter Web.
class AiContentService {
  final String apiKey;
  final String modelName =
      'gemini-2.0-flash'; // 2.0-flash chạy gọi HTTP rất ổn định
  static const _maxRetries = 3;

  AiContentService({required this.apiKey});

  /// Hàm gọi HTTP POST tới Gemini API, hỗ trợ Web Search Grounding
  Future<String> _callGeminiApi(String prompt, String systemInstruction) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
    );

    // Định nghĩa Tools: Google Search
    final tools = [
      {"google_search": {}},
    ];

    final contents = <Map<String, dynamic>>[
      {
        "role": "user",
        "parts": [
          {"text": prompt},
        ],
      },
    ];

    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "system_instruction": {
              "parts": {"text": systemInstruction},
            },
            "contents": contents,
            "tools": tools,
            "generationConfig": {
              "temperature": 0.5,
            }, // Giảm temp để dữ liệu chính xác hơn
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final candidate = data['candidates'][0];
          final parts = candidate['content']['parts'] as List<dynamic>;

          // Trả về text
          for (final p in parts) {
            if (p.containsKey('text')) return p['text'] as String;
          }
          throw Exception('Không tìm thấy text trong phản hồi.');
        } else if (response.statusCode == 429) {
          if (attempt == _maxRetries) {
            throw Exception(
              'API đã hết quota tạm thời (Error 429). Vui lòng đợi 1 phút rồi thử lại.',
            );
          }
        } else {
          if (attempt == _maxRetries) {
            throw Exception(
              'Lỗi API (${response.statusCode}): ${response.body}',
            );
          }
        }
      } catch (e) {
        if (e.toString().contains('429')) rethrow;
        if (attempt == _maxRetries) {
          throw Exception('Không thể kết nối Server API: $e');
        }
      }
      await Future.delayed(Duration(seconds: 2 << attempt));
    }
    throw Exception('Đã thử $_maxRetries lần nhưng thất bại.');
  }

  /// Gọi API Nominatim (OpenStreetMap) để lấy tọa độ
  Future<Map<String, dynamic>> _fetchGpsFromNominatim(String query) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1',
      );
      final response = await http.get(
        url,
        headers: {
          'User-Agent':
              'TourVN Flutter App (tuanday112@gmail.com)', // Cần thiết cho Nominatim
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return {
            "latitude": double.parse(data[0]['lat'].toString()),
            "longitude": double.parse(data[0]['lon'].toString()),
          };
        }
      }
      return {
        "error": "Không tìm thấy tọa độ.",
        "latitude": null,
        "longitude": null,
      };
    } catch (e) {
      return {"error": e.toString(), "latitude": null, "longitude": null};
    }
  }

  // ── Destination Generation ──────────────────────────────

  Future<Map<String, dynamic>> generateDestination(String prompt) async {
    final systemPrompt = '''
Bạn là một chuyên gia du lịch Việt Nam. Tạo thông tin về điểm đến du lịch dựa trên yêu cầu.
Trả về JSON thuần túy (KHÔNG có markdown code block), với các trường:
{
  "id": "slug-id-tu-ten (ví dụ: ninh-binh)",
  "name": "Tên điểm đến tiếng Việt",
  "heroImage": "",
  "description": "Mô tả chi tiết 200-400 từ về điểm đến, lịch sử, văn hóa, đặc trưng",
  "countryCode": "VN",
  "status": "draft_ai"
}
Chỉ trả về JSON, không thêm giải thích hay markdown.
''';

    final resultText = await _callGeminiApi(
      'Tạo thông tin điểm đến: $prompt',
      systemPrompt,
    );
    return _parseJson(resultText);
  }

  // ── Location Generation ─────────────────────────────────

  Future<List<Map<String, dynamic>>> generateLocations({
    required String destinationId,
    required String destinationName,
    required String prompt,
    int count = 5,
  }) async {
    final systemPrompt =
        '''
Bạn là chuyên gia du lịch Việt Nam. Tạo danh sách $count địa điểm cụ thể tại "$destinationName".
Trả về JSON thuần túy (KHÔNG có markdown code block), là một mảng JSON:
[
  {
    "id": "slug-id-tu-ten",
    "destinationId": "$destinationId",
    "destinationName": "$destinationName",
    "name": "Tên địa điểm tiếng Việt",
    "image": "",
    "category": "food" hoặc "places" hoặc "stay",
    "address": "Địa chỉ cụ thể",
    "description": "Mô tả 50-100 từ",
    "priceRange": "\$" hoặc "\$\$" hoặc "\$\$\$",
    "rating": 4.5,
    "latitude": null,
    "longitude": null,
    "tags": ["romantic", "family-friendly", "adventure", "instagram-worthy", "hidden-gem", "budget-friendly", "luxury", "local-favorite"],
    "searchKeywords": ["từ khóa 1", "từ khóa 2"],
    "estimatedDurationMin": 60,
    "status": "draft_ai"
  }
]
Chọn tags phù hợp (2-4 tags). Chỉ trả về JSON, không thêm giải thích.
''';

    final resultText = await _callGeminiApi(
      'Tạo $count địa điểm cho: $prompt',
      systemPrompt,
    );
    final locations = _parseJsonList(resultText);

    // Xử lý GPS cục bộ bằng cách gọi Nominatim API cho từng địa điểm
    final updatedLocations = <Map<String, dynamic>>[];
    for (var loc in locations) {
      final name = loc['name'] as String?;
      final address = loc['address'] as String?;

      if (name != null && name.isNotEmpty) {
        // Thử tìm kiếm theo Tên + Tỉnh/Thành
        final searchQuery = '$name, $destinationName';
        final gpsData = await _fetchGpsFromNominatim(searchQuery);

        if (gpsData['latitude'] != null) {
          loc['latitude'] = gpsData['latitude'];
          loc['longitude'] = gpsData['longitude'];
        } else if (address != null && address.isNotEmpty) {
          // Nếu tìm theo tên thất bại, thử tìm theo địa chỉ
          final gpsDataFallback = await _fetchGpsFromNominatim(address);
          if (gpsDataFallback['latitude'] != null) {
            loc['latitude'] = gpsDataFallback['latitude'];
            loc['longitude'] = gpsDataFallback['longitude'];
          }
        }
      }
      updatedLocations.add(loc);
    }

    return updatedLocations;
  }

  // ── Review (Article) Generation ─────────────────────────

  /// Article styles supported by the AI writer.
  static const List<String> articleStyles = [
    'review',
    'guide',
    'top-list',
    'tips',
  ];

  /// Generate a single review/article with context-aware prompting.
  ///
  /// [existingLocations] provides real location data from the DB so the AI
  /// writes about actual places and fills `relatedLocationIds` correctly.
  /// [articleStyle] controls the writing format and length.
  Future<Map<String, dynamic>> generateReview({
    required String prompt,
    String? destinationId,
    String? destinationName,
    List<Map<String, dynamic>>? existingLocations,
    String articleStyle = 'review',
  }) async {
    final destContext = destinationId != null
        ? '\nĐiểm đến: $destinationName (ID: $destinationId)'
        : '';

    // Build location context block
    final locationContext = _buildLocationContext(existingLocations);

    // Style-specific instructions
    final styleInstructions = _getStyleInstructions(articleStyle);

    final systemPrompt = '''
Bạn là một travel blogger Việt Nam chuyên nghiệp, viết bài du lịch hấp dẫn và chi tiết.$destContext
$locationContext
$styleInstructions

Trả về JSON thuần túy (KHÔNG có markdown code block), với các trường:
{
  "id": "slug-tu-tieu-de",
  "heroImage": "",
  "title": "Tiêu đề hấp dẫn tiếng Việt, thu hút click",
  "authorId": "ai-writer",
  "authorName": "AI Travel Writer",
  "authorAvatar": "",
  "fullText": "Nội dung bài viết dạng Markdown, có ## heading cho từng phần, chi tiết và sinh động",
  "createdAt": "${DateTime.now().toIso8601String()}",
  "likeCount": 0,
  "commentCount": 0,
  "saveCount": 0,
  "relatedLocationIds": ["id-thuc-te-1", "id-thuc-te-2"],
  "destinationId": ${destinationId != null ? '"$destinationId"' : 'null'},
  "destinationName": ${destinationName != null ? '"$destinationName"' : 'null'},
  "category": "food hoặc places hoặc stay (tự suy từ nội dung chính)",
  "slug": "slug-tu-tieu-de",
  "status": "draft_ai"
}

QUY TẮC QUAN TRỌNG:
- "relatedLocationIds" CHỈ chứa các ID có trong danh sách địa điểm ở trên (nếu có). Nếu không có danh sách, để mảng rỗng.
- "fullText" phải dùng Markdown: ## cho heading, **bold** cho tên địa điểm, có ít nhất 3 phần/heading.
- Viết tự nhiên, có trải nghiệm cá nhân, mẹo thực tế, giá cả tham khảo.
- Chỉ trả về JSON, không thêm giải thích hay markdown block.
''';

    final resultText = await _callGeminiApi(
      'Viết bài $articleStyle về: $prompt',
      systemPrompt,
    );
    return _parseJson(resultText);
  }

  /// Generate multiple reviews/articles for a destination in one call.
  ///
  /// Each article will have a different style and focus on different locations.
  Future<List<Map<String, dynamic>>> generateMultipleReviews({
    required String destinationName,
    required String destinationId,
    required List<Map<String, dynamic>> existingLocations,
    int count = 3,
  }) async {
    // Build location context
    final locationContext = _buildLocationContext(existingLocations);

    final systemPrompt = '''
Bạn là team travel blogger Việt Nam chuyên nghiệp. Tạo $count bài viết KHÁC NHAU về "$destinationName".

$locationContext

Mỗi bài PHẢI khác nhau về:
1. Style (review trải nghiệm / hướng dẫn chi tiết / top list / mẹo du lịch)
2. Nhóm địa điểm (mỗi bài tập trung nhóm locations khác nhau)
3. Góc nhìn (ẩm thực / check-in / gia đình / giới trẻ / budget...)

Trả về JSON thuần túy là một MẢNG gồm $count objects:
[
  {
    "id": "slug-tu-tieu-de",
    "heroImage": "",
    "title": "Tiêu đề hấp dẫn tiếng Việt",
    "authorId": "ai-writer",
    "authorName": "AI Travel Writer",
    "authorAvatar": "",
    "fullText": "Nội dung Markdown 800-1200 từ, có ## headings, **bold** tên địa điểm",
    "createdAt": "${DateTime.now().toIso8601String()}",
    "likeCount": 0,
    "commentCount": 0,
    "saveCount": 0,
    "relatedLocationIds": ["id-thuc-te-1", "id-thuc-te-2"],
    "destinationId": "$destinationId",
    "destinationName": "$destinationName",
    "category": "food|places|stay",
    "slug": "slug-tu-tieu-de",
    "status": "draft_ai"
  }
]

QUY TẮC:
- "relatedLocationIds" CHỈ chứa IDs từ danh sách địa điểm trên. Mỗi bài dùng 2-5 locations.
- Mỗi bài có ÍT NHẤT 3 phần ## heading trong fullText.
- Chỉ trả về JSON mảng, không thêm giải thích.
''';

    final resultText = await _callGeminiApi(
      'Tạo $count bài viết du lịch đa dạng cho $destinationName',
      systemPrompt,
    );
    return _parseJsonList(resultText);
  }

  /// Build location context string from existing DB locations.
  String _buildLocationContext(List<Map<String, dynamic>>? locations) {
    if (locations == null || locations.isEmpty) {
      return 'Không có dữ liệu địa điểm sẵn có. Hãy viết dựa trên kiến thức chung.';
    }

    final buffer = StringBuffer();
    buffer.writeln(
      'Dưới đây là ${locations.length} địa điểm THỰC TẾ đang có trong hệ thống. '
      'Hãy viết bài DỰA TRÊN các địa điểm này:',
    );
    for (final loc in locations) {
      buffer.writeln(
        '- ID: "${loc['id']}" | ${loc['name']} | ${loc['category']} | '
        '${(loc['tags'] as List?)?.join(', ') ?? ''} | ★${loc['rating'] ?? 'N/A'} '
        '| ${loc['address'] ?? ''}',
      );
    }
    return buffer.toString();
  }

  /// Get style-specific writing instructions.
  String _getStyleInstructions(String style) {
    switch (style) {
      case 'guide':
        return '''
Style: HƯỚNG DẪN DU LỊCH CHI TIẾT (1000-1500 từ)
- Cấu trúc: ## Tổng quan → ## Di chuyển → ## Các điểm phải đến → ## Ẩm thực → ## Mẹo hữu ích
- Thông tin thực tế: giá vé, giờ mở cửa, cách đi lại
- Gợi ý lịch trình theo ngày nếu phù hợp''';
      case 'top-list':
        return '''
Style: TOP LIST (600-1000 từ)
- Cấu trúc: ## Giới thiệu → ## 1. Tên địa điểm → ## 2. ... → ## Kết luận
- Mỗi mục: mô tả ngắn gọn, điểm nổi bật, giá tham khảo
- Đánh số rõ ràng, dễ đọc lướt''';
      case 'tips':
        return '''
Style: MẸO DU LỊCH THỰC TẾ (500-800 từ)
- Cấu trúc: ## Chuẩn bị → ## Tiết kiệm chi phí → ## Trải nghiệm local → ## Lưu ý quan trọng
- Mẹo thực tế, cụ thể, có thể áp dụng ngay
- Bao gồm mức giá tham khảo, thời điểm tốt nhất''';
      default: // 'review'
        return '''
Style: REVIEW TRẢI NGHIỆM (800-1200 từ)
- Cấu trúc: ## Ấn tượng đầu tiên → ## Trải nghiệm chi tiết → ## Ẩm thực → ## Đánh giá tổng thể
- Viết như người đã đến: cảm xúc, chi tiết cá nhân, so sánh
- Có rating/đánh giá riêng cho từng khía cạnh''';
    }
  }

  // ── JSON Parsing Helpers ────────────────────────────────

  Map<String, dynamic> _parseJson(String raw) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('```json'))
      cleaned = cleaned.replaceFirst('```json\n', '');
    if (cleaned.startsWith('```'))
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
    if (cleaned.endsWith('```'))
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
    return jsonDecode(cleaned.trim()) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> _parseJsonList(String raw) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('```json'))
      cleaned = cleaned.replaceFirst('```json\n', '');
    if (cleaned.startsWith('```'))
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
    if (cleaned.endsWith('```'))
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
    final list = jsonDecode(cleaned.trim()) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }
}
