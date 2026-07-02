import 'package:share_plus/share_plus.dart';

class ShareUtils {
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
