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
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.graphic_eq,
                color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              l10n.appName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (libCtrl.isLoading.value || homeCtrl.isLoading.value) {
          return const _LoadingView();
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
                    subtitle: l10n.homeLocalRecords,
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
                    style: SongRowStyle.regular,
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
                    leadingIcon: Icons.favorite,
                    leadingIconColor: Theme.of(context).colorScheme.tertiary,
                    songs: homeCtrl.favoriteSongs.toList(),
                    style: SongRowStyle.favorite,
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
                    leadingIcon: Icons.shuffle,
                    subtitleBadge: l10n.homeRandom10,
                    songs: homeCtrl.randomDiscoveries.toList(),
                    style: SongRowStyle.lucky,
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
                    style: SongRowStyle.mostPlayed,
                    playCounts: homeCtrl.mostPlayedCounts,
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
                    totalFollow: libCtrl.artists.length,
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.headphones,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.homeOfflineEngine,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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

// ========== LOADING ==========

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CircularProgressIndicator(strokeWidth: 3),
                Icon(
                  Icons.graphic_eq,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.homeLoadingTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.homeLoadingMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
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
            greeting.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
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
    _controller = PageController(viewportFraction: 0.9);
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
            height: 268,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) {
                setState(() => _currentPage = i);
                _startAutoScroll();
              },
              itemCount: widget.albums.length,
              itemBuilder: (context, i) =>
                  _FeaturedCard(album: widget.albums[i]),
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
                          .primary
                          .withValues(alpha: 0.4),
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
        borderRadius: BorderRadius.circular(28),
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
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  stops: const [0.2, 0.55, 1.0],
                ),
              ),
            ),
            // Audiophile badge
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB8F1D1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.homeMaster.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFB8F1D1),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom meta
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.homeFeaturedSelection.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                        const SizedBox(height: 2),
                        Text(
                          album.artist ?? l10n.unknownArtist,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _playAlbum,
                      child: const SizedBox(
                        width: 52,
                        height: 52,
                        child: Icon(Icons.play_arrow_rounded,
                            color: Colors.black, size: 28),
                      ),
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

// ========== NOW PLAYING HERO ==========

class _HeroNowPlaying extends StatelessWidget {
  const _HeroNowPlaying();

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final playerCtrl = Get.find<PlayerController>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Obx(() {
      final song = playerCtrl.currentSong;
      if (song == null) return const SizedBox.shrink();

      final totalMs = playerCtrl.duration.value.inMilliseconds;
      final currentMs = playerCtrl.position.value.inMilliseconds;
      final progress =
          totalMs > 0 ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Material(
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.85),
          child: InkWell(
            onTap: () => Get.toNamed(AppRoutes.player),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
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
                                  Icons.equalizer,
                                  size: 13,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.homeNowPlaying.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    fontSize: 10,
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
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              '${song.artist ?? l10n.unknownArtist}${song.album != null ? " • ${song.album}" : ""}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer
                                    .withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        iconSize: 42,
                        color: theme.colorScheme.primary,
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          minimumSize: const Size(42, 42),
                          padding: EdgeInsets.zero,
                        ),
                        icon: Icon(
                          playerCtrl.isPlaying.value
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 24,
                        ),
                        onPressed: playerCtrl.togglePlayPause,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 3,
                            backgroundColor:
                                theme.colorScheme.onSurface.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation(
                                theme.colorScheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${_fmt(Duration(milliseconds: currentMs))} / ${_fmt(Duration(milliseconds: totalMs))}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer
                              .withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.music_note,
              count: libCtrl.songs.length,
              label: l10n.libraryTabSongs,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              icon: Icons.album,
              count: libCtrl.albums.length,
              label: l10n.libraryTabAlbums,
              color: theme.colorScheme.tertiary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              icon: Icons.mic,
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
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

// ========== SECTION HEADER ==========

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.leadingIcon,
    this.leadingIconColor,
    this.subtitle,
    this.subtitleBadge,
    this.onSeeAll,
  });

  final String title;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final String? subtitle;
  final String? subtitleBadge;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon,
                size: 20,
                color: leadingIconColor ?? theme.colorScheme.primary),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (subtitleBadge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                subtitleBadge!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (onSeeAll != null)
            TextButton.icon(
              onPressed: onSeeAll,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text(l10n.homeSeeAll),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: theme.colorScheme.primary,
                textStyle: theme.textTheme.labelMedium,
              ),
            ),
        ],
      ),
    );
  }
}

// ========== ALBUM CAROUSEL ==========

class _AlbumCarousel extends StatelessWidget {
  const _AlbumCarousel({
    required this.title,
    required this.albums,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final List<AlbumModel> albums;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, subtitle: subtitle),
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
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ArtworkImage(
                              songId: album.artworkSongId,
                              borderRadius: BorderRadius.circular(16),
                              fallbackIcon: Icons.album_rounded,
                            ),
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        album.title ?? l10n.unknownAlbum,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
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

enum SongRowStyle { regular, favorite, lucky, mostPlayed }

class _SongRowSection extends StatelessWidget {
  const _SongRowSection({
    required this.title,
    required this.songs,
    this.style = SongRowStyle.regular,
    this.leadingIcon,
    this.leadingIconColor,
    this.subtitleBadge,
    this.onSeeAll,
    this.playCounts,
  });

  final String title;
  final List<SongModel> songs;
  final SongRowStyle style;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final String? subtitleBadge;
  final VoidCallback? onSeeAll;
  final Map<int, int>? playCounts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: title,
          leadingIcon: leadingIcon,
          leadingIconColor: leadingIconColor,
          subtitleBadge: subtitleBadge,
          onSeeAll: onSeeAll,
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: songs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _SongCard(
              song: songs[i],
              queue: songs,
              style: style,
              playCount: playCounts?[songs[i].id],
            ),
          ),
        ),
      ],
    );
  }
}

class _SongCard extends StatelessWidget {
  const _SongCard({
    required this.song,
    required this.queue,
    required this.style,
    this.playCount,
  });

  final SongModel song;
  final List<SongModel> queue;
  final SongRowStyle style;
  final int? playCount;

  String? _formatBadge() {
    if (song.path.isEmpty) return null;
    final ext = song.path.split('.').last.toUpperCase();
    const known = {'FLAC', 'MP3', 'M4A', 'OGG', 'WAV', 'AAC', 'OPUS', 'AIFF'};
    return known.contains(ext) && ext.length <= 4 ? ext : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final format = _formatBadge();

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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ArtworkImage(
                    songId: song.id,
                    borderRadius: BorderRadius.circular(16),
                    fallbackIcon: Icons.music_note,
                  ),
                  if (style == SongRowStyle.regular && format != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          format,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  if (style == SongRowStyle.favorite)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.favorite,
                            color: theme.colorScheme.tertiary, size: 14),
                      ),
                    ),
                  if (style == SongRowStyle.mostPlayed && playCount != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.homePlayCountBadge(playCount!),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (style == SongRowStyle.lucky)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.casino,
                                color: theme.colorScheme.primary, size: 11),
                            const SizedBox(width: 3),
                            Text(
                              l10n.homeLucky,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
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
  const _ArtistCarousel({required this.artists, this.totalFollow});
  final List<ArtistModel> artists;
  final int? totalFollow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: l10n.homeYourArtists,
          subtitle: totalFollow != null
              ? l10n.homeFollowCount(totalFollow!)
              : null,
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
                        style: theme.textTheme.labelMedium?.copyWith(
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
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.album,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.homeEmptyTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
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
              icon: const Icon(Icons.folder_open),
              label: Text(l10n.homeScanAndStart),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}