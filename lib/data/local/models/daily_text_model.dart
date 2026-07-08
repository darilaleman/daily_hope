/// Modelo unificado que contiene el texto diario en AMBOS idiomas.
///
/// Reglas:
/// - Un registro = un día = ambos idiomas
/// - Nunca existe parcialmente traducido
/// - Los getters [title], [content], [reference] devuelven el valor
///   correspondiente al idioma solicitado
/// - Soporta migración automática desde el formato antiguo (un solo idioma)
class DailyTextModel {
  final String id;
  final DateTime date;
  final String source;
  final String category;

  final String titleEs;
  final String contentEs;
  final String? referenceEs;

  final String titleEn;
  final String contentEn;
  final String? referenceEn;

  DailyTextModel({
    required this.id,
    required this.date,
    this.source = 'local',
    this.category = 'reflexion',
    required this.titleEs,
    required this.contentEs,
    this.referenceEs,
    required this.titleEn,
    required this.contentEn,
    this.referenceEn,
  });

  /// Título en el idioma solicitado
  String title(String lang) => lang == 'en' ? titleEn : titleEs;

  /// Contenido en el idioma solicitado
  String content(String lang) => lang == 'en' ? contentEn : contentEs;

  /// Referencia en el idioma solicitado (puede ser null)
  String? reference(String lang) => lang == 'en' ? referenceEn : referenceEs;

  /// Convierte el modelo a JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'source': source,
        'category': category,
        'titleEs': titleEs,
        'contentEs': contentEs,
        'referenceEs': referenceEs,
        'titleEn': titleEn,
        'contentEn': contentEn,
        'referenceEn': referenceEn,
      };

  /// Factory con migración automática desde el formato antiguo.
  factory DailyTextModel.fromJson(Map<String, dynamic> json) {
    final bool isNewFormat =
        json.containsKey('titleEs') || json.containsKey('titleEn');

    if (isNewFormat) {
      return DailyTextModel(
        id: json['id'] as String? ?? '',
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : DateTime.now(),
        source: json['source'] as String? ?? 'local',
        category:
            _normalizeCategory(json['category'] as String? ?? 'reflexion'),
        titleEs: json['titleEs'] as String? ?? '',
        contentEs: json['contentEs'] as String? ?? '',
        referenceEs: json['referenceEs'] as String?,
        titleEn: json['titleEn'] as String? ?? '',
        contentEn: json['contentEn'] as String? ?? '',
        referenceEn: json['referenceEn'] as String?,
      );
    }

    final String oldLang = json['language'] as String? ?? 'es';
    final String oldTitle = json['title'] as String? ?? '';
    final String oldContent = json['content'] as String? ?? '';
    final String? oldRef = json['reference'] as String?;

    return DailyTextModel(
      id: json['id'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      source: json['source'] as String? ?? 'local',
      category: _normalizeCategory(json['category'] as String? ?? 'reflexion'),
      titleEs: oldLang == 'es' ? oldTitle : '',
      contentEs: oldLang == 'es' ? oldContent : '',
      referenceEs: oldLang == 'es' ? oldRef : null,
      titleEn: oldLang == 'en' ? oldTitle : '',
      contentEn: oldLang == 'en' ? oldContent : '',
      referenceEn: oldLang == 'en' ? oldRef : null,
    );
  }

  /// Normaliza categorías antiguas para mantener consistencia interna.
  static String _normalizeCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'oracion':
        return 'prayer';
      case 'reflexion':
      case 'motivacion':
        return 'reflection';
      case 'versiculo':
        return 'verse';
      case 'prayer':
      case 'reflection':
      case 'verse':
      case 'motivation':
        return cat.toLowerCase();
      default:
        return 'reflection';
    }
  }

  /// Crea una copia con los campos del idioma indicado reemplazados.
  DailyTextModel copyWithLang({
    required String lang,
    String? title,
    String? content,
    String? reference,
  }) {
    if (lang == 'en') {
      return DailyTextModel(
        id: id,
        date: date,
        source: source,
        category: category,
        titleEs: titleEs,
        contentEs: contentEs,
        referenceEs: referenceEs,
        titleEn: title ?? titleEn,
        contentEn: content ?? contentEn,
        referenceEn: reference ?? referenceEn,
      );
    } else {
      return DailyTextModel(
        id: id,
        date: date,
        source: source,
        category: category,
        titleEs: title ?? titleEs,
        contentEs: content ?? contentEs,
        referenceEs: reference ?? referenceEs,
        titleEn: titleEn,
        contentEn: contentEn,
        referenceEn: referenceEn,
      );
    }
  }

  /// Verifica si el registro tiene contenido en ambos idiomas.
  bool get isComplete =>
      titleEs.isNotEmpty &&
      contentEs.isNotEmpty &&
      titleEn.isNotEmpty &&
      contentEn.isNotEmpty;

  @override
  String toString() =>
      'DailyTextModel(id: $id, date: $date, complete: $isComplete)';
}
