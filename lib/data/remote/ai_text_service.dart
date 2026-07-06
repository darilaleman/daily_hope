import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Servicio de IA para generar reflexiones bilingües (ES + EN).
///
/// Estrategia:
/// - PRIMARIO: Groq (rápido, estable, gratis) con múltiples API keys ofuscadas
/// - FALLBACK: Pollinations (gratis, inestable)
/// - Genera 3 días en una sola llamada (más eficiente)
class AITextService {
  // ============ CONFIGURACIÓN ============

  // Groq (primario)
  static const String _groqUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _groqModel = 'llama-3.3-70b-versatile';

  // Pollinations (fallback)
  static const String _pollinationsUrl = 'https://text.pollinations.ai/';

  // MethodChannel para obtener API keys del código nativo
  static const MethodChannel _channel = MethodChannel('daily_hope/api_keys');

  // Cache de claves (solo se obtienen una vez)
  static List<String>? _cachedKeys;
  static int _currentKeyIndex = 0;

  // ============ TEMAS ============

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

  // ============ MÉTODO PRINCIPAL (EL QUE LLAMA EL REPOSITORIO) ============

  /// Genera reflexiones bilingües para múltiples días en una sola llamada.
  ///
  /// Retorna una lista de Maps con:
  /// - 'titleEs', 'contentEs' (español)
  /// - 'titleEn', 'contentEn' (inglés)
  /// - 'source': 'ai'
  static Future<List<Map<String, dynamic>>> generateMultipleDaysBilingual({
    int daysToGenerate = 3,
  }) async {
    // 1. Intentar con Groq (rotando entre múltiples keys)
    final groqResult = await _generateMultipleDaysWithGroq(daysToGenerate);
    if (groqResult.isNotEmpty) return groqResult;

    // 2. Fallback a Pollinations
    print('⚠️ Groq falló (todas las keys), intentando con Pollinations...');
    final pollinationsResult =
        await _generateMultipleDaysWithPollinations(daysToGenerate);
    if (pollinationsResult.isNotEmpty) return pollinationsResult;

    // 3. Todos los servicios fallaron
    print('❌ Todos los servicios de IA fallaron');
    return [];
  }

  // ============ GROQ (PRIMARIO) CON ROTACIÓN DE KEYS ============

  static Future<List<Map<String, dynamic>>> _generateMultipleDaysWithGroq(
      int daysCount) async {
    final keys = await _getGroqKeys();
    if (keys.isEmpty) {
      print('⚠️ [Groq] No hay API keys disponibles');
      return [];
    }

    for (int i = 0; i < keys.length; i++) {
      final keyIndex = (_currentKeyIndex + i) % keys.length;
      final apiKey = keys[keyIndex];

      print('🤖 [Groq] Intentando con key #${keyIndex + 1}/${keys.length}...');
      final result = await _tryRequestWithGroqKey(apiKey, daysCount);

      if (result != null) {
        _currentKeyIndex = (keyIndex + 1) % keys.length;
        return result;
      }
    }

    return [];
  }

  static Future<List<Map<String, dynamic>>?> _tryRequestWithGroqKey(
      String apiKey, int daysCount) async {
    try {
      final prompt = _buildMultiDayPrompt(daysCount);

      print('🤖 [Groq] Generando $daysCount días bilingües...');
      final startTime = DateTime.now();

      final response = await http
          .post(
            Uri.parse(_groqUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': _groqModel,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a professional writer of motivational content in Spanish and English. Always respond in the exact format requested.',
                },
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.8,
              'max_tokens': 3000,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      print('⏱️ [Groq] Respuesta en ${duration}ms');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return _parseMultiDayResponse(content, daysCount);
      } else if (response.statusCode == 429) {
        print('⚠️ [Groq] Key alcanzó límite (429), rotando a la siguiente...');
        return null;
      } else {
        print('❌ [Groq] Error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ [Groq] Excepción: $e');
      return null;
    }
  }

  // ============ POLLINATIONS (FALLBACK) ============

  static Future<List<Map<String, dynamic>>>
      _generateMultipleDaysWithPollinations(int daysCount) async {
    try {
      final seed = Random().nextInt(999999);
      final prompt = Uri.encodeComponent(
          '${_buildMultiDayPrompt(daysCount)}\n\nSeed: $seed');

      print('🤖 [Pollinations] Generando $daysCount días bilingües...');
      final startTime = DateTime.now();

      final response = await http
          .get(Uri.parse('$_pollinationsUrl$prompt'))
          .timeout(const Duration(seconds: 40));

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      print('⏱️ [Pollinations] Respuesta en ${duration}ms');

      if (response.statusCode == 200) {
        final content = response.body.trim();
        return _parseMultiDayResponse(content, daysCount);
      } else {
        print('❌ [Pollinations] Error ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ [Pollinations] Excepción: $e');
      return [];
    }
  }

  // ============ OBTENER API KEYS (NATIVO OFUSCADO) ============

  static Future<List<String>> _getGroqKeys() async {
    if (_cachedKeys != null && _cachedKeys!.isNotEmpty) return _cachedKeys!;

    try {
      final result = await _channel.invokeMethod<List>('getGroqKeys');
      if (result != null && result.isNotEmpty) {
        _cachedKeys = result.cast<String>();
        print('✓ Cargadas ${_cachedKeys!.length} API keys desde código nativo');
        return _cachedKeys!;
      }
    } catch (e) {
      print('⚠️ No se pudieron obtener las API keys nativas: $e');
    }
    return [];
  }

  static void clearKeysCache() {
    _cachedKeys = null;
    _currentKeyIndex = 0;
  }

  // ============ PROMPT ============

  static String _buildMultiDayPrompt(int daysCount) {
    final themes = <String>[];
    for (int i = 0; i < daysCount; i++) {
      final themeES = _themesES[Random().nextInt(_themesES.length)];
      final themeEN = _themesEN[Random().nextInt(_themesEN.length)];
      themes.add('DAY_${i + 1}_ES: $themeES\nDAY_${i + 1}_EN: $themeEN');
    }

    return '''
You are a professional writer of motivational phrases.

Generate $daysCount inspiring reflections in BOTH Spanish and English.

THEMES:
${themes.join('\n')}

Generate $daysCount reflections following this EXACT format for EACH day:

=== DAY 1 ===
TITLE_ES: [A COMPLETE title in Spanish of 5 to 8 words]

REFLECTION_ES: [Write a motivational text in Spanish of 80 to 120 words. It must be warm, hopeful and direct. Speak in second person (tú). Include a powerful metaphor or image. End with a short and powerful phrase of encouragement.]

TITLE_EN: [A COMPLETE title in English of 5 to 8 words. Use title case]

REFLECTION_EN: [Write a motivational text in English of 80 to 120 words. It must be warm, hopeful and direct. Speak in second person (you). Include a powerful metaphor or image. End with a short and powerful phrase of encouragement.]

=== DAY 2 ===
[Same format]

=== DAY 3 ===
[Same format]

[Continue for all $daysCount days]

ABSOLUTE RULES:
1. Each TITLE must have BETWEEN 5 AND 8 COMPLETE WORDS
2. Each REFLECTION must be between 80 and 120 words
3. Do NOT use biblical or religious references
4. Do NOT use the word "Amen"
5. Do NOT include quotes in titles
6. Return ONLY the format shown above, nothing else
7. Generate EXACTLY $daysCount days, no more, no less
''';
  }

  // ============ PARSING ============

  static List<Map<String, dynamic>> _parseMultiDayResponse(
      String rawText, int daysCount) {
    final results = <Map<String, dynamic>>[];

    for (int dayNum = 1; dayNum <= daysCount; dayNum++) {
      final dayPattern = '=== DAY $dayNum ===';
      final nextDayPattern = '=== DAY ${dayNum + 1} ===';

      final dayStart = rawText.indexOf(dayPattern);
      if (dayStart == -1) {
        print('⚠️ No se encontró $dayPattern');
        continue;
      }

      final dayEnd = rawText.indexOf(nextDayPattern);
      final dayContent = dayEnd == -1
          ? rawText.substring(dayStart)
          : rawText.substring(dayStart, dayEnd);

      String titleEs = '';
      String contentEs = '';
      String titleEn = '';
      String contentEn = '';

      final titleEsMatch =
          RegExp(r'TITLE_ES:\s*(.+?)(?:\n|$)').firstMatch(dayContent);
      if (titleEsMatch != null) titleEs = titleEsMatch.group(1)!.trim();

      final reflectionEsMatch =
          RegExp(r'REFLECTION_ES:\s*([\s\S]+?)(?=TITLE_EN:|$)')
              .firstMatch(dayContent);
      if (reflectionEsMatch != null) {
        contentEs = reflectionEsMatch.group(1)!.trim();
      }

      final titleEnMatch =
          RegExp(r'TITLE_EN:\s*(.+?)(?:\n|$)').firstMatch(dayContent);
      if (titleEnMatch != null) titleEn = titleEnMatch.group(1)!.trim();

      final reflectionEnMatch =
          RegExp(r'REFLECTION_EN:\s*([\s\S]+)').firstMatch(dayContent);
      if (reflectionEnMatch != null) {
        contentEn = reflectionEnMatch.group(1)!.trim();
      }

      if (!_isValidTitle(titleEs)) {
        titleEs = _fallbackTitlesES[Random().nextInt(_fallbackTitlesES.length)];
      }
      if (!_isValidTitle(titleEn)) {
        titleEn = _fallbackTitlesEN[Random().nextInt(_fallbackTitlesEN.length)];
      }

      if (_hasContent(contentEs) && _hasContent(contentEn)) {
        results.add({
          'titleEs': _cleanAndFormatTitle(titleEs),
          'contentEs': _cleanContent(contentEs),
          'titleEn': _cleanAndFormatTitle(titleEn),
          'contentEn': _cleanContent(contentEn),
          'source': 'ai',
        });
        print('✓ Día $dayNum procesado correctamente');
      } else {
        print('⚠️ Día $dayNum tiene contenido incompleto, omitiendo');
      }
    }

    return results;
  }

  // ============ VALIDACIONES ============

  static bool _hasContent(dynamic value) {
    if (value == null) return false;
    if (value is! String) return false;
    return value.trim().length >= 10;
  }

  static bool _isValidTitle(String title) {
    final cleaned = title.trim();
    if (cleaned.length < 15) return false;
    final words = cleaned.split(RegExp(r'\s+'));
    if (words.length < 4 || words.length > 10) return false;
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
