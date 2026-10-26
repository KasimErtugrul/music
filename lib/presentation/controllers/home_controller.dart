import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:resonance/core/constants/smart_playlist_keys.dart';
import 'package:resonance/data/models/album_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/favorite_repository.dart';
import 'package:resonance/data/repositories/history_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/stats_repository.dart';

class HomeController extends GetxController {
  HomeController(
    this._statsRepo,
    this._favRepo,
    this._historyRepo,
    this._libraryRepo,
  );

  final StatsRepository _statsRepo;
  final FavoriteRepository _favRepo;
  final HistoryRepository _historyRepo;
  final LibraryRepository _libraryRepo;

  final recentlyAdded = <SongModel>[].obs;
  final mostPlayed = <SongModel>[].obs;
  final neverPlayed = <SongModel>[].obs;
  final favoriteCount = 0.obs;
  final isLoading = true.obs;

  final featuredAlbums = <AlbumModel>[].obs;
  final recentlyPlayedAlbums = <AlbumModel>[].obs;
  final favoriteSongs = <SongModel>[].obs;
  final randomDiscoveries = <SongModel>[].obs;

  /// Şarkı başına toplam çalınma sayısı (En Çok Çalınanlar rozetleri için).
  final mostPlayedCounts = <int, int>{}.obs;

  final _random = Random();
  StreamSubscription<List<int>>? _favSub;

  @override
  void onInit() {
    super.onInit();
    _favSub = _favRepo.watchFavoriteIds().listen((ids) async {
      favoriteCount.value = ids.length;
      await _updateFavoriteSongs(ids);
    });
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _statsRepo.getSmartPlaylist(SmartPlaylistKeys.recentlyAdded),
        _statsRepo.getSmartPlaylist(SmartPlaylistKeys.mostPlayed),
        _statsRepo.getSmartPlaylist(SmartPlaylistKeys.neverPlayed),
        _libraryRepo.albums(),
        _libraryRepo.songs(),
        _statsRepo.getMostPlayedCounts(limit: 100),
      ]);

      final recent = results[0] as List<SongModel>;
      final most = results[1] as List<SongModel>;
      final never = results[2] as List<SongModel>;
      final allAlbums = results[3] as List<AlbumModel>;
      final allSongs = results[4] as List<SongModel>;
      final counts = results[5] as Map<int, int>;

      recentlyAdded.assignAll(recent.take(10));
      mostPlayed.assignAll(most.take(10));
      neverPlayed.assignAll(never.take(10));
      mostPlayedCounts.assignAll(counts);

      final shuffledAlbums = List<AlbumModel>.from(allAlbums)..shuffle(_random);
      featuredAlbums.assignAll(shuffledAlbums.take(8));

      final shuffledNever = List<SongModel>.from(never)..shuffle(_random);
      randomDiscoveries.assignAll(shuffledNever.take(10));

      await _loadRecentlyPlayedAlbums(allAlbums);

      final favIds = await _favRepo.watchFavoriteIds().first;
      favoriteCount.value = favIds.length;
      await _updateFavoriteSongs(favIds, allSongs);
    } catch (e, st) {
      // ignore: avoid_print
      print('HomeController.loadAll: $e\n$st');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadRecentlyPlayedAlbums(List<AlbumModel> allAlbums) async {
    try {
      final history = await _historyRepo.watchRecentHistory(limit: 30).first;
      final albumById = {for (final a in allAlbums) a.id: a};
      final seen = <int>{};
      final albums = <AlbumModel>[];
      for (final song in history) {
        final albumId = song.albumId;
        if (albumId == null || seen.contains(albumId)) continue;
        seen.add(albumId);
        final album = albumById[albumId];
        if (album != null) albums.add(album);
        if (albums.length >= 8) break;
      }
      recentlyPlayedAlbums.assignAll(albums);
    } catch (_) {}
  }

  Future<void> _updateFavoriteSongs(
    List<int> favIds, [
    List<SongModel>? cachedSongs,
  ]) async {
    if (favIds.isEmpty) {
      favoriteSongs.clear();
      return;
    }
    final allSongs = cachedSongs ?? await _libraryRepo.songs();
    final songById = {for (final s in allSongs) s.id: s};
    final favs = <SongModel>[];
    for (final id in favIds) {
      final s = songById[id];
      if (s != null) favs.add(s);
    }
    favoriteSongs.assignAll(favs.take(10));
  }

  @override
  void onClose() {
    _favSub?.cancel();
    super.onClose();
  }
}