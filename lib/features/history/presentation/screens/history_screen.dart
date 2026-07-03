import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/models/daily_text_model.dart';
import '../../../../data/local/hive/hive_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/share_utils.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/i18n/translations.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<DailyTextModel> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory(); // ← Solo se llama UNA vez al iniciar
  }

  // ❌ ELIMINADO: didChangeDependencies() que recargaba datos al cambiar idioma

  void _loadHistory() {
    setState(() {
      _history = HiveService.getHistory();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    String t(String key) => AppTranslations.translate(key, lang);

    return Scaffold(
      backgroundColor: const Color(0xFFE8DDD0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3D3D3D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('history'),
            style: const TextStyle(color: Color(0xFF3D3D3D))),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFF3D3D3D)),
              tooltip: t('clear_history'),
              onPressed: () => _confirmClearHistory(t),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB8996A)))
          : _history.isEmpty
              ? _buildEmptyState(t)
              : _buildHistoryList(t, lang),
      bottomNavigationBar: _buildBottomNav(2, lang, t),
    );
  }

  Widget _buildEmptyState(String Function(String) t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_outlined,
              size: 64, color: Color(0xFFB8996A)),
          const SizedBox(height: 16),
          Text(
            t('no_history_yet'),
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF6B6B6B),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t('texts_will_appear_here'),
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(String Function(String) t, String lang) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        return _buildHistoryCard(item, t, lang);
      },
    );
  }

  Widget _buildHistoryCard(
      DailyTextModel item, String Function(String) t, String lang) {
    return Card(
      color: Colors.white.withValues(alpha: 0.7),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFB8996A).withValues(alpha: 0.2),
          child: Icon(
            _getCategoryIcon(item.category),
            color: const Color(0xFFB8996A),
            size: 20,
          ),
        ),
        title: Text(
          item.title(lang), // ← GETTER POR IDIOMA
          style: const TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Color(0xFF3D3D3D),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              AppDateUtils.formatDate(item.date, lang),
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
            ),
            const SizedBox(height: 4),
            Text(
              item.content(lang), // ← GETTER POR IDIOMA
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B6B6B)),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFB8996A)),
        onTap: () => _showTextDetail(context, item, t, lang),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'prayer': // ← Categorías normalizadas en inglés
        return Icons.auto_awesome;
      case 'verse':
        return Icons.menu_book;
      default:
        return Icons.wb_sunny_outlined;
    }
  }

  void _showTextDetail(BuildContext context, DailyTextModel item,
      String Function(String) t, String lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5EDE3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                color: Colors.grey[300],
                margin: const EdgeInsets.only(bottom: 24),
              ),
              Text(
                AppDateUtils.formatDate(item.date, lang),
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
              ),
              const SizedBox(height: 16),
              Text(
                item.title(lang), // ← GETTER POR IDIOMA
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3D3D3D),
                ),
              ),
              const SizedBox(height: 20),
              Container(width: 40, height: 1, color: const Color(0xFFB8996A)),
              const SizedBox(height: 20),
              Text(
                item.content(lang), // ← GETTER POR IDIOMA
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.7,
                  color: Color(0xFF3D3D3D),
                ),
              ),
              if (item.reference(lang) != null &&
                  item.reference(lang)!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '— ${item.reference(lang)}', // ← GETTER POR IDIOMA
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFB8996A),
                  ),
                ),
              ],
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _actionButton(
                    icon: Icons.share_outlined,
                    label: t('share'),
                    onTap: () {
                      ShareUtils.shareText(
                        title: item.title(lang),
                        content: item.content(lang),
                        reference: item.reference(lang),
                      );
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 40),
                  _actionButton(
                    icon: HiveService.isFavorite(item.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: HiveService.isFavorite(item.id)
                        ? Colors.red
                        : const Color(0xFF6B6B6B),
                    label: HiveService.isFavorite(item.id)
                        ? t('saved')
                        : t('save'),
                    onTap: () async {
                      if (HiveService.isFavorite(item.id)) {
                        await HiveService.removeFavorite(item.id);
                      } else {
                        await HiveService.addFavorite(item);
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(HiveService.isFavorite(item.id)
                                ? t('saved_to_favorites')
                                : t('removed_from_favorites')),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    (color ?? const Color(0xFF6B6B6B)).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child:
                Icon(icon, color: color ?? const Color(0xFF6B6B6B), size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, color: color ?? const Color(0xFF6B6B6B)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory(String Function(String) t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5EDE3),
        title: Text(t('clear_history'),
            style: const TextStyle(color: Color(0xFF3D3D3D))),
        content: Text(t('clear_history_confirm'),
            style: const TextStyle(color: Color(0xFF6B6B6B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel'),
                style: const TextStyle(color: Color(0xFF6B6B6B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HiveService.clearHistory();
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('history_cleared')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildBottomNav(
      int currentIndex, String lang, String Function(String) t) {
    return BottomNavigationBar(
      backgroundColor: Colors.white.withValues(alpha: 0.8),
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
        if (index == 0) Navigator.pop(context);
        if (index == 1) {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/favorites');
        }
      },
    );
  }
}
