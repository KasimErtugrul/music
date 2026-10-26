import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/ui/pages/albums_page.dart';
import 'package:resonance/presentation/ui/pages/artists_page.dart';
import 'package:resonance/presentation/ui/pages/folders_page.dart';
import 'package:resonance/presentation/ui/pages/genres_page.dart';
import 'package:resonance/presentation/ui/pages/songs_page.dart';

class LibraryTabsPage extends StatefulWidget {
  const LibraryTabsPage({super.key});

  @override
  State<LibraryTabsPage> createState() => _LibraryTabsPageState();
}

class _LibraryTabsPageState extends State<LibraryTabsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final libCtrl = Get.find<LibraryController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Text(
              l10n.tabLibrary,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.libraryLocal,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _isSearching = !_isSearching),
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: l10n.rescanStorage,
            onPressed: libCtrl.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: l10n.libraryOptions,
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              // 1. Search Bar (Animated)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: _isSearching ? 56 : 0,
                child: _isSearching
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: l10n.searchInLibraryHint(libCtrl.songs.length),
                            prefixIcon: const Icon(Icons.manage_search, size: 20),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() => _isSearching = false),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerLow,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                      )
                    : null,
              ),
              // 2. Custom Pill TabBar
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildTab(0, l10n.libraryTabSongs, Icons.music_note, libCtrl.songs.length),
                    _buildTab(1, l10n.libraryTabAlbums, Icons.album, libCtrl.albums.length),
                    _buildTab(2, l10n.libraryTabArtists, Icons.person, libCtrl.artists.length),
                    _buildTab(3, l10n.libraryTabGenres, Icons.category, libCtrl.genres.length),
                    _buildTab(4, l10n.libraryTabFolders, Icons.folder, libCtrl.folders.length),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SongsView(),
          AlbumsPage(),
          ArtistsPage(),
          GenresPage(),
          FoldersPage(),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon, int count) {
    final isSelected = _tabController.index == index;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? theme.colorScheme.onSecondaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                color: isSelected
                    ? theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.7)
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}