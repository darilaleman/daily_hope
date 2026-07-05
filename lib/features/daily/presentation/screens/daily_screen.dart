import 'package:daily_hope/features/streaks/services/streak_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/models/daily_text_model.dart';
import '../../../../data/repositories/daily_text_repository.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/share_utils.dart';
import '../../../../core/providers/favorites_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/i18n/translations.dart';

class DailyScreen extends ConsumerStatefulWidget {
  const DailyScreen({super.key});

  @override
  ConsumerState<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends ConsumerState<DailyScreen> {
  final DailyTextRepository _repository = DailyTextRepository();
  DailyTextModel? _dailyText;
  bool _isLoading = true;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _setupPrefetchListener();
    _loadText();
  }

  void _setupPrefetchListener() {
    _repository.onPrefetchStatusChanged = (isWorking, progress) {
      if (mounted) {
        setState(() {});
      }
    };
  }

  /// Carga el texto del día UNA sola vez al iniciar
  Future<void> _loadText() async {
    setState(() => _isLoading = true);

    try {
      final text = await _repository.getDailyText();

      // ✅ Marcar hoy como leído (actualiza streak)
      await StreakService.markTodayAsRead();

      // ✅ Cargar el streak actual
      final streak = StreakService.getCurrentStreak();

      if (mounted) {
        setState(() {
          _dailyText = text;
          _currentStreak = streak;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_dailyText == null) return;
    await ref.read(favoritesProvider.notifier).toggleFavorite(_dailyText!);
    if (mounted) {
      final isFav =
          ref.read(favoritesProvider.notifier).isFavorite(_dailyText!.id);
      final lang = ref.read(languageProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.translate(
              isFav ? 'saved_to_favorites' : 'removed_from_favorites', lang)),
          duration: const Duration(seconds: 1),
          backgroundColor: isFav ? const Color(0xFFB8996A) : Colors.grey,
        ),
      );
    }
  }

  String _getSourceLabel(String source, String lang) {
    switch (source) {
      case 'local':
        return AppTranslations.translate('phrase_of_the_day', lang);
      case 'ai':
        return AppTranslations.translate('personalized_reflection', lang);
      default:
        return AppTranslations.translate('phrase_of_the_day', lang);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'prayer':
        return Icons.auto_awesome;
      case 'verse':
        return Icons.menu_book;
      default:
        return Icons.wb_sunny_outlined;
    }
  }

  @override
  void dispose() {
    _repository.onPrefetchStatusChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    String t(String key) => AppTranslations.translate(key, lang);
    final favorites = ref.watch(favoritesProvider);

    final isFavorite = _dailyText != null
        ? favorites.any((fav) => fav.id == _dailyText!.id)
        : false;

    return Scaffold(
      backgroundColor: const Color(0xFFE8DDD0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF3D3D3D)),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB8996A)))
          : _dailyText == null
              ? Center(child: Text(t('no_text_available')))
              : _buildContent(isFavorite, lang, t),
      bottomNavigationBar: _buildBottomNav(0, lang, t),
    );
  }

  Widget _buildContent(
      bool isFavorite, String lang, String Function(String) t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getCategoryIcon(_dailyText!.category),
                size: 20,
                color: const Color(0xFFB8996A),
              ),
              const SizedBox(width: 8),
              Text(
                t('header_title'),
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 2,
                  color: Color(0xFFB8996A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppDateUtils.formatDate(DateTime.now(), lang),
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
          ),

          // ✅ WIDGET DE STREAK (solo si streak > 0)
          if (_currentStreak > 0) ...[
            const SizedBox(height: 12),
            _buildStreakWidget(lang),
          ],

          const SizedBox(height: 16),
          Container(width: 30, height: 1, color: const Color(0xFFB8996A)),
          const SizedBox(height: 16),
          Text(
            _dailyText!.title(lang),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontStyle: FontStyle.italic,
              color: Color(0xFF3D3D3D),
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(width: 30, height: 1, color: const Color(0xFFB8996A)),
          const SizedBox(height: 16),
          Text(
            _dailyText!.content(lang),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFF3D3D3D),
            ),
          ),
          const SizedBox(height: 16),
          if (_dailyText!.reference(lang) != null &&
              _dailyText!.reference(lang)!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '— ${_dailyText!.reference(lang)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFFB8996A),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFB8996A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _getSourceLabel(_dailyText!.source, lang),
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFFB8996A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildActionButtons(isFavorite, lang, t),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Widget que muestra el streak actual
  Widget _buildStreakWidget(String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB8996A),
            Color(0xFFD6B88A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB8996A).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🔥',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 8),
          Text(
            '$_currentStreak ${lang == 'en' ? 'days' : 'días'}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      bool isFavorite, String lang, String Function(String) t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _actionButton(
          icon: isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : const Color(0xFF6B6B6B),
          label: isFavorite ? t('saved') : t('save'),
          onTap: _toggleFavorite,
        ),
        const SizedBox(width: 40),
        _actionButton(
          icon: Icons.share_outlined,
          color: const Color(0xFF6B6B6B),
          label: t('share'),
          onTap: () async {
            if (_dailyText != null) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFB8996A)),
                ),
              );

              await ShareUtils.shareAsImage(
                text: _dailyText!,
                language: lang,
              );

              if (mounted) Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(
      int currentIndex, String lang, String Function(String) t) {
    return BottomNavigationBar(
      backgroundColor: Colors.white.withOpacity(0.8),
      selectedItemColor: const Color(0xFFB8996A),
      unselectedItemColor: const Color(0xFF6B6B6B),
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.wb_sunny_outlined), label: t('tab_today')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_border), label: t('tab_favorites')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.history_outlined), label: t('tab_history')),
      ],
      onTap: (index) {
        if (index == 1) Navigator.pushNamed(context, '/favorites');
        if (index == 2) Navigator.pushNamed(context, '/history');
      },
    );
  }
}
