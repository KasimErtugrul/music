import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/ui/pages/albums_page.dart';
import 'package:resonance/presentation/ui/pages/artists_page.dart';
import 'package:resonance/presentation/ui/pages/folders_page.dart';
import 'package:resonance/presentation/ui/pages/genres_page.dart';
import 'package:resonance/presentation/ui/pages/songs_page.dart';
import 'package:resonance/presentation/ui/widgets/library_tab_pills.dart';

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
              // Gün 17.8: sayaçlar LibraryTabPills içinde Obx ile okunur;
              // yükleme bitince rozetler kendiliğinden güncellenir.
              SizedBox(
                height: 48,
                child: LibraryTabPills(
                  controller: libCtrl,
                  tabController: _tabController,
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
}