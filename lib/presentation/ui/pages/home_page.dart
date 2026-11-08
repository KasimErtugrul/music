import 'package:flutter/material.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/ui/layouts/adaptive_scaffold.dart';
import 'package:resonance/presentation/ui/pages/library_tabs_page.dart';
import 'package:resonance/presentation/ui/pages/playlists/playlists_page.dart';
import 'package:resonance/presentation/ui/pages/search_page.dart';
import 'package:resonance/presentation/ui/pages/settings/settings_home_page.dart';
import 'package:resonance/presentation/ui/pages/home_tab_content.dart';

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
          HomeTabContent(),   // ← DEĞİŞTİ (önce _HomeTabContent'ti)
          LibraryTabsPage(),
          PlaylistsPage(),
          SearchPage(), // <- Burası değişti
          SettingsHomePage(), // değişti
        ],
      ),
    );
  }
}



