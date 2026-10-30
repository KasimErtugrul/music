import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/utils/duration_extensions.dart';
import 'package:resonance/data/models/album_model.dart';
import 'package:resonance/data/models/artist_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/favorite_controller.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/data/repositories/stats_repository.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';
import 'package:resonance/presentation/ui/widgets/mini_player.dart';
import 'package:resonance/presentation/ui/widgets/song_options_sheet.dart';

/// Sanatçı profili — M3 tasarım güncellemesi:
/// - Hero: yuvarlak avatar + ortam ışıması + yerel rozeti, sanatçı adı,
///   en sık tür çipi (sanatçının şarkılarından türetilir) ve gerçek istatistik
///   hapı (albüm, şarkı, toplam süre + toplam çalma sayısı)
/// - Tümünü Çal / Karıştır aksiyonları
/// - "Popüler Şarkılar": gerçek çalma sayılarına göre ilk 5 (istatistik yoksa
///   kütüphane sırasıyla numaralı liste); her satırda dinlenme sayısı
/// - "Albümler": 2 sütunlu gerçek albüm ızgarası
/// - "Benzer Sanatçılar": aynı en sık türe sahip diğer sanatçılar
///   (kütüphaneden türetilir; en az 3 örnekle tamamlanır)
/// - Alt bilgi kartı: tamamen çevrimdışı taahhüdü
///
/// Tasarımdaki "doğrulanmış rozet", "14 sa dinlendi", EP etiketi, yıl
/// bilgileri ve albüm favori düğmesi; karşılık gelen gerçek veri/özellik
/// olmadığı için bilinçli olarak eklenmedi (dürüstlük notu: README).
class ArtistDetailPage extends StatefulWidget {
  const ArtistDetailPage({super.key});

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> {
  ArtistModel? _artist;
  List<SongModel>? _songs;
  List<AlbumModel>? _albums;
  Map<int, int>? _playCounts;
  List<ArtistModel>? _similar;

  @override
  void initState() {
    super.initState();
    _artist = Get.arguments as ArtistModel?;
    _load();
  }

  Future<void> _load() async {
    final artist = _artist;
    if (artist == null) return;
    final ctrl = Get.find<LibraryController>();
    final songs = await ctrl.songsOfArtist(artist.id);
    final albums = await ctrl.albumsOfArtist(artist.id);
    Map<int, int>? counts;
    try {
      counts = await Get.find<StatsRepository>().getMostPlayedCounts(
        limit: 5000,
      );
    } on Object {
      counts = null; // İstatistik okunamazsa liste normal akışta kalır.
    }
    final similar = await _deriveSimilar(artist, ctrl);
    if (mounted) {
      setState(() {
        _songs = songs;
        _albums = albums;
        _playCounts = counts;
        _similar = similar;
      });
    }
  }

  /// Benzer sanatçılar: bu sanatçının en sık türündeki diğer sanatçılar.
  /// Yeterli aday yoksa şarkı sayısına göre en yakın diğerleri eklenir.
  Future<List<ArtistModel>> _deriveSimilar(
    ArtistModel artist,
    LibraryController ctrl,
  ) async {
    final all = ctrl.artists.toList();
    final others = all
        .where((a) => a.id != artist.id && !a.isUnknown)
        .toList(growable: false);
    if (others.isEmpty) return const <ArtistModel>[];

    final songs = _songs ?? await ctrl.songsOfArtist(artist.id);
    final genreCounts = <String, int>{};
    for (final s in songs) {
      final g = s.genre;
      if (g != null) genreCounts[g] = (genreCounts[g] ?? 0) + 1;
    }
    String? topGenre;
    var best = 0;
    genreCounts.forEach((g, c) {
      if (c > best) {
        best = c;
        topGenre = g;
      }
    });

    List<ArtistModel> result = const <ArtistModel>[];
    if (topGenre != null) {
      // Tür eşleşmesi tüm kütüphane şarkıları üzerinden türetilir.
      final librarySongs = ctrl.songs.toList();
      final genreOfArtist = <String, Set<String>>{};
      for (final s in librarySongs) {
        final a = s.artist;
        final g = s.genre;
        if (a == null || g == null) continue;
        genreOfArtist.putIfAbsent(a, () => <String>{}).add(g);
      }
      final sameGenre = others
          .where((a) => a.name != null && genreOfArtist[a.name]
                  ?.contains(topGenre) ==
              true)
          .toList();
      sameGenre.sort((a, b) => b.songCount.compareTo(a.songCount));
      result = sameGenre;
    }
    if (result.length < 3) {
      final rest = others
          .where((a) => !result.contains(a))
          .toList()
        ..sort((a, b) => b.songCount.compareTo(a.songCount));
      result = [...result, ...rest];
    }
    return result.take(3).toList();
  }

  int get _totalPlays {
    final counts = _playCounts;
    final songs = _songs;
    if (counts == null || songs == null) return 0;
    return songs.fold<int>(0, (sum, s) => sum + (counts[s.id] ?? 0));
  }

  String? get _topGenre {
    final songs = _songs;
    if (songs == null) return null;
    final counts = <String, int>{};
    for (final s in songs) {
      final g = s.genre;
      if (g != null) counts[g] = (counts[g] ?? 0) + 1;
    }
    String? top;
    var best = 0;
    counts.forEach((g, c) {
      if (c > best) {
        best = c;
        top = g;
      }
    });
    return top;
  }

  List<SongModel> get _popularSongs {
    final songs = _songs ?? const <SongModel>[];
    final counts = _playCounts;
    if (counts == null) return songs;
    final sorted = List<SongModel>.of(songs)
      ..sort((a, b) {
        final ca = counts[a.id] ?? 0;
        final cb = counts[b.id] ?? 0;
        if (ca != cb) return cb.compareTo(ca);
        return a.id.compareTo(b.id);
      });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final artist = _artist;
    if (artist == null) {
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
          l10n.artistProfileTitle,
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
                    _ArtistHero(
                      artist: artist,
                      totalPlays: _totalPlays,
                      topGenre: _topGenre,
                      onPlay: () => _playAll(shuffle: false),
                      onShuffle: () => _playAll(shuffle: true),
                    ),
                    _PopularSection(
                      songs: _popularSongs.take(5).toList(),
                      playCounts: _playCounts,
                    ),
                    if ((_albums ?? const <AlbumModel>[]).isNotEmpty)
                      _AlbumsGrid(albums: _albums!),
                    if ((_similar ?? const <ArtistModel>[]).isNotEmpty)
                      _SimilarArtists(similar: _similar!),
                    const _OfflineCard(),
                  ],
                ),
    );
  }

  void _playAll({required bool shuffle}) {
    final songs = _songs;
    if (songs == null || songs.isEmpty) return;
    final player = Get.find<PlayerController>();
    if (shuffle && !player.shuffleEnabled.value) {
      player.toggleShuffle();
    }
    final first = shuffle
        ? songs[DateTime.now().millisecond % songs.length]
        : songs.first;
    player.playSong(first, queue: songs);
  }
}

// ========== HERO ==========

class _ArtistHero extends StatelessWidget {
  const _ArtistHero({
    required this.artist,
    required this.totalPlays,
    required this.topGenre,
    required this.onPlay,
    required this.onShuffle,
  });

  final ArtistModel artist;
  final int totalPlays;
  final String? topGenre;
  final VoidCallback onPlay;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final d = artist.totalDuration;
    final durationText = d.inHours > 0
        ? '${l10n.hoursShort(d.inHours)} ${l10n.minutesShort(d.inMinutes.remainder(60))}'
        : l10n.minutesShort(d.inMinutes);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              cs.surfaceContainerHigh.withValues(alpha: 0.6),
              cs.surfaceContainerLow,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Avatar + ışıma + yerel rozeti
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 168,
                      height: 168,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: <Color>[
                            cs.primaryContainer.withValues(alpha: 0.35),
                            cs.tertiaryContainer.withValues(alpha: 0.12),
                            cs.primaryContainer.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 136,
                  height: 136,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: ArtworkImage(
                      songId: artist.artworkSongId,
                      fallbackIcon: Icons.person,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.sd_card, size: 16, color: cs.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              artist.name ?? l10n.unknownArtist,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
            if (topGenre != null) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.graphic_eq,
                        size: 14, color: cs.onSecondaryContainer),
                    const SizedBox(width: 5),
                    Text(
                      topGenre!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Gerçek istatistik hapı
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.album, size: 14, color: cs.primary),
                  const SizedBox(width: 4),
                  Text(
                    l10n.albumCount(artist.albumCount),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _dot(cs),
                  Icon(Icons.music_note, size: 14, color: cs.primary),
                  const SizedBox(width: 4),
                  Text(
                    l10n.songCount(artist.songCount),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _dot(cs),
                  Icon(Icons.schedule, size: 14, color: cs.tertiary),
                  const SizedBox(width: 4),
                  Text(
                    durationText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (totalPlays > 0) ...<Widget>[
                    _dot(cs),
                    Icon(Icons.headphones, size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      l10n.playCount(totalPlays),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onPlay,
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
                    onPressed: onShuffle,
                    icon: const Icon(Icons.shuffle, size: 20),
                    label: Text(l10n.shuffleAll),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(ColorScheme cs) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          '•',
          style: TextStyle(color: cs.outline, fontSize: 11),
        ),
      );
}

// ========== POPÜLER ŞARKILAR ==========

class _PopularSection extends StatelessWidget {
  const _PopularSection({required this.songs, required this.playCounts});
  final List<SongModel> songs;
  final Map<int, int>? playCounts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasCounts = playCounts != null &&
        songs.any((s) => (playCounts![s.id] ?? 0) > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Icon(Icons.trending_up, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.artistPopularTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasCounts)
                Text(
                  l10n.artistMostPlayedHint,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        ...songs.asMap().entries.map((e) {
          final plays = playCounts?[e.value.id] ?? 0;
          return _PopularRow(
            rank: e.key + 1,
            song: e.value,
            plays: plays,
            queue: songs,
          );
        }),
      ],
    );
  }
}

class _PopularRow extends StatelessWidget {
  const _PopularRow({
    required this.rank,
    required this.song,
    required this.plays,
    required this.queue,
  });

  final int rank;
  final SongModel song;
  final int plays;
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
            constraints: const BoxConstraints(minHeight: 68),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Sıra / çalan göstergesi
                SizedBox(
                  width: 28,
                  child: isCurrent
                      ? Center(
                          child: Icon(
                            Icons.equalizer,
                            size: 18,
                            color: cs.primary,
                          ),
                        )
                      : Text(
                          rank.toString(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.outline,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ArtworkImage(
                    songId: song.id,
                    borderRadius: BorderRadius.circular(10),
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              song.artist ?? l10n.unknownArtist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            song.duration.clock,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          if (plays > 0) ...<Widget>[
                            const SizedBox(width: 6),
                            Icon(Icons.headphones,
                                size: 13, color: cs.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Text(
                              '$plays',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
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

// ========== ALBÜM IZGARASI ==========

class _AlbumsGrid extends StatelessWidget {
  const _AlbumsGrid({required this.albums});
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            children: [
              Icon(Icons.album_outlined, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.artistAlbumsTitle,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: albums.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, i) => _AlbumCell(album: albums[i]),
          ),
        ),
      ],
    );
  }
}

class _AlbumCell extends StatelessWidget {
  const _AlbumCell({required this.album});
  final AlbumModel album;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.toNamed<void>(
          AppRoutes.albumDetail,
          arguments: album,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ArtworkImage(
                songId: album.artworkSongId,
                fallbackIcon: Icons.album_outlined,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title ?? l10n.unknownAlbum,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.songCount(album.songCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
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

// ========== BENZER SANATÇILAR ==========

class _SimilarArtists extends StatelessWidget {
  const _SimilarArtists({required this.similar});
  final List<ArtistModel> similar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            children: [
              Icon(Icons.group_outlined, size: 18, color: cs.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.artistSimilarTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                l10n.artistSimilarHint,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final a in similar) ...<Widget>[
                Expanded(
                  child: _SimilarCell(artist: a),
                ),
                if (a != similar.last) const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SimilarCell extends StatelessWidget {
  const _SimilarCell({required this.artist});
  final ArtistModel artist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.toNamed<void>(
          AppRoutes.artistDetail,
          arguments: artist,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              SizedBox(
                width: 62,
                height: 62,
                child: ClipOval(
                  child: ArtworkImage(
                    songId: artist.artworkSongId,
                    fallbackIcon: Icons.person,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                artist.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                artist.albumCount.toString(),
                maxLines: 1,
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

// ========== ÇEVRİMDIŞI BİLGİ KARTI ==========

class _OfflineCard extends StatelessWidget {
  const _OfflineCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(Icons.auto_awesome, size: 20, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.libraryLocal,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.artistOfflineNote,
                    style: theme.textTheme.bodySmall?.copyWith(
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