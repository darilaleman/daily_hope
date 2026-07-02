class DailyTextModel {
  final String id;
  final String title;
  final String content;
  final String? reference;
  final String language;
  final String category;
  final DateTime date;
  final String source;

  DailyTextModel({
    required this.id,
    required this.title,
    required this.content,
    this.reference,
    this.language = 'es',
    this.category = 'reflexion',
    required this.date,
    this.source = 'local',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'reference': reference,
        'language': language,
        'category': category,
        'date': date.toIso8601String(),
        'source': source,
      };

  factory DailyTextModel.fromJson(Map<String, dynamic> json) {
    return DailyTextModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      reference: json['reference'],
      language: json['language'] ?? 'es',
      category: json['category'] ?? 'reflexion',
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      source: json['source'] ?? 'local',
    );
  }
}
