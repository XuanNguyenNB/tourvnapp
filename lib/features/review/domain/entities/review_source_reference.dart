class ReviewSourceReference {
  final String title;
  final String url;
  final String? date;
  final String? domain;

  const ReviewSourceReference({
    required this.title,
    required this.url,
    this.date,
    this.domain,
  });

  factory ReviewSourceReference.fromJson(Map<String, dynamic> json) {
    return ReviewSourceReference(
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : (json['url'] as String? ?? '').trim(),
      url: (json['url'] as String? ?? '').trim(),
      date: (json['date'] as String?)?.trim(),
      domain: (json['domain'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'url': url, 'date': date, 'domain': domain};
  }
}
