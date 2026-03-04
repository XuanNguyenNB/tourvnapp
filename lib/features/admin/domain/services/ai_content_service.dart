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

  Future<Map<String, dynamic>> generateReview({
    required String prompt,
    String? destinationId,
    String? destinationName,
  }) async {
    final destContext = destinationId != null
        ? '\nĐiểm đến: $destinationName (ID: $destinationId)'
        : '';

    final systemPrompt =
        '''
Bạn là một travel blogger Việt Nam viết bài du lịch hấp dẫn. Tạo một bài viết dựa trên yêu cầu.$destContext
Trả về JSON thuần túy (KHÔNG có markdown code block), với các trường:
{
  "id": "slug-tu-tieu-de",
  "heroImage": "",
  "title": "Tiêu đề hấp dẫn tiếng Việt",
  "authorId": "ai-writer",
  "authorName": "AI Travel Writer",
  "authorAvatar": "",
  "fullText": "Nội dung bài viết 300-600 từ, viết theo dạng review/blog, sử dụng Markdown",
  "createdAt": "${DateTime.now().toIso8601String()}",
  "likeCount": 0,
  "commentCount": 0,
  "saveCount": 0,
  "relatedLocationIds": [],
  "destinationId": ${destinationId != null ? '"$destinationId"' : 'null'},
  "destinationName": ${destinationName != null ? '"$destinationName"' : 'null'},
  "category": "places",
  "slug": "slug-tu-tieu-de",
  "status": "draft_ai"
}
Chỉ trả về JSON, không thêm giải thích hay markdown.
''';

    final resultText = await _callGeminiApi(
      'Viết bài về: $prompt',
      systemPrompt,
    );
    return _parseJson(resultText);
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
