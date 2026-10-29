import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/utils/duration_extensions.dart';
import 'package:resonance/core/utils/locale_sorter.dart';
import 'package:resonance/data/models/album_model.dart';
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

/// Albüm detayı — M3 tasarım güncellemesi:
/// - Hero kart: ortalanmış büyük kapak ("Yerel" rozetiyle), ortam ışıması,
///   başlık/sanatçı ve gerçek verilere dayalı çipler (şarkı sayısı + toplam
///   süre). Tasarımdaki "yıl" ve "FLAC 96kHz" çipleri, AlbumModel'de yıl ve
///   kodlama bilgisi bulunmadığı için bilinçli olarak eklenmedi.
/// - Aksiyon kümesi: Tümünü Çal (dolu) + Karıştır (tonal). Albüm düzeyinde
///   favori kavrami veri modelinde olmadığı için tasarımdeki kalp düğmesi
///   parça satırlarına taşındı (parça başına favori gerçek bir özellik).
/// - "Parçalar" bölümü: sıralama menüsü (başlık/sanatçı/süre/eklenme),
///   numaralı satırlar, çalan parçada EQ animasyonu, parça başına favori.
/// - Alt tarafta mini oynatıcı.
class AlbumDetailPage extends StatefulWidget {
  const AlbumDetailPage({super.key});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  AlbumModel? _album;
  List<SongModel>? _songs;
  SongSort _sort = const SongSort();

  @override
  void initState() {
    super.initState();
    _album = Get.arguments as AlbumModel?;
    _load();
  }

  Future<void> _load() async {
    final album = _album;
    if (album == null) return;
    final songs = await Get.find<LibraryController>().songsOfAlbum(album.id);
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
        return byTitle; // Albüm içi listede albüm alanı anlamsızdır.
    }
  }

  String _sortLabel(AppLocalizations l10n, SongSort sort) => switch (sort.field) {
    SongSortField.title => l10n.sortFieldTitle,
    SongSortField.artist => l10n.sortFieldArtist,
    SongSortField.duration => l10n.sortFieldDuration,
    SongSortField.dateAdded => l10n.sortFieldDateAdded,
    SongSortField.album => l10n.sortFieldAlbum,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final album = _album;
    if (album == null) {
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
          l10n.albumDetailTitle,
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
                    _HeroSection(album: album),
                    _ActionCluster(songs: _songs!),
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

// ========== HERO KARTI ==========

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.album});
  final AlbumModel album;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Gerçek süre özeti: 1 sa 32 dk / 48 dk biçiminde.
    final d = album.totalDuration;
    final durationText = d.inHours > 0
        ? '${l10n.hoursShort(d.inHours)} ${l10n.minutesShort(d.inMinutes.remainder(60))}'
        : l10n.minutesShort(d.inMinutes);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Kapak + ortam ışıması + "Yerel" rozeti
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Ortam ışıması (tasarımdaki blur efektinin gradyan karşılığı)
                Positioned(
                  top: -18,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: <Color>[
                            cs.primaryContainer.withValues(alpha: 0.35),
                            cs.primaryContainer.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ArtworkImage(
                      songId: album.artworkSongId,
                      fallbackIcon: Icons.album_outlined,
                    ),
                  ),
                ),
                // Çevrimdışı/yerel rozeti
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sd_card, size: 13, color: cs.primary),
                        const SizedBox(width: 4),
                        Text(
                          l10n.libraryLocal.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Başlık + sanatçı
            Text(
              album.title ?? l10n.unknownAlbum,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              album.artist ?? l10n.unknownArtist,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            // Gerçek veri çipleri: şarkı sayısı + toplam süre
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _HeroChip(label: l10n.songCount(album.songCount)),
                _HeroChip(
                  label: durationText,
                  icon: Icons.schedule,
                  highlighted: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, this.icon, this.highlighted = false});
  final String label;
  final IconData? icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlighted ? cs.surfaceContainerHigh : cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: cs.primary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: highlighted ? cs.primary : cs.onSurfaceVariant,
              fontWeight: highlighted ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ========== AKSİYON KÜMESİ ==========

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
              label: Text(l10n.playInOrder),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () async {
                if (songs.isEmpty) return;
                // Karıştır: mevcut mod kapalıysa aç, rastgele bir parçayla
                // başlat (kuyruk sırası shuffle modunda karıştırılır).
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
          ),
        ],
      ),
    );
  }
}

// ========== PARÇALAR BÖLÜMÜ ==========

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
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              Text(
                l10n.albumTracksTitle,
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
              // Sıralama menüsü (songs_page ile aynı dilden hap buton)
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
                    const SongSort(
                      field: SongSortField.duration,
                      direction: SortDirection.descending,
                    ),
                    l10n.sortByDuration,
                  ),
                  _item(
                    context,
                    const SongSort(
                      field: SongSortField.dateAdded,
                      direction: SortDirection.descending,
                    ),
                    l10n.sortByDateAdded,
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

// ========== PARÇA SATIRI ==========

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.index,
    required this.song,
    required this.queue,
  });
  final int index;
  final SongModel song;

  /// Ekran sırasındaki albüm listesi (çalma kuyruğu bağlamı).
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
                // Numara / çalan EQ göstergesi
                SizedBox(
                  width: 32,
                  height: 32,
                  child: isCurrent
                      ? Obx(() => _PlayingIndicator(
                          isPlaying: player.isPlaying.value))
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
                // Parça başına favori (gerçek özellik)
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

// ========== ÇALMA GÖSTERGESİ ==========

class _PlayingIndicator extends StatefulWidget {
  const _PlayingIndicator({required this.isPlaying});
  final bool isPlaying;

  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isPlaying) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PlayingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(color, 0.4, 1.0),
            _bar(color, 0.2, 0.7),
            _bar(color, 0.6, 0.9),
          ],
        );
      },
    );
  }

  Widget _bar(Color color, double min, double max) {
    final height = 6 + 14 * (widget.isPlaying ? min + (max - min) * _controller.value : min);
    return Container(
      width: 3,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
