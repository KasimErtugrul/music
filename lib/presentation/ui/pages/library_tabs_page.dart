import 'package:flutter/material.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/ui/pages/albums_page.dart';
import 'package:resonance/presentation/ui/pages/artists_page.dart';
import 'package:resonance/presentation/ui/pages/folders_page.dart';
import 'package:resonance/presentation/ui/pages/genres_page.dart';
import 'package:resonance/presentation/ui/pages/songs_page.dart';

/// Kütüphane sekmelerinin barındırıcısı. `HomePage`'in "Library" sekmesinin
/// içeriği. Gün 12'de adaptif yerleşimlere ayrılacak.
class LibraryTabsPage extends StatelessWidget {
  const LibraryTabsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.tabLibrary),
          bottom: TabBar(
            isScrollable: true,
            tabs: <Widget>[
              Tab(text: l10n.libraryTabSongs),
              Tab(text: l10n.libraryTabAlbums),
              Tab(text: l10n.libraryTabArtists),
              Tab(text: l10n.libraryTabGenres),
              Tab(text: l10n.libraryTabFolders),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            SongsPage(),
            AlbumsPage(),
            ArtistsPage(),
            GenresPage(),
            FoldersPage(),
          ],
        ),
      ),
    );
  }
}