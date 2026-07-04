import 'package:flutter/material.dart';
import '../../../../data/local/models/daily_text_model.dart';

/// Widget que renderiza la tarjeta para compartir como imagen.
/// Este widget NO se muestra en pantalla, solo se usa para capturar como imagen.
class ShareableCard extends StatelessWidget {
  final DailyTextModel text;
  final String language;

  const ShareableCard({
    super.key,
    required this.text,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080, // Resolución Instagram/Facebook
      height: 1080,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8DDD0), // Beige
            Color(0xFFD4C4B0), // Beige oscuro
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono superior
            const Icon(
              Icons.wb_sunny_outlined,
              size: 60,
              color: Color(0xFFB8996A),
            ),
            const SizedBox(height: 40),

            // Título
            Text(
              text.title(language),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 56,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D3D3D),
                height: 1.3,
                fontFamily: 'PlayfairDisplay',
              ),
            ),
            const SizedBox(height: 40),

            // Línea decorativa
            Container(
              width: 80,
              height: 2,
              color: const Color(0xFFB8996A),
            ),
            const SizedBox(height: 40),

            // Contenido
            Text(
              text.content(language),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                height: 1.6,
                color: Color(0xFF3D3D3D),
              ),
            ),
            const SizedBox(height: 60),

            // Branding
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 24,
                  color: Color(0xFFB8996A),
                ),
                const SizedBox(width: 12),
                Text(
                  language == 'en' ? 'Daily Hope' : 'Esperanza Diaria',
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 3,
                    color: Color(0xFFB8996A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
