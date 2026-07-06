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

  /// Comparte el texto como imagen (PNG)
  static Future<void> shareAsImage({
    required DailyTextModel text,
    required String language,
  }) async {
    try {
      // Capturar el widget como imagen
      final Uint8List imageBytes =
          await _screenshotController.captureFromWidget(
        ShareableCard(
          text: text,
          language: language,
        ),
        delay: const Duration(milliseconds: 100),
        pixelRatio: 1.0, // 1080x1080
      );

      // Verificar que se generaron bytes (aunque no sea null, puede estar vacío)
      if (imageBytes.isEmpty) {
        throw Exception('No se pudo generar la imagen');
      }

      // Guardar temporalmente
      final directory = await getTemporaryDirectory();
      final imagePath = File(
          '${directory.path}/daily_hope_${DateTime.now().millisecondsSinceEpoch}.png');
      await imagePath.writeAsBytes(imageBytes);

      // Compartir
      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: language == 'en'
            ? '✨ Daily Hope - ${text.title(language)}'
            : '✨ Esperanza Diaria - ${text.title(language)}',
      );

      // Limpiar archivo temporal (opcional, después de compartir)
      await Future.delayed(const Duration(seconds: 5));
      if (await imagePath.exists()) {
        await imagePath.delete();
      }
    } catch (e) {
      print('❌ Error compartiendo imagen: $e');
      // Fallback a compartir texto si falla
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
}
