import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/album_model.dart';
import 'package:resonance/data/models/artist_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/search_controller.dart';
import 'package:resonance/presentation/ui/pages/album_detail_page.dart';
import 'package:resonance/presentation/ui/pages/artist_detail_page.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';
import 'package:resonance/presentation/ui/widgets/song_tile.dart';
import 'package:resonance/presentation/ui/widgets/state_views.dart';

/// Arama sekmesi — M3 tasarım güncellemesi:
/// - Yuvarlak (pill) M3 arama çubuğu + temizle düğmesi
/// - Filtre çipleri: Tümü / Şarkılar / Albümler / Sanatçılar (gerçek sonuç
///   grupları; tasarımdeki "Klasörler" çipi arama API'si klasör döndürmediği
///   için bilinçli olarak eklenmedi)
/// - Gruplanmış sonuçlar: Şarkılar (liste), Albümler (2 sütun kart ızgarası),
///   Sanatçılar (yuvarlak avatar satırları)
/// - Son aramalar: yerel kalıcı geçmiş (terim ekle / tekil sil / tümünü temizle)
/// Sekme içeridir; alt gezinme ve mini oynatıcı kabuk (AdaptiveScaffold)
/// tarafından sağlanır — bu sayfa kendi alt çubuğunu çizmez.
enum _SearchFilter { all, songs, albums, artists }

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  _SearchFilter _filter = _SearchFilter.all;
  AppSearchController? _search;

  AppSearchController get _ctrl => _search ??= Get.find<AppSearchController>();

  @override
  void initState() {
    super.initState();
    _textController.text = _ctrl.query.value;
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _applyQuery(String text) => _ctrl.onQueryChanged(text);

  void _useHistoryTerm(String term) {
    _textController.text = term;
    _applyQuery(term);
    _focusNode.requestFocus();
  }

  void _clearQuery() {
    _textController.clear();
    _applyQuery('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- Sayfa başlığı (tasarımdaki "Ara" üst bandı) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.graphic_eq, size: 24, color: cs.primary),
                  const SizedBox(width: 10),
                  Text(
                    l10n.tabSearch,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            // --- M3 arama çubuğu ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _SearchField(
                controller: _textController,
                focusNode: _focusNode,
                hint: l10n.searchHint,
                onChanged: _applyQuery,
                onClear: _clearQuery,
                onSubmitted: (text) {
                  _ctrl.commitSearch(text);
                  _applyQuery(text);
                },
              ),
            ),
            // --- Filtre çipleri + sonuç sayacı + gruplu sonuçlar ---
            Expanded(
              child: Obx(() {
                final query = _ctrl.query.value.trim();
                if (query.isEmpty) {
                  return _RecentSearches(
                    onUseTerm: _useHistoryTerm,
                    onRemoveTerm: (t) => _ctrl.removeHistoryItem(t),
                    onClearAll: _ctrl.clearHistory,
                  );
                }
                if (_ctrl.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final result = _ctrl.results.value;
                if (result == null || result.isEmpty) {
                  // Şartname 6.17: tasarlanmış boş-sonuç görünümü.
                  // Öneriler kütüphanedeki sanatçılardan türetilir
                  // (dokunma = gerçek arama terimi).
                  final lib = Get.find<LibraryController>();
                  final suggestions = lib.artists
                      .where((a) => a.name != null && !a.isUnknown)
                      .take(4)
                      .map((a) => a.name!)
                      .toList(growable: false);
                  return NoSearchResultsView(
                    query: _textController.text,
                    onClear: () {
                      _textController.clear();
                      _search?.onQueryChanged('');
                      _focusNode.requestFocus();
                    },
                    suggestions: suggestions,
                    onSuggestion: (term) {
                      _textController.text = term;
                      _textController.selection = TextSelection.fromPosition(
                        TextPosition(offset: term.length),
                      );
                      _search?.onQueryChanged(term);
                      _search?.commitSearch(term);
                    },
                  );
                }

                final total =
                    result.songs.length + result.albums.length + result.artists.length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilterChips(
                      filter: _filter,
                      songs: result.songs.length,
                      albums: result.albums.length,
                      artists: result.artists.length,
                      onSelect: (f) => setState(() => _filter = f),
                    ),
                    const SizedBox(height: 4),
                    _ResultBanner(count: total),
                    Expanded(
                      child: _GroupedResults(
                        filter: _filter,
                        songs: result.songs,
                        albums: result.albums,
                        artists: result.artists,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== ARAMA ÇUBUĞU ==========

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    required this.onClear,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;
        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 24, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  textInputAction: TextInputAction.search,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
              if (hasText)
                IconButton(
                  tooltip:
                      AppLocalizations.of(context).commonClear,
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClear,
                ),
            ],
          ),
        );
      },
    );
  }
}

// ========== FİLTRE ÇİPLERİ ==========

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filter,
    required this.songs,
    required this.albums,
    required this.artists,
    required this.onSelect,
  });

  final _SearchFilter filter;
  final int songs;
  final int albums;
  final int artists;
  final ValueChanged<_SearchFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _chip(
              context,
              selected: filter == _SearchFilter.all,
              label: l10n.searchFilterAll,
              icon: Icons.check,
              onTap: () => onSelect(_SearchFilter.all),
            ),
            const SizedBox(width: 8),
            _chip(
              context,
              selected: filter == _SearchFilter.songs,
              label: '${l10n.libraryTabSongs} ($songs)',
              icon: Icons.music_note,
              onTap: () => onSelect(_SearchFilter.songs),
            ),
            const SizedBox(width: 8),
            _chip(
              context,
              selected: filter == _SearchFilter.albums,
              label: '${l10n.libraryTabAlbums} ($albums)',
              icon: Icons.album,
              onTap: () => onSelect(_SearchFilter.albums),
            ),
            const SizedBox(width: 8),
            _chip(
              context,
              selected: filter == _SearchFilter.artists,
              label: '${l10n.libraryTabArtists} ($artists)',
              icon: Icons.person,
              onTap: () => onSelect(_SearchFilter.artists),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required bool selected,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? cs.secondaryContainer : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== SONUÇ SAYACI ==========

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.offline_pin, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.searchResultCount(count),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== GRUPLU SONUÇLAR ==========

class _GroupedResults extends StatelessWidget {
  const _GroupedResults({
    required this.filter,
    required this.songs,
    required this.albums,
    required this.artists,
  });

  final _SearchFilter filter;
  final List<SongModel> songs;
  final List<AlbumModel> albums;
  final List<ArtistModel> artists;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showSongs = filter == _SearchFilter.all || filter == _SearchFilter.songs;
    final showAlbums = filter == _SearchFilter.all || filter == _SearchFilter.albums;
    final showArtists = filter == _SearchFilter.all || filter == _SearchFilter.artists;

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      children: [
        if (showSongs && songs.isNotEmpty) ...[
          _SectionHeader(
            title: l10n.libraryTabSongs.toUpperCase(),
            count: songs.length,
            trailing: _PlayAllButton(songs: songs),
          ),
          ...songs.map(
            (s) => SongTile(song: s, queueContext: songs),
          ),
        ],
        if (showAlbums && albums.isNotEmpty) ...[
          _SectionHeader(
            title: l10n.libraryTabAlbums.toUpperCase(),
            count: albums.length,
          ),
          const SizedBox(height: 4),
          _AlbumGrid(albums: albums),
        ],
        if (showArtists && artists.isNotEmpty) ...[
          _SectionHeader(
            title: l10n.libraryTabArtists.toUpperCase(),
            count: artists.length,
          ),
          ...artists.map((a) => _ArtistRow(artist: a)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.count, this.trailing});
  final String title;
  final int? count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Flexible(
            child: Text(
              count != null ? '$title ($count)' : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class _PlayAllButton extends StatelessWidget {
  const _PlayAllButton({required this.songs});
  final List<SongModel> songs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextButton(
      onPressed: () {
        if (songs.isEmpty) return;
        Get.find<PlayerController>().playSong(songs.first, queue: songs);
      },
      child: Text(l10n.playInOrder),
    );
  }
}

// --- Albüm kartı ızgarası (tasarımdaki 2 sütun kaydırmalı kartlar) ---

class _AlbumGrid extends StatelessWidget {
  const _AlbumGrid({required this.albums});
  final List<AlbumModel> albums;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: albums.length,
      itemBuilder: (context, i) => _AlbumCard(album: albums[i]),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album});
  final AlbumModel album;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.to<void>(
          () => const AlbumDetailPage(),
          arguments: album,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ArtworkImage(
                    songId: album.artworkSongId,
                    fallbackIcon: Icons.album,
                  ),
                  // Oynatma düğmesi: albüm parçalarını yükleyip kuyrukla çalar.
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _AlbumPlayFab(album: album),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    album.title ?? l10n.unknownAlbum,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    album.artist ?? l10n.unknownArtist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumPlayFab extends StatelessWidget {
  const _AlbumPlayFab({required this.album});
  final AlbumModel album;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 44,
      height: 44,
      child: FilledButton(
        onPressed: () async {
          final lib = Get.find<LibraryController>();
          final songs = await lib.songsOfAlbum(album.id);
          if (songs.isEmpty) return;
          if (!context.mounted) return;
          Get.find<PlayerController>()
              .playSong(songs.first, queue: songs);
        },
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
        ),
        child: const Icon(Icons.play_arrow, size: 24),
      ),
    );
  }
}

// --- Sanatçı satırı (yuvarlak avatar + sayaçlar) ---

class _ArtistRow extends StatelessWidget {
  const _ArtistRow({required this.artist});
  final ArtistModel artist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: ArtworkImage(
          songId: artist.artworkSongId,
          size: 52,
          borderRadius: BorderRadius.circular(26),
          fallbackIcon: Icons.person,
        ),
        title: Text(
          artist.name ?? l10n.unknownArtist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${l10n.songCount(artist.songCount)} • ${l10n.albumCount(artist.albumCount)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        onTap: () => Get.to<void>(
          () => const ArtistDetailPage(),
          arguments: artist,
        ),
      ),
    );
  }
}

// ========== SON ARAMALAR ==========

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.onUseTerm,
    required this.onRemoveTerm,
    required this.onClearAll,
  });

  final ValueChanged<String> onUseTerm;
  final ValueChanged<String> onRemoveTerm;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Obx(() {
      final terms = Get.find<AppSearchController>().searchHistory;
      if (terms.isEmpty) {
        return EmptyState(
          icon: Icons.search,
          title: l10n.noSearchYet,
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.history, size: 18, color: cs.outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.searchHistoryTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onClearAll,
                  style: TextButton.styleFrom(foregroundColor: cs.error),
                  child: Text(l10n.clearHistory),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final term in terms)
                  _HistoryChip(
                    term: term,
                    onUse: () => onUseTerm(term),
                    onRemove: () => onRemoveTerm(term),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({required this.term, required this.onUse, required this.onRemove});
  final String term;
  final VoidCallback onUse;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 32,
      padding: const EdgeInsets.only(left: 10, right: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 15, color: cs.outline),
          const SizedBox(width: 6),
          InkWell(
            onTap: onUse,
            child: Text(
              term,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, size: 14, color: cs.outline),
            ),
          ),
        ],
      ),
    );
  }
}
