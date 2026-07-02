import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class BibleApiService {
  static const String _baseUrl = 'https://bible-api.com';

  /// Lista EXPANDIDA de versículos (200+ para máxima variedad)
  static const List<String> _popularVerses = [
    // Salmos
    'psalm 23:1', 'psalm 23:2', 'psalm 23:3', 'psalm 23:4', 'psalm 23:5',
    'psalm 23:6',
    'psalm 27:1', 'psalm 27:4', 'psalm 27:14',
    'psalm 34:8', 'psalm 34:17', 'psalm 34:18',
    'psalm 37:4', 'psalm 37:5', 'psalm 37:7',
    'psalm 46:1', 'psalm 46:10',
    'psalm 51:10', 'psalm 51:11', 'psalm 51:12',
    'psalm 55:22', 'psalm 56:3', 'psalm 56:4',
    'psalm 62:1', 'psalm 62:5', 'psalm 62:8',
    'psalm 73:26',
    'psalm 91:1', 'psalm 91:2', 'psalm 91:4', 'psalm 91:11',
    'psalm 100:4', 'psalm 100:5',
    'psalm 103:1', 'psalm 103:2', 'psalm 103:8', 'psalm 103:12',
    'psalm 118:24',
    'psalm 119:11', 'psalm 119:105', 'psalm 119:114',
    'psalm 121:1', 'psalm 121:2', 'psalm 121:7', 'psalm 121:8',
    'psalm 139:14', 'psalm 139:23', 'psalm 139:24',
    'psalm 143:8', 'psalm 143:10',
    'psalm 145:18',
    'psalm 150:6',

    // Proverbios
    'proverbs 3:5', 'proverbs 3:5-6', 'proverbs 3:6',
    'proverbs 4:23', 'proverbs 4:26',
    'proverbs 11:25',
    'proverbs 16:3', 'proverbs 16:9',
    'proverbs 18:10',
    'proverbs 22:6',
    'proverbs 30:5',
    'proverbs 31:25', 'proverbs 31:26',

    // Eclesiastés
    'ecclesiastes 3:1', 'ecclesiastes 3:11',

    // Isaías
    'isaiah 26:3',
    'isaiah 40:31',
    'isaiah 41:10',
    'isaiah 43:2',
    'isaiah 43:18-19',
    'isaiah 53:5',
    'isaiah 54:17',
    'isaiah 55:8-9',
    'isaiah 58:11',
    'isaiah 61:1',

    // Jeremías
    'jeremiah 29:11',
    'jeremiah 29:13',
    'jeremiah 33:3',

    // Lamentaciones
    'lamentations 3:22-23',
    'lamentations 3:25',

    // Miqueas
    'micah 6:8',

    // Habacuc
    'habakkuk 2:2-3',
    'habakkuk 3:17-18',

    // Mateo
    'matthew 5:14', 'matthew 5:16',
    'matthew 6:25', 'matthew 6:26', 'matthew 6:33', 'matthew 6:34',
    'matthew 7:7', 'matthew 7:8',
    'matthew 11:28', 'matthew 11:29', 'matthew 11:30',
    'matthew 17:20',
    'matthew 19:26',
    'matthew 28:19', 'matthew 28:20',

    // Marcos
    'mark 9:23',
    'mark 10:27',
    'mark 11:24',
    'mark 12:30-31',

    // Lucas
    'luke 1:37',
    'luke 6:31',
    'luke 6:38',
    'luke 11:9',
    'luke 12:32',
    'luke 18:27',

    // Juan
    'john 1:1', 'john 1:12', 'john 1:14',
    'john 3:16', 'john 3:17',
    'john 8:12', 'john 8:32',
    'john 10:10',
    'john 11:25', 'john 11:26',
    'john 13:34', 'john 13:35',
    'john 14:1', 'john 14:6', 'john 14:27',
    'john 15:5', 'john 15:7', 'john 15:13',
    'john 16:13', 'john 16:33',

    // Hechos
    'acts 1:8',
    'acts 2:38',
    'acts 16:31',

    // Romanos
    'romans 3:23',
    'romans 5:1', 'romans 5:8',
    'romans 6:23',
    'romans 8:1',
    'romans 8:18',
    'romans 8:28',
    'romans 8:31', 'romans 8:37', 'romans 8:38-39',
    'romans 10:9', 'romans 10:10',
    'romans 12:2', 'romans 12:12', 'romans 12:21',
    'romans 15:13',

    // 1 Corintios
    '1 corinthians 2:9',
    '1 corinthians 10:13',
    '1 corinthians 13:4', '1 corinthians 13:7', '1 corinthians 13:13',
    '1 corinthians 15:58',
    '1 corinthians 16:13',

    // 2 Corintios
    '2 corinthians 4:16', '2 corinthians 4:17', '2 corinthians 4:18',
    '2 corinthians 5:7', '2 corinthians 5:17', '2 corinthians 5:21',
    '2 corinthians 9:8',
    '2 corinthians 12:9', '2 corinthians 12:10',

    // Gálatas
    'galatians 2:20',
    'galatians 5:22-23',
    'galatians 6:9',

    // Efesios
    'ephesians 2:8', 'ephesians 2:8-9', 'ephesians 2:10',
    'ephesians 3:20', 'ephesians 3:21',
    'ephesians 4:32',
    'ephesians 6:10', 'ephesians 6:11',

    // Filipenses
    'philippians 1:6',
    'philippians 2:3-4',
    'philippians 4:4', 'philippians 4:6', 'philippians 4:7',
    'philippians 4:8', 'philippians 4:13', 'philippians 4:19',

    // Colosenses
    'colossians 3:2', 'colossians 3:13', 'colossians 3:15', 'colossians 3:23',

    // 1 Tesalonicenses
    '1 thessalonians 5:11', '1 thessalonians 5:16-18',

    // 2 Timoteo
    '2 timothy 1:7',
    '2 timothy 4:7',

    // Hebreos
    'hebrews 4:12', 'hebrews 4:16',
    'hebrews 10:25',
    'hebrews 11:1', 'hebrews 11:6',
    'hebrews 12:1', 'hebrews 12:2',
    'hebrews 13:5', 'hebrews 13:6', 'hebrews 13:8',

    // Santiago
    'james 1:2', 'james 1:3', 'james 1:5', 'james 1:17', 'james 1:22',
    'james 4:7', 'james 4:8',
    'james 5:16',

    // 1 Pedro
    '1 peter 2:9',
    '1 peter 3:15',
    '1 peter 5:6', '1 peter 5:7', '1 peter 5:10',

    // 1 Juan
    '1 john 1:9',
    '1 john 3:1',
    '1 john 4:4', '1 john 4:7', '1 john 4:8', '1 john 4:18', '1 john 4:19',

    // Apocalipsis
    'revelation 3:20',
    'revelation 21:4',
    'revelation 22:13',
  ];

  /// Obtiene un versículo ALEATORIO y lo traduce al español
  static Future<Map<String, dynamic>?> getRandomVerse() async {
    final random = Random();
    final index = random.nextInt(_popularVerses.length);
    final reference = _popularVerses[index];
    print('📖 Obteniendo versículo: $reference');
    return getVerse(reference);
  }

  /// Obtiene un versículo por referencia y lo traduce al español
  static Future<Map<String, dynamic>?> getVerse(String reference) async {
    try {
      // SIN parámetro translation (usa WEB por defecto, en inglés)
      final response = await http
          .get(Uri.parse('$_baseUrl/$reference'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final englishText = data['text'] ?? '';
        final englishRef = data['reference'] ?? reference;

        if (englishText.isEmpty) return null;

        // Traducir al español usando Pollinations
        final spanishText = await _translateToSpanish(englishText);
        final spanishRef = await _translateReference(englishRef);

        return {
          'reference': spanishRef ?? englishRef,
          'text': spanishText ?? englishText,
          'original_reference': englishRef,
          'original_text': englishText,
        };
      } else {
        print('❌ Bible API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Bible API exception: $e');
    }
    return null;
  }

  /// Obtiene versículo del día basado en la fecha
  static Future<Map<String, dynamic>?> getVerseOfDay(DateTime date) async {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final index = dayOfYear % _popularVerses.length;
    return getVerse(_popularVerses[index]);
  }

  /// Traduce texto al español usando Pollinations AI
  static Future<String?> _translateToSpanish(String englishText) async {
    try {
      final seed = Random().nextInt(999999);
      final prompt = Uri.encodeComponent(
        'Traduce este versículo bíblico al español de forma natural y reverente. '
        'Devuelve SOLO la traducción, sin explicaciones ni comillas. '
        'Versículo: "$englishText" '
        'Seed: $seed',
      );

      final response = await http
          .get(Uri.parse('https://text.pollinations.ai/$prompt'))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return _cleanQuotes(response.body.trim());
      }

      return null;
    } catch (e) {
      print('Error traduciendo: $e');
      return null;
    }
  }

  /// Traduce la referencia al español (ej: "Psalm 23:1" → "Salmo 23:1")
  static Future<String?> _translateReference(String englishRef) async {
    try {
      final prompt = Uri.encodeComponent(
        'Traduce esta referencia bíblica al español. '
        'Ejemplos: Psalm es Salmo, Proverbs es Proverbios, '
        'John es Juan, Matthew es Mateo, Romans es Romanos, '
        'Genesis es Genesis, Isaiah es Isaias, Jeremiah es Jeremias, '
        '1 Corinthians es 1 Corintios, 2 Corinthians es 2 Corintios, '
        '1 Peter es 1 Pedro, 1 John es 1 Juan, Revelation es Apocalipsis. '
        'Devuelve SOLO la referencia traducida, nada mas. '
        'Referencia: "$englishRef"',
      );

      final response = await http
          .get(Uri.parse('https://text.pollinations.ai/$prompt'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _cleanQuotes(response.body.trim());
      }

      return null;
    } catch (e) {
      print('Error traduciendo referencia: $e');
      return null;
    }
  }

  /// Limpia comillas del inicio y final del texto
  static String _cleanQuotes(String text) {
    String cleaned = text;

    // Quitar comillas dobles al inicio y final
    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }

    // Quitar comillas simples al inicio y final
    if (cleaned.startsWith("'") && cleaned.endsWith("'")) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }

    return cleaned.trim();
  }
}
