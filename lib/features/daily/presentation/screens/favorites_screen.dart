import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/models/daily_text_model.dart';
import '../../../../core/providers/favorites_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/i18n/translations.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/share_utils.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    String t(String key) => AppTranslations.translate(key, lang);
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE8DDD0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3D3D3D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('favorites'),
            style: const TextStyle(color: Color(0xFF3D3D3D))),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border,
                      size: 64, color: Color(0xFFB8996A)),
                  const SizedBox(height: 16),
                  Text(
                    t('no_favorites_yet'),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF6B6B6B),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('tap_heart_to_save'),
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final fav = favorites[index];
                return _buildFavoriteCard(context, fav, lang, t);
              },
            ),
      bottomNavigationBar: _buildBottomNav(context, 1, lang, t),
    );
  }

  Widget _buildFavoriteCard(BuildContext context, DailyTextModel fav,
      String lang, String Function(String) t) {
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
          child: const Icon(
            Icons.favorite,
            color: Color(0xFFB8996A),
            size: 20,
          ),
        ),
        title: Text(
          fav.title(lang),
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
              AppDateUtils.formatDateShort(fav.date, lang),
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
            ),
            const SizedBox(height: 4),
            Text(
              fav.content(lang),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B6B6B)),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFB8996A)),
        onTap: () => _showTextDetail(context, fav, lang, t),
      ),
    );
  }

  /// Muestra el texto completo en un bottom sheet
  void _showTextDetail(BuildContext context, DailyTextModel item, String lang,
      String Function(String) t) {
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
                item.title(lang),
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
                item.content(lang),
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
                  '— ${item.reference(lang)}',
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
                    onTap: () async {
                      Navigator.pop(context);
                      await ShareUtils.shareAsImage(
                        text: item,
                        language: lang,
                      );
                    },
                  ),
                  const SizedBox(width: 40),
                  _actionButton(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    label: t('remove'),
                    onTap: () async {
                      // Cerrar el bottom sheet primero
                      Navigator.pop(context);

                      // Mostrar diálogo de confirmación
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFFF5EDE3),
                          title: Text(
                            t('remove_from_favorites'),
                            style: const TextStyle(color: Color(0xFF3D3D3D)),
                          ),
                          content: Text(
                            t('remove_from_favorites_confirm'),
                            style: const TextStyle(color: Color(0xFF6B6B6B)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                t('cancel'),
                                style:
                                    const TextStyle(color: Color(0xFF6B6B6B)),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                t('remove'),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      // Si confirma, eliminar el favorito
                      if (confirm == true) {
                        await ref
                            .read(favoritesProvider.notifier)
                            .toggleFavorite(item);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t('removed_from_favorites')),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.grey,
                            ),
                          );
                        }
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

  Widget _buildBottomNav(BuildContext context, int currentIndex, String lang,
      String Function(String) t) {
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
        if (index == 2) {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/history');
        }
      },
    );
  }
}
