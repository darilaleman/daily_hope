import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../../data/local/models/daily_text_model.dart';

/// Widget que renderiza la tarjeta para compartir como imagen.
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
    const double canvasHeight = 1080;
    const double canvasWidth = 1080;

    return Container(
      width: canvasWidth,
      height: canvasHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8DDD0), Color(0xFFD4C4B0)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.wb_sunny_outlined,
              size: 50, color: Color(0xFFB8996A)),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80),
            child: AutoSizeText(
              text.title(language),
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D3D3D),
                height: 1.3,
              ),
              minFontSize: 28,
              maxFontSize: 44,
              stepGranularity: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(width: 80, height: 2, color: const Color(0xFFB8996A)),
          const SizedBox(height: 15),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Center(
                child: AutoSizeText(
                  text.content(language),
                  maxLines: 20,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF3D3D3D),
                    height: 1.6,
                  ),
                  minFontSize: 18,
                  maxFontSize: 60,
                  stepGranularity: 1,
                ),
              ),
            ),
          ),
          if (text.reference(language) != null &&
              text.reference(language)!.isNotEmpty) ...[
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80),
              child: AutoSizeText(
                '— ${text.reference(language)}',
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Color(0xFFB8996A),
                ),
                minFontSize: 16,
                maxFontSize: 26,
                stepGranularity: 1,
              ),
            ),
          ],
          const SizedBox(height: 20),
          _buildBranding(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Construye la sección de branding con logo y nombre de la app
  Widget _buildBranding() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
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
                  size: 35,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              language == 'en' ? 'DAILY HOPE' : 'ESPERANZA DIARIA',
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 3,
                color: Color(0xFFB8996A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              language == 'en'
                  ? 'A message of hope every day'
                  : 'Un mensaje de esperanza cada día',
              style: const TextStyle(
                fontSize: 14,
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
