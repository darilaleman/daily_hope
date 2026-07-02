import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/favorites_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/i18n/translations.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/share_utils.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                return _buildFavoriteCard(context, ref, fav, lang, t);
              },
            ),
      bottomNavigationBar: _buildBottomNav(context, 1, lang, t),
    );
  }

  Widget _buildFavoriteCard(BuildContext context, WidgetRef ref, dynamic fav,
      String lang, String Function(String) t) {
    return Card(
      color: Colors.white.withValues(alpha: 0.7),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppDateUtils.formatDateShort(fav.date, lang),
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFFB8996A)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 20),
                      color: const Color(0xFF6B6B6B),
                      onPressed: () => ShareUtils.shareText(
                        title: fav.title,
                        content: fav.content,
                        reference: fav.reference,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red.withValues(alpha: 0.6),
                      onPressed: () async {
                        await ref
                            .read(favoritesProvider.notifier)
                            .toggleFavorite(fav);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t('delete_from_favorites')),
                              duration: const Duration(seconds: 1),
                              backgroundColor: Colors.grey,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              fav.title,
              style: const TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D3D3D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fav.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF6B6B6B),
              ),
            ),
          ],
        ),
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
