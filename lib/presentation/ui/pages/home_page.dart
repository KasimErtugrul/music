import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';

/// GEÇİCİ ana sayfa (Gün 1): yalnızca TR/EN metin değişimini göstermek için.
/// Gün 5 ve Gün 12'de gerçek sayfa ve adaptif yerleşimle değiştirilecek.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTurkish = Localizations.localeOf(context).languageCode == 'tr';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.songCount(1842),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(l10n.libraryTabSongs)),
                Chip(label: Text(l10n.libraryTabAlbums)),
                Chip(label: Text(l10n.libraryTabArtists)),
                Chip(label: Text(l10n.libraryTabGenres)),
                Chip(label: Text(l10n.libraryTabFolders)),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  Get.updateLocale(Locale(isTurkish ? 'en' : 'tr')),
              child: Text(l10n.debugLanguageToggle),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.tabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.library_music_outlined),
            selectedIcon: const Icon(Icons.library_music),
            label: l10n.tabLibrary,
          ),
          NavigationDestination(
            icon: const Icon(Icons.queue_music_outlined),
            selectedIcon: const Icon(Icons.queue_music),
            label: l10n.tabPlaylists,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search),
            label: l10n.tabSearch,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.tabSettings,
          ),
        ],
      ),
    );
  }
}
