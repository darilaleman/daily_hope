import 'package:flutter/material.dart';
import '../../../../data/local/models/daily_text_model.dart';

/// Widget que renderiza la tarjeta para compartir como imagen.
/// Se adapta dinámicamente al tamaño del texto.
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
    // Calcular tamaños de fuente según la longitud del contenido
    final contentLength = text.content(language).length;
    final titleLength = text.title(language).length;

    // Título: más pequeño si es largo
    final double titleFontSize = titleLength > 50 ? 48 : 56;

    // Contenido: ajustar según longitud
    final double contentFontSize;
    if (contentLength < 150) {
      contentFontSize = 36;
    } else if (contentLength < 250) {
      contentFontSize = 30;
    } else if (contentLength < 400) {
      contentFontSize = 26;
    } else {
      contentFontSize = 22;
    }

    // Calcular altura dinámica del canvas
    // Base: 1080 de ancho, altura depende del contenido
    double canvasHeight;
    if (contentLength < 150) {
      canvasHeight = 1080;
    } else if (contentLength < 250) {
      canvasHeight = 1200;
    } else if (contentLength < 400) {
      canvasHeight = 1350;
    } else {
      canvasHeight = 1600;
    }

    return Container(
      width: 1080,
      height: canvasHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8DDD0),
            Color(0xFFD4C4B0),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Contenido principal centrado
          Padding(
            padding: const EdgeInsets.fromLTRB(80, 100, 80, 200),
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
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D3D3D),
                    height: 1.3,
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

                // Contenido - Flexible para evitar desbordamiento
                Flexible(
                  child: Text(
                    text.content(language),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: contentFontSize,
                      height: 1.6,
                      color: const Color(0xFF3D3D3D),
                    ),
                  ),
                ),

                // Referencia (si existe)
                if (text.reference(language) != null &&
                    text.reference(language)!.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  Text(
                    '— ${text.reference(language)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: contentFontSize * 0.7,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFB8996A),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Branding en la parte inferior
          Positioned(
            left: 60,
            right: 60,
            bottom: 60,
            child: _buildBranding(),
          ),
        ],
      ),
    );
  }

  /// Construye el branding con logo + nombre de la app
  Widget _buildBranding() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.wb_sunny,
                  color: Color(0xFFB8996A),
                  size: 40,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              language == 'en' ? 'DAILY HOPE' : 'ESPERANZA DIARIA',
              style: const TextStyle(
                fontSize: 28,
                letterSpacing: 3,
                color: Color(0xFFB8996A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              language == 'en'
                  ? 'A message of hope every day'
                  : 'Un mensaje de esperanza cada día',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B6B6B),
                fontStyle: FontStyle.italic,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
