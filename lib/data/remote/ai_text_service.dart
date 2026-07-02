import 'dart:math';
import 'package:http/http.dart' as http;

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

  /// Genera una reflexión en el idioma especificado
  static Future<Map<String, dynamic>?> generateReflection({
    String? theme,
    String language = 'es',
  }) async {
    try {
      final isEN = language == 'en';
      final themes = isEN ? _themesEN : _themesES;
      final fallbackTitles = isEN ? _fallbackTitlesEN : _fallbackTitlesES;

      final selectedTheme = theme ?? themes[Random().nextInt(themes.length)];
      final seed = Random().nextInt(999999);

      final langName = isEN ? 'English' : 'Spanish';

      final prompt = Uri.encodeComponent(
        'You are a professional writer of motivational phrases.\n\n'
        'THEME: $selectedTheme\n\n'
        'Generate an inspiring reflection following this EXACT format:\n\n'
        'TITLE: [A COMPLETE title of 5 to 8 words. '
        'Use title case: first letter of each important word in UPPERCASE. '
        'Examples: "The Strength Born From Pain", '
        "Every Dawn Is A New Opportunity, "
        '"The Courage To Keep Moving Forward"]\n\n'
        'REFLECTION: [Write a motivational text of 80 to 120 words. '
        'It must be warm, hopeful and direct. '
        'Speak in second person (you). '
        'Include a powerful metaphor or image. '
        'End with a short and powerful phrase of encouragement.]\n\n'
        'ABSOLUTE RULES:\n'
        '1. The TITLE must have BETWEEN 5 AND 8 COMPLETE WORDS\n'
        '2. The TITLE must use title case format\n'
        '3. The TITLE must be a COMPLETE phrase, never cut off\n'
        '4. The TITLE must not end with loose words like "no", "is", "that", "of"\n'
        '5. The REFLECTION must be between 80 and 120 words\n'
        '6. The REFLECTION must be in $langName\n'
        '7. Do NOT use biblical or religious references\n'
        '8. Do NOT use the word "Amen"\n'
        '9. Do NOT include quotes in the title\n'
        '10. Return ONLY the TITLE/REFLECTION format, nothing else\n\n'
        'Seed: $seed',
      );

      print('🤖 Generating reflection about: $selectedTheme ($langName)');

      final response = await http
          .get(Uri.parse('$_baseUrl$prompt'))
          .timeout(const Duration(seconds: 35));

      if (response.statusCode == 200) {
        final rawText = response.body.trim();
        return _parseAIResponse(rawText, selectedTheme, fallbackTitles, isEN);
      } else {
        print('❌ AI API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ AI Service exception: $e');
      return null;
    }
  }

  static Map<String, dynamic> _parseAIResponse(String rawText,
      String fallbackTheme, List<String> fallbackTitles, bool isEN) {
    String title = '';
    String content = '';

    final titleMatch = RegExp(r'TITLE:\s*(.+?)(?:\n|$)').firstMatch(rawText);
    if (titleMatch != null) {
      title = titleMatch.group(1)!.trim();
    }

    final reflexionMatch =
        RegExp(r'REFLECTION:\s*([\s\S]+)').firstMatch(rawText);
    if (reflexionMatch != null) {
      content = reflexionMatch.group(1)!.trim();
    }

    if (content.isEmpty) {
      content = rawText;
    }

    if (!_isValidTitle(title)) {
      print('⚠️ Invalid title detected: "$title"');
      title = fallbackTitles[Random().nextInt(fallbackTitles.length)];
    }

    title = _cleanAndFormatTitle(title);
    content = _cleanContent(content);

    return {
      'title': title,
      'content': content,
      'reference': null,
      'source': 'ai',
      'theme': fallbackTheme,
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
    final uppercaseCount = cleaned
        .split('')
        .where((c) => c == c.toUpperCase() && c != c.toLowerCase())
        .length;
    if (uppercaseCount < 2) return false;
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
    final words = cleaned.split(' ');
    final importantWords = {
      'and',
      'or',
      'but',
      'the',
      'a',
      'an',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by'
    };
    final formatted = words.map((word) {
      if (word.isEmpty) return word;
      if (importantWords.contains(word.toLowerCase())) {
        return word.toLowerCase();
      }
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
    return formatted.trim();
  }

  static String _cleanContent(String content) {
    String cleaned = content.trim();
    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    cleaned =
        cleaned.replaceAll(RegExp(r'^TITLE:\s*', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(
        RegExp(r'^REFLECTION:\s*', caseSensitive: false), '');
    return cleaned.trim();
  }
}
