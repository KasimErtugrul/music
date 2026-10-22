import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/ui/layouts/adaptive_scaffold.dart';
import 'package:resonance/presentation/ui/pages/library_tabs_page.dart';
import 'package:resonance/presentation/ui/pages/playlists/playlists_page.dart';
import 'package:resonance/presentation/ui/pages/search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdaptiveScaffold(
      currentIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      destinations: <NavigationDestination>[
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
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          _HomeTabContent(),
          LibraryTabsPage(),
          PlaylistsPage(),
          SearchPage(), // <- Burası değişti
          _PlaceholderTab(icon: Icons.settings_outlined),
        ],
      ),
    );
  }
}

class _HomeTabContent extends StatelessWidget {
  const _HomeTabContent();

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
          children: <Widget>[
            Text(
              l10n.songCount(1842),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
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
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Icon(
          icon,
          size: 64,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
