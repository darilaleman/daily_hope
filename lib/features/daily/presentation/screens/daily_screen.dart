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
  bool _isPrefetching = false;
  int _prefetchProgress = 0;
  String? _lastLoadedLanguage;

  @override
  void initState() {
    super.initState();
    _setupPrefetchListener();
  }

  void _setupPrefetchListener() {
    _repository.onPrefetchStatusChanged = (isWorking, progress) {
      if (mounted) {
        setState(() {
          _isPrefetching = isWorking;
          _prefetchProgress = progress;
        });
      }
    };
  }

  /// Carga el texto del día para el idioma actual
  /// IMPORTANTE: Solo lee del cache, NO genera IA
  Future<void> _loadText() async {
    if (_dailyText == null) {
      setState(() => _isLoading = true);
    }

    final text = await _repository.getDailyText();
    if (!mounted) return;

    setState(() {
      _dailyText = text;
      _isLoading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Detectar cambio de idioma y recargar desde cache
    final currentLang = ref.read(languageProvider);
    if (_lastLoadedLanguage != currentLang) {
      _lastLoadedLanguage = currentLang;
      _loadText();
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
      case 'oracion':
        return Icons.auto_awesome;
      case 'versiculo':
        return Icons.menu_book;
      default:
        return Icons.wb_sunny_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final t = (String key) => AppTranslations.translate(key, lang);
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
      floatingActionButton: _isPrefetching
          ? FloatingActionButton.small(
              backgroundColor: const Color(0xFFB8996A),
              onPressed: null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_prefetchProgress/2',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : null,
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
          const SizedBox(height: 16),
          Container(width: 30, height: 1, color: const Color(0xFFB8996A)),
          const SizedBox(height: 16),
          Text(
            _dailyText!.title,
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
            _dailyText!.content,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFF3D3D3D),
            ),
          ),
          const SizedBox(height: 16),
          if (_dailyText!.reference != null &&
              _dailyText!.reference!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '— ${_dailyText!.reference}',
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
          onTap: () {
            if (_dailyText != null) {
              ShareUtils.shareText(
                title: _dailyText!.title,
                content: _dailyText!.content,
                reference: _dailyText!.reference,
              );
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
