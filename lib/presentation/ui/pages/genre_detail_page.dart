import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/utils/duration_extensions.dart';
import 'package:resonance/core/utils/locale_sorter.dart';
import 'package:resonance/data/models/album_model.dart';
import 'package:resonance/data/models/genre_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/favorite_controller.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';
import 'package:resonance/presentation/ui/widgets/mini_player.dart';
import 'package:resonance/presentation/ui/widgets/song_options_sheet.dart';

/// Tür detayı — M3 tasarım güncellemesi:
/// - Hero kart: tür adı + gerçek istatistik satırı (şarkı sayısı, toplam
///   süre) + Tümünü Çal / Karıştır aksiyonları
/// - "Bu Türdeki Albümler": türün şarkılarından türetilen gerçek albüm
///   gruplaması (yatay karusel, dokununca albüm detayına gider)
/// - Parça listesi: sıralama menüsü, numaralı satırlar, çalan parçada EQ
///   animasyonu, parça başına favori
/// - Alt tarafta mini oynatıcı
///
/// Tasarımdaki alt-tür filtre çipleri (Retrowave, Dark Synth vb.) EKLENMEDİ:
/// MediaStore tür verisi düz bir listedir, alt tür ayrımı yoktur ve uydurma
/// filtre etiketleri gerçek veriyle eşleşmez.
class GenreDetailPage extends StatefulWidget {
  const GenreDetailPage({super.key});

  @override
  State<GenreDetailPage> createState() => _GenreDetailPageState();
}

class _GenreDetailPageState extends State<GenreDetailPage> {
  GenreModel? _genre;
  List<SongModel>? _songs;
  SongSort _sort = const SongSort();

  @override
  void initState() {
    super.initState();
    _genre = Get.arguments as GenreModel?;
    _load();
  }

  Future<void> _load() async {
    final genre = _genre;
    if (genre == null) return;
    final songs = await Get.find<LibraryController>().songsInGenre(genre.key);
    if (mounted) setState(() => _songs = songs);
  }

  void _applySort(SongSort sort) {
    final songs = _songs;
    final sorted = songs == null
        ? null
        : (List<SongModel>.of(songs)..sort(_comparator(sort)));
    setState(() {
      _sort = sort;
      if (sorted != null) _songs = sorted;
    });
  }

  Comparator<SongModel> _comparator(SongSort sort) {
    final dir = sort.isDescending ? -1 : 1;
    int byTitle(SongModel a, SongModel b) {
      final c = LocaleSorter.collationKey(a.title)
          .compareTo(LocaleSorter.collationKey(b.title));
      return c != 0 ? c : a.id.compareTo(b.id);
    }

    switch (sort.field) {
      case SongSortField.title:
        return (a, b) => dir * byTitle(a, b);
      case SongSortField.artist:
        return (a, b) {
          final an = a.artist;
          final bn = b.artist;
          if (an == null && bn == null) return byTitle(a, b);
          if (an == null) return 1;
          if (bn == null) return -1;
          final c = dir * LocaleSorter.collationKey(an)
              .compareTo(LocaleSorter.collationKey(bn));
          return c != 0 ? c : byTitle(a, b);
        };
      case SongSortField.duration:
        return (a, b) {
          final c = dir * a.durationMs.compareTo(b.durationMs);
          return c != 0 ? c : byTitle(a, b);
        };
      case SongSortField.dateAdded:
        return (a, b) {
          final ma = a.dateAdded?.millisecondsSinceEpoch ?? 0;
          final mb = b.dateAdded?.millisecondsSinceEpoch ?? 0;
          final c = dir * ma.compareTo(mb);
          return c != 0 ? c : byTitle(a, b);
        };
      case SongSortField.album:
        return (a, b) {
          final c = dir * LocaleSorter.collationKey(a.album ?? '')
              .compareTo(LocaleSorter.collationKey(b.album ?? ''));
          return c != 0 ? c : byTitle(a, b);
        };
    }
  }

  String _sortLabel(AppLocalizations l10n, SongSort sort) => switch (sort.field) {
    SongSortField.title => l10n.sortFieldTitle,
    SongSortField.artist => l10n.sortFieldArtist,
    SongSortField.duration => l10n.sortFieldDuration,
    SongSortField.dateAdded => l10n.sortFieldDateAdded,
    SongSortField.album => l10n.sortFieldAlbum,
  };

  /// Türün şarkılarından gerçek albüm gruplaması. Bilinmeyen albüm
  /// kovası (-1) karusele alınmaz.
  List<AlbumModel> _albumsInGenre(List<SongModel> songs) {
    final byId = <int, List<SongModel>>{};
    for (final s in songs) {
      final id = s.albumId;
      final title = s.album;
      if (id == null || id < 0 || title == null) continue;
      byId.putIfAbsent(id, () => <SongModel>[]).add(s);
    }
    final albums = byId.entries.map((e) {
      final list = e.value;
      final totalMs = list.fold<int>(0, (sum, s) => sum + s.durationMs);
      final artistCounts = <String, int>{};
      for (final s in list) {
        final a = s.artist;
        if (a != null) artistCounts[a] = (artistCounts[a] ?? 0) + 1;
      }
      String? topArtist;
      var best = 0;
      artistCounts.forEach((name, count) {
        if (count > best) {
          best = count;
          topArtist = name;
        }
      });
      return AlbumModel(
        id: e.key,
        songCount: list.length,
        totalDurationMs: totalMs,
        title: topArtist == null ? list.first.album : list.first.album,
        artist: topArtist,
        artworkSongId: list.first.id,
      );
    }).toList()
      ..sort((a, b) => b.songCount.compareTo(a.songCount));
    return albums;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final genre = _genre;
    if (genre == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.error_outline,
          title: l10n.libraryLoadErrorTitle,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.genreDetailTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      bottomNavigationBar: const MiniPlayer(),
      body: _songs == null
          ? const Center(child: CircularProgressIndicator())
          : _songs!.isEmpty
              ? EmptyState(
                  icon: Icons.music_off_outlined,
                  title: l10n.libraryEmptySongsTitle,
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _GenreHero(genre: genre, songs: _songs!),
                    _ActionCluster(songs: _songs!),
                    if (_albumsInGenre(_songs!).isNotEmpty)
                      _GenreAlbumsCarousel(albums: _albumsInGenre(_songs!)),
                    _TracksSection(
                      songs: _songs!,
                      sort: _sort,
                      sortLabel: _sortLabel(l10n, _sort),
                      onSort: _applySort,
                    ),
                  ],
                ),
    );
  }
}

// ========== HERO ==========

class _GenreHero extends StatelessWidget {
  const _GenreHero({required this.genre, required this.songs});
  final GenreModel genre;
  final List<SongModel> songs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final totalMs = songs.fold<int>(0, (sum, s) => sum + s.durationMs);
    final d = Duration(milliseconds: totalMs);
    final durationText = d.inHours > 0
        ? '${l10n.hoursShort(d.inHours)} ${l10n.minutesShort(d.inMinutes.remainder(60))}'
        : l10n.minutesShort(d.inMinutes);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rozet: yerel arşiv
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.graphic_eq, size: 14, color: cs.primary),
                  const SizedBox(width: 5),
                  Text(
                    l10n.libraryLocal,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              genre.name ?? l10n.unknownGenre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.songCount(genre.songCount)} • $durationText',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== AKSİYONLAR ==========

class _ActionCluster extends StatelessWidget {
  const _ActionCluster({required this.songs});
  final List<SongModel> songs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final player = Get.find<PlayerController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                if (songs.isEmpty) return;
                player.playSong(songs.first, queue: songs);
              },
              icon: const Icon(Icons.play_arrow, size: 22),
              label: Text(l10n.genrePlayAll),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonalIcon(
            onPressed: () async {
              if (songs.isEmpty) return;
              if (!player.shuffleEnabled.value) {
                await player.toggleShuffle();
              }
              final first = songs[DateTime.now().millisecond % songs.length];
              await player.playSong(first, queue: songs);
            },
            icon: const Icon(Icons.shuffle, size: 20),
            label: Text(l10n.shuffleAll),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== TÜRDEKİ ALBÜMLER KARUSELİ ==========

class _GenreAlbumsCarousel extends StatelessWidget {
  const _GenreAlbumsCarousel({required this.albums});
  final List<AlbumModel> albums;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Row(
            children: [
              Icon(Icons.album_outlined, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.genreAlbumsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                l10n.albumCount(albums.length),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 186,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: albums.length.clamp(0, 12),
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final album = albums[i];
              return _AlbumCard(album: album);
            },
          ),
        ),
      ],
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album});
  final AlbumModel album;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SizedBox(
      width: 140,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Get.toNamed<void>(
            AppRoutes.albumDetail,
            arguments: album,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Material(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        clipBehavior: Clip.antiAlias,
                        child: ArtworkImage(
                          songId: album.artworkSongId,
                          fallbackIcon: Icons.album_outlined,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child:
                            Icon(Icons.album, size: 15, color: cs.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                album.title ?? l10n.unknownAlbum,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                album.artist ?? l10n.unknownArtist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== PARÇA LİSTESİ ==========

class _TracksSection extends StatelessWidget {
  const _TracksSection({
    required this.songs,
    required this.sort,
    required this.sortLabel,
    required this.onSort,
  });

  final List<SongModel> songs;
  final SongSort sort;
  final String sortLabel;
  final ValueChanged<SongSort> onSort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Text(
                l10n.libraryTabSongs,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l10n.songCount(songs.length),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              PopupMenuButton<SongSort>(
                tooltip: l10n.sortBy,
                onSelected: onSort,
                itemBuilder: (context) => <PopupMenuEntry<SongSort>>[
                  _item(context, const SongSort(), l10n.sortByTitleAsc),
                  _item(
                    context,
                    const SongSort(field: SongSortField.artist),
                    l10n.sortByArtist,
                  ),
                  _item(
                    context,
                    const SongSort(field: SongSortField.album),
                    l10n.sortByAlbum,
                  ),
                  _item(
                    context,
                    const SongSort(
                      field: SongSortField.duration,
                      direction: SortDirection.descending,
                    ),
                    l10n.sortByDuration,
                  ),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sort, size: 16, color: cs.primary),
                      const SizedBox(width: 6),
                      Text(
                        sortLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ...songs.asMap().entries.map(
              (e) => _TrackRow(
                index: e.key + 1,
                song: e.value,
                queue: songs,
              ),
            ),
      ],
    );
  }

  PopupMenuItem<SongSort> _item(
    BuildContext context,
    SongSort sort,
    String label,
  ) {
    final selected = sort.field == this.sort.field &&
        sort.direction == this.sort.direction;
    return PopupMenuItem<SongSort>(
      value: sort,
      child: Row(
        children: [
          Icon(
            selected ? Icons.check : Icons.sort,
            size: 18,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.index,
    required this.song,
    required this.queue,
  });
  final int index;
  final SongModel song;
  final List<SongModel> queue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final player = Get.find<PlayerController>();
    final favCtrl = Get.find<FavoriteController>();

    return Obx(() {
      final isCurrent = player.currentItem.value?.id == song.uri;
      final isFav = favCtrl.isFavorite(song.id);

      return Material(
        color: isCurrent ? cs.surfaceContainerHigh : Colors.transparent,
        child: InkWell(
          onTap: () => player.playSong(song, queue: queue),
          onLongPress: () => SongOptionsSheet.show(context, song),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: isCurrent
                      ? Center(
                          child: Icon(
                            Icons.equalizer,
                            size: 18,
                            color: cs.primary,
                          ),
                        )
                      : Center(
                          child: Text(
                            index.toString().padLeft(2, '0'),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.outline,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isCurrent ? cs.primary : cs.onSurface,
                          fontWeight:
                              isCurrent ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${song.artist ?? l10n.unknownArtist} • ${song.duration.clock}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: isFav
                      ? l10n.removeFromFavorites
                      : l10n.addToFavorites,
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: isFav ? cs.tertiary : cs.onSurfaceVariant,
                  ),
                  onPressed: () => favCtrl.toggle(song),
                ),
                IconButton(
                  tooltip: l10n.songInfo,
                  icon: Icon(Icons.more_vert,
                      size: 22, color: cs.onSurfaceVariant),
                  onPressed: () => SongOptionsSheet.show(context, song),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
