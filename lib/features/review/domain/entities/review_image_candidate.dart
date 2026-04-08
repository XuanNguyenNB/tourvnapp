class ReviewImageCandidate {
  final String imageUrl;
  final String sourceUrl;
  final String title;
  final String? domain;

  const ReviewImageCandidate({
    required this.imageUrl,
    required this.sourceUrl,
    required this.title,
    this.domain,
  });

  factory ReviewImageCandidate.fromJson(Map<String, dynamic> json) {
    return ReviewImageCandidate(
      imageUrl:
          (json['imageUrl'] as String? ?? json['image_url'] as String? ?? '')
              .trim(),
      sourceUrl:
          (json['sourceUrl'] as String? ??
                  json['source_url'] as String? ??
                  json['origin_url'] as String? ??
                  '')
              .trim(),
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : ((json['sourceUrl'] as String? ??
                    json['source_url'] as String? ??
                    json['origin_url'] as String? ??
                    '')
                .trim()),
      domain: (json['domain'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'sourceUrl': sourceUrl,
      'title': title,
      'domain': domain,
    };
  }
}
