import 'dart:math';
import 'package:http/http.dart' as http;

/// Servicio de IA para generar reflexiones en AMBOS idiomas simultáneamente.
///
/// Reglas:
/// - Un solo request genera ES + EN
/// - Nunca se usa para traducir (solo para generar contenido nuevo)
/// - Nunca se llama al cambiar idioma
class AITextService {
  static const String _baseUrl = 'https://text.pollinations.ai/';

  static const List<String> _themesES = [
    'superar momentos difíciles y salir adelante',
    'encontrar fuerza interior cuando todo parece perdido',
    'levantarse después de una caída emocional',
    'confiar en que los días malos son temporales',
    'encontrar esperanza en medio de la adversidad',
    'sanar heridas del pasado y seguir adelante',
    'transformar el dolor en fortaleza',
    'no rendirse cuando los sueños parecen lejanos',
    'encontrar luz al final del túnel',
    'aceptar que está bien no estar bien, pero seguir',
    'el valor de empezar de nuevo cada día',
    'soltar lo que duele y abrazar el presente',
    'creer en uno mismo cuando nadie más lo hace',
    'la resiliencia como camino de vida',
    'encontrar propósito después del fracaso',
    'perdonarse y darse una segunda oportunidad',
    'la valentía de pedir ayuda',
    'celebrar los pequeños avances diarios',
    'aprender a fluir con los cambios de la vida',
    'encontrar paz en medio del caos',
    'la importancia de ser amable contigo mismo',
    'saber que mereces cosas buenas',
    'dejar de compararte y empezar a crecer',
    'el poder de decir hoy lo intento de nuevo',
    'abrazar la incertidumbre con valentía',
  ];

  static const List<String> _themesEN = [
    'overcoming difficult moments and moving forward',
    'finding inner strength when all seems lost',
    'rising up after an emotional fall',
    'trusting that bad days are temporary',
    'finding hope in the midst of adversity',
    'healing past wounds and moving on',
    'transforming pain into strength',
    'not giving up when dreams seem distant',
    'finding light at the end of the tunnel',
    'accepting that it is okay not to be okay, but keep going',
    'the value of starting over every day',
    'letting go of what hurts and embracing the present',
    'believing in yourself when no one else does',
    'resilience as a way of life',
    'finding purpose after failure',
    'forgiving yourself and giving yourself a second chance',
    'the courage to ask for help',
    'celebrating small daily progress',
    'learning to flow with life changes',
    'finding peace in the midst of chaos',
    'the importance of being kind to yourself',
    'knowing that you deserve good things',
    'stop comparing yourself and start growing',
    'the power of saying today I will try again',
    'embracing uncertainty with courage',
  ];

  static const List<String> _fallbackTitlesES = [
    'La Fuerza Que Nace Del Interior',
    'Cada Amanecer Es Una Nueva Oportunidad',
    'El Coraje De Seguir Adelante',
    'Cuando Todo Parece Perdido',
    'La Luz Después De La Tormenta',
    'El Valor De Empezar De Nuevo',
    'Confía En El Proceso',
    'No Estás Solo En Este Camino',
    'La Paz Que Viene Después Del Dolor',
    'El Poder De Una Sonrisa Hoy',
    'Soltar Para Poder Avanzar',
    'La Belleza De Los Pequeños Pasos',
    'Respira Y Sigue Adelante',
    'El Momento Presente Es Tuyo',
    'La Esperanza Nunca Se Apaga',
    'Tu Historia Aún No Termina',
    'El Silencio Que Sana El Alma',
    'Abraza Lo Que Eres Hoy',
    'La Calma Después De La Lucha',
    'Cicatrices Que Cuentan Historias',
  ];

  static const List<String> _fallbackTitlesEN = [
    'The Strength That Comes From Within',
    'Every Dawn Is A New Opportunity',
    'The Courage To Keep Moving Forward',
    'When Everything Seems Lost',
    'The Light After The Storm',
    'The Value Of Starting Over',
    'Trust In The Process',
    'You Are Not Alone On This Path',
    'The Peace That Comes After Pain',
    'The Power Of A Smile Today',
    'Letting Go To Move Forward',
    'The Beauty Of Small Steps',
    'Breathe And Keep Going',
    'The Present Moment Is Yours',
    'Hope Never Fades Away',
    'Your Story Is Not Over Yet',
    'The Silence That Heals The Soul',
    'Embrace Who You Are Today',
    'The Calm After The Struggle',
    'Scars That Tell Stories',
  ];

  /// Genera una reflexión en AMBOS idiomas (ES + EN) en un solo request.
  ///
  /// Retorna un Map con:
  /// - 'titleEs', 'contentEs' (español)
  /// - 'titleEn', 'contentEn' (inglés)
  /// - 'source': 'ai'
  static Future<Map<String, dynamic>?> generateReflectionBilingual() async {
    try {
      final selectedThemeES = _themesES[Random().nextInt(_themesES.length)];
      final selectedThemeEN = _themesEN[Random().nextInt(_themesEN.length)];
      final seed = Random().nextInt(999999);

      final prompt = Uri.encodeComponent(
        'You are a professional writer of motivational phrases.\n\n'
        'Generate an inspiring reflection in BOTH Spanish and English.\n\n'
        'SPANISH THEME: $selectedThemeES\n'
        'ENGLISH THEME: $selectedThemeEN\n\n'
        'Generate TWO reflections following this EXACT format:\n\n'
        'TITLE_ES: [A COMPLETE title in Spanish of 5 to 8 words]\n\n'
        'REFLECTION_ES: [Write a motivational text in Spanish of 80 to 120 words. '
        'It must be warm, hopeful and direct. Speak in second person (tú). '
        'Include a powerful metaphor or image. End with a short and powerful phrase of encouragement.]\n\n'
        'TITLE_EN: [A COMPLETE title in English of 5 to 8 words. Use title case]\n\n'
        'REFLECTION_EN: [Write a motivational text in English of 80 to 120 words. '
        'It must be warm, hopeful and direct. Speak in second person (you). '
        'Include a powerful metaphor or image. End with a short and powerful phrase of encouragement.]\n\n'
        'ABSOLUTE RULES:\n'
        '1. Each TITLE must have BETWEEN 5 AND 8 COMPLETE WORDS\n'
        '2. Each REFLECTION must be between 80 and 120 words\n'
        '3. Do NOT use biblical or religious references\n'
        '4. Do NOT use the word "Amen"\n'
        '5. Do NOT include quotes in titles\n'
        '6. Return ONLY the TITLE_ES/REFLECTION_ES/TITLE_EN/REFLECTION_EN format, nothing else\n\n'
        'Seed: $seed',
      );

      print('🤖 Generating bilingual reflection...');
      final response = await http
          .get(Uri.parse('$_baseUrl$prompt'))
          .timeout(const Duration(seconds: 35));

      if (response.statusCode == 200) {
        final rawText = response.body.trim();
        return _parseBilingualResponse(rawText);
      } else {
        print('❌ AI API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ AI Service exception: $e');
      return null;
    }
  }

  /// Parsea la respuesta bilingüe de la IA
  static Map<String, dynamic> _parseBilingualResponse(String rawText) {
    String titleEs = '';
    String contentEs = '';
    String titleEn = '';
    String contentEn = '';

    // Extraer TITLE_ES
    final titleEsMatch =
        RegExp(r'TITLE_ES:\s*(.+?)(?:\n|$)').firstMatch(rawText);
    if (titleEsMatch != null) {
      titleEs = titleEsMatch.group(1)!.trim();
    }

    // Extraer REFLECTION_ES
    final reflectionEsMatch =
        RegExp(r'REFLECTION_ES:\s*([\s\S]+?)(?=TITLE_EN:|$)')
            .firstMatch(rawText);
    if (reflectionEsMatch != null) {
      contentEs = reflectionEsMatch.group(1)!.trim();
    }

    // Extraer TITLE_EN
    final titleEnMatch =
        RegExp(r'TITLE_EN:\s*(.+?)(?:\n|$)').firstMatch(rawText);
    if (titleEnMatch != null) {
      titleEn = titleEnMatch.group(1)!.trim();
    }

    // Extraer REFLECTION_EN
    final reflectionEnMatch =
        RegExp(r'REFLECTION_EN:\s*([\s\S]+)').firstMatch(rawText);
    if (reflectionEnMatch != null) {
      contentEn = reflectionEnMatch.group(1)!.trim();
    }

    // Validar y limpiar títulos
    if (!_isValidTitle(titleEs)) {
      titleEs = _fallbackTitlesES[Random().nextInt(_fallbackTitlesES.length)];
    }
    titleEs = _cleanAndFormatTitle(titleEs);

    if (!_isValidTitle(titleEn)) {
      titleEn = _fallbackTitlesEN[Random().nextInt(_fallbackTitlesEN.length)];
    }
    titleEn = _cleanAndFormatTitle(titleEn);

    // Limpiar contenidos
    contentEs = _cleanContent(contentEs);
    contentEn = _cleanContent(contentEn);

    return {
      'titleEs': titleEs,
      'contentEs': contentEs,
      'titleEn': titleEn,
      'contentEn': contentEn,
      'source': 'ai',
    };
  }

  static bool _isValidTitle(String title) {
    final cleaned = title.trim();
    if (cleaned.length < 15) return false;
    final words = cleaned.split(RegExp(r'\s+'));
    if (words.length < 4 || words.length > 10) return false;
    final lastWord = words.last.toLowerCase();
    final badEndings = {
      'no',
      'is',
      'that',
      'of',
      'the',
      'a',
      'an',
      'and',
      'or',
      'but'
    };
    if (badEndings.contains(lastWord)) return false;
    return true;
  }

  static String _cleanAndFormatTitle(String title) {
    String cleaned = title.trim();
    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    if (cleaned.startsWith("'") && cleaned.endsWith("'")) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    return cleaned.trim();
  }

  static String _cleanContent(String content) {
    String cleaned = content.trim();
    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    cleaned =
        cleaned.replaceAll(RegExp(r'^TITLE_ES:\s*', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(
        RegExp(r'^REFLECTION_ES:\s*', caseSensitive: false), '');
    cleaned =
        cleaned.replaceAll(RegExp(r'^TITLE_EN:\s*', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(
        RegExp(r'^REFLECTION_EN:\s*', caseSensitive: false), '');
    return cleaned.trim();
  }
}
