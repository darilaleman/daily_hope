import 'dart:async';
import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _dotsController;
  late AnimationController _phraseController;

  int _currentDots = 0;
  int _currentPhrase = 0;
  Timer? _dotsTimer;
  Timer? _phraseTimer;

  final List<String> _phrases = [
    'Buscando inspiración para ti',
    'Preparando tu mensaje del día',
    'Seleccionando palabras de aliento',
    'Cargando esperanza',
  ];

  @override
  void initState() {
    super.initState();

    // Rotación del sol (lenta, elegante)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Pulso del círculo exterior
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Puntos suspensivos animados
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Transición entre frases
    _phraseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Timer para los puntos
    _dotsTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          _currentDots = (_currentDots + 1) % 4;
        });
      }
    });

    // Timer para rotar frases
    _phraseTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _phraseController.forward().then((_) {
          if (mounted) {
            setState(() {
              _currentPhrase = (_currentPhrase + 1) % _phrases.length;
            });
            _phraseController.reverse();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _dotsController.dispose();
    _phraseController.dispose();
    _dotsTimer?.cancel();
    _phraseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Sol animado con pulso
          _buildAnimatedSun(),

          const SizedBox(height: 40),

          // Título principal
          const Text(
            'ESPERANZA DIARIA',
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 4,
              color: Color(0xFFB8996A),
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          // Línea decorativa animada
          _buildAnimatedLine(),

          const SizedBox(height: 32),

          // Frase rotativa con fade
          _buildRotatingPhrase(),

          const SizedBox(height: 16),

          // Puntos suspensivos animados
          _buildAnimatedDots(),

          const Spacer(flex: 3),

          // Pequeño texto inferior
          const Opacity(
            opacity: 0.5,
            child: Text(
              'Un mensaje nuevo cada día',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF6B6B6B),
                fontStyle: FontStyle.italic,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSun() {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, child) {
        final pulseValue = _pulseController.value; // 0 a 1
        return Stack(
          alignment: Alignment.center,
          children: [
            // Círculo exterior pulsante
            Container(
              width: 120 + (pulseValue * 20),
              height: 120 + (pulseValue * 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB8996A)
                    .withValues(alpha: 0.1 - (pulseValue * 0.05)),
              ),
            ),
            // Segundo círculo
            Container(
              width: 100 + (pulseValue * 10),
              height: 100 + (pulseValue * 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB8996A)
                    .withValues(alpha: 0.15 - (pulseValue * 0.05)),
              ),
            ),
            // Sol rotando
            Transform.rotate(
              angle: _rotationController.value * 2 * 3.1416,
              child: const Icon(
                Icons.wb_sunny,
                size: 60,
                color: Color(0xFFB8996A),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedLine() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 40 + (_pulseController.value * 20),
          height: 1,
          color: const Color(0xFFB8996A)
              .withValues(alpha: 0.5 + _pulseController.value * 0.3),
        );
      },
    );
  }

  Widget _buildRotatingPhrase() {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.3).animate(
        CurvedAnimation(parent: _phraseController, curve: Curves.easeInOut),
      ),
      child: Text(
        _phrases[_currentPhrase],
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF3D3D3D),
          fontStyle: FontStyle.italic,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildAnimatedDots() {
    return Text(
      '.' * _currentDots,
      style: const TextStyle(
        fontSize: 24,
        color: Color(0xFFB8996A),
        letterSpacing: 4,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
