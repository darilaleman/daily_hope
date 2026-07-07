import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/local/models/daily_text_model.dart';
import '../../features/daily/presentation/widgets/shareable_card.dart';

class ShareUtils {
  static final ScreenshotController _screenshotController =
      ScreenshotController();

  /// Comparte el texto como imagen (PNG) sin bloquear la UI.
  static Future<void> shareAsImage({
    required DailyTextModel text,
    required String language,
  }) async {
    try {
      // Capturar el widget como imagen (operación asíncrona necesaria)
      final Uint8List imageBytes =
          await _screenshotController.captureFromWidget(
        ShareableCard(
          text: text,
          language: language,
        ),
        delay: const Duration(milliseconds: 100),
        pixelRatio: 1.0, // 1080x1080
      );

      if (imageBytes.isEmpty) {
        throw Exception('No se pudo generar la imagen');
      }

      // Guardar temporalmente
      final directory = await getTemporaryDirectory();
      final imagePath = File(
          '${directory.path}/daily_hope_${DateTime.now().millisecondsSinceEpoch}.png');
      await imagePath.writeAsBytes(imageBytes);

      // Lanzar el selector de compartir SIN esperar a que el usuario termine.
      // Usamos unawaited para no bloquear el retorno de esta función.
      unawaited(
        Share.shareXFiles(
          [XFile(imagePath.path)],
          text: language == 'en'
              ? '✨ Daily Hope - ${text.title(language)}'
              : '✨ Esperanza Diaria - ${text.title(language)}',
        ).then((_) {
          // Al terminar (compartido o cancelado), borrar el archivo tras un breve retraso
          _deleteFileAfterDelay(imagePath, const Duration(seconds: 2));
        }).catchError((e) {
          // Si falla al compartir, igualmente borrar el archivo
          _deleteFileAfterDelay(imagePath, const Duration(seconds: 1));
        }),
      );

      // Retornamos inmediatamente; el selector de compartir ya se está mostrando.
      return;
    } catch (e) {
      print('❌ Error capturando imagen: $e');
      // Fallback a compartir texto (esta operación sí espera, pero es excepcional)
      await shareText(
        title: text.title(language),
        content: text.content(language),
        reference: text.reference(language),
      );
    }
  }

  /// Compartir como texto (fallback)
  static Future<void> shareText({
    required String title,
    required String content,
    String? reference,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('🌅 $title');
    buffer.writeln('');
    buffer.writeln(content);
    if (reference != null && reference.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('— $reference');
    }
    buffer.writeln('');
    buffer.writeln('✨ Esperanza Diaria');
    await Share.share(buffer.toString());
  }

  /// Elimina un archivo después de un retraso, sin bloquear.
  static void _deleteFileAfterDelay(File file, Duration delay) {
    Future.delayed(delay, () {
      file.delete().catchError((_) => file);
    });
  }
}
