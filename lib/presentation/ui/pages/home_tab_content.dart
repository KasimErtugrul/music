import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/constants/smart_playlist_keys.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/data/models/album_model.dart';
import 'package:resonance/data/models/artist_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/home_controller.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/pages/smart_playlist_detail_page.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';

class HomeTabContent extends StatelessWidget {
  const HomeTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final libCtrl = Get.find<LibraryController>();
    final homeCtrl = Get.find<HomeController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: Obx(() {
        if (libCtrl.isLoading.value || homeCtrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (libCtrl.songs.isEmpty) {
          return _EmptyState(libCtrl: libCtrl);
        }

        return RefreshIndicator(
          onRefresh: () async {
            await libCtrl.refresh();
            await homeCtrl.loadAll();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _GreetingHeader(
                  greeting: _greeting(l10n),
                  tagline: l10n.homeTagline,
                ),
              ),
              Obx(() {
                if (homeCtrl.featuredAlbums.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: _FeaturedCarousel(
                    albums: homeCtrl.featuredAlbums.toList(),
                  ),
                );
              }),
              const SliverToBoxAdapter(child: _HeroNowPlaying()),
              SliverToBoxAdapter(child: _StatsRow(libCtrl: libCtrl)),
              Obx(() {
                if (homeCtrl.recentlyPlayedAlbums.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: _AlbumCarousel(
                    title: l10n.homeRecentlyPlayed,
                    albums: homeCtrl.recentlyPlayedAlbums.toList(),
                  ),
                );
              }),
              Obx(() {
                if (homeCtrl.recentlyAdded.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: _SongRowSection(
                    title: l10n.recentlyAdded,
                    songs: homeCtrl.recentlyAdded.toList(),
                    onSeeAll: () => Get.to(
                      () => SmartPlaylistDetailPage(
                        keyValue: SmartPlaylistKeys.recentlyAdded,
                        title: l10n.recentlyAdded,
                      ),
                    ),
                  ),
                );
              }),
              Obx(() {
                if (homeCtrl.favoriteSongs.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: _SongRowSection(
                    title: l10n.favorites,
                    songs: homeCtrl.favoriteSongs.toList(),
                    onSeeAll: () => Get.toNamed(AppRoutes.favorites),
                  ),
                );
              }),
              Obx(() {
                if (homeCtrl.randomDiscoveries.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: _SongRowSection(
                    title: l10n.homeDiscover,
                    songs: homeCtrl.randomDiscoveries.toList(),
                  ),
                );
              }),
              Obx(() {
                if (homeCtrl.mostPlayed.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: _SongRowSection(
                    title: l10n.mostPlayed,
                    songs: homeCtrl.mostPlayed.toList(),
                    onSeeAll: () => Get.to(
                      () => SmartPlaylistDetailPage(
                        keyValue: SmartPlaylistKeys.mostPlayed,
                        title: l10n.mostPlayed,
                      ),
                    ),
                  ),
                );
              }),
              if (libCtrl.artists.isNotEmpty)
                SliverToBoxAdapter(
                  child: _ArtistCarousel(
                    artists: libCtrl.artists.take(12).toList(),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      }),
    );
  }

  String _greeting(AppLocalizations l10n) {
    final h = DateTime.now().hour;
    if (h < 6) return l10n.homeGoodNight;
    if (h < 12) return l10n.homeGoodMorning;
    if (h < 18) return l10n.homeGoodAfternoon;
    return l10n.homeGoodEvening;
  }
}

// ========== GREETING ==========

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.greeting, required this.tagline});
  final String greeting;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tagline,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ========== FEATURED CAROUSEL ==========

class _FeaturedCarousel extends StatefulWidget {
  const _FeaturedCarousel({required this.albums});
  final List<AlbumModel> albums;

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (widget.albums.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_currentPage + 1) % widget.albums.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.albums.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        children: [
          SizedBox(
            height: 260,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) {
                setState(() => _currentPage = i);
                _startAutoScroll();
              },
              itemCount: widget.albums.length,
              itemBuilder: (context, i) => _FeaturedCard(album: widget.albums[i]),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.albums.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentPage ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _currentPage
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.album});
  final AlbumModel album;

  Future<void> _playAlbum() async {
    final libCtrl = Get.find<LibraryController>();
    final songs = await libCtrl.songsOfAlbum(album.id);
    if (songs.isEmpty) return;
    await Get.find<PlayerController>().playSong(songs.first, queue: songs);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ArtworkImage(
              songId: album.artworkSongId,
              fit: BoxFit.cover,
              fallbackIcon: Icons.album_rounded,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          album.title ?? l10n.unknownAlbum,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          album.artist ?? l10n.unknownArtist,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _playAlbum,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                      minimumSize: const Size(52, 52),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, size: 26),
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

// ========== NOW PLAYING HERO ==========

class _HeroNowPlaying extends StatelessWidget {
  const _HeroNowPlaying();

  @override
  Widget build(BuildContext context) {
    final playerCtrl = Get.find<PlayerController>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Obx(() {
      final song = playerCtrl.currentSong;
      if (song == null) return const SizedBox.shrink();

      final progress = playerCtrl.duration.value.inMilliseconds > 0
          ? (playerCtrl.position.value.inMilliseconds /
                  playerCtrl.duration.value.inMilliseconds)
              .clamp(0.0, 1.0)
          : 0.0;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Material(
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          color: theme.colorScheme.primaryContainer,
          child: InkWell(
            onTap: () => Get.toNamed(AppRoutes.player),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: ArtworkImage(
                      songId: song.id,
                      borderRadius: BorderRadius.circular(12),
                      fallbackIcon: Icons.music_note,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.graphic_eq,
                              size: 12,
                              color: theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.homeNowPlaying,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.7),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          song.artist ?? l10n.unknownArtist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 3,
                            backgroundColor: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation(
                                theme.colorScheme.onPrimaryContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    iconSize: 42,
                    color: theme.colorScheme.onPrimaryContainer,
                    icon: Icon(
                      playerCtrl.isPlaying.value
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                    ),
                    onPressed: playerCtrl.togglePlayPause,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ========== STATS ROW ==========

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.libCtrl});
  final LibraryController libCtrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.music_note_rounded,
              count: libCtrl.songs.length,
              label: l10n.libraryTabSongs,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.album_rounded,
              count: libCtrl.albums.length,
              label: l10n.libraryTabAlbums,
              color: theme.colorScheme.tertiary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.person_rounded,
              count: libCtrl.artists.length,
              label: l10n.libraryTabArtists,
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ========== ALBUM CAROUSEL (reusable) ==========

class _AlbumCarousel extends StatelessWidget {
  const _AlbumCarousel({required this.title, required this.albums});
  final String title;
  final List<AlbumModel> albums;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: albums.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final album = albums[i];
              return SizedBox(
                width: 148,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      Get.toNamed(AppRoutes.albumDetail, arguments: album),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 148,
                        height: 148,
                        child: ArtworkImage(
                          songId: album.artworkSongId,
                          borderRadius: BorderRadius.circular(12),
                          fallbackIcon: Icons.album_rounded,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        album.title ?? l10n.unknownAlbum,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        album.artist ?? l10n.unknownArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ========== SONG ROW ==========

class _SongRowSection extends StatelessWidget {
  const _SongRowSection({
    required this.title,
    required this.songs,
    this.onSeeAll,
  });

  final String title;
  final List<SongModel> songs;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (onSeeAll != null)
                TextButton(onPressed: onSeeAll, child: Text(l10n.homeSeeAll)),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: songs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) =>
                _SongCard(song: songs[i], queue: songs),
          ),
        ),
      ],
    );
  }
}

class _SongCard extends StatelessWidget {
  const _SongCard({required this.song, required this.queue});
  final SongModel song;
  final List<SongModel> queue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      width: 148,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.find<PlayerController>().playSong(song, queue: queue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 148,
              height: 148,
              child: ArtworkImage(
                songId: song.id,
                borderRadius: BorderRadius.circular(12),
                fallbackIcon: Icons.music_note,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              song.artist ?? l10n.unknownArtist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== ARTIST CAROUSEL ==========

class _ArtistCarousel extends StatelessWidget {
  const _ArtistCarousel({required this.artists});
  final List<ArtistModel> artists;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            l10n.homeYourArtists,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: artists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, i) {
              final artist = artists[i];
              return SizedBox(
                width: 100,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () => Get.toNamed(
                    AppRoutes.artistDetail,
                    arguments: artist,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 88,
                        height: 88,
                        child: ArtworkImage(
                          songId: artist.artworkSongId,
                          borderRadius: BorderRadius.circular(44),
                          fallbackIcon: Icons.person_rounded,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        artist.name ?? l10n.unknownArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ========== EMPTY STATE ==========

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.libCtrl});
  final LibraryController libCtrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.library_music_rounded,
                size: 64,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.homeEmptyTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.homeEmptyMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: libCtrl.refresh,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.homeScanNow),
            ),
          ],
        ),
      ),
    );
  }
}