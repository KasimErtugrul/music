import 'package:resonance/core/constants/smart_playlist_keys.dart';
import 'package:resonance/data/datasources/local/daos/history_dao.dart';
import 'package:resonance/data/models/play_stats_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/library_repository.dart';

abstract class StatsRepository {
  Future<List<SongModel>> getSmartPlaylist(String key);

  /// Her şarkı için çalınma sayısı. `songId -> playCount`.
  Future<Map<int, int>> getMostPlayedCounts({int limit = 100});

  /// [since] verilirse yalnızca bu andan sonraki çalmalar sayılır
  /// (null: tüm zamanlar).
  Future<PlayStatsModel> getStats({DateTime? since});

  /// Son [window] içindeki çalmalar (en yeni önce). İstatistik sayfasının
  /// "son çalınanlar" bölümü için zaman damgasıyla döner.
  Future<List<RecentPlay>> getRecentPlays({
    required Duration window,
    int limit = 20,
  });
}

class StatsRepositoryImpl implements StatsRepository {
  StatsRepositoryImpl(this._historyDao, this._libraryRepo);

  final HistoryDao _historyDao;
  final LibraryRepository _libraryRepo;

  @override
  Future<List<SongModel>> getSmartPlaylist(String key) async {
    final allSongs = await _libraryRepo.songs();

    if (key == SmartPlaylistKeys.recentlyAdded) {
      final sorted = List<SongModel>.from(allSongs)
        ..sort((a, b) {
          final dateA = a.dateAdded ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dateB = b.dateAdded ?? DateTime.fromMillisecondsSinceEpoch(0);
          return dateB.compareTo(dateA);
        });
      return sorted.take(100).toList();
    }

    if (key == SmartPlaylistKeys.mostPlayed) {
      final mostPlayedData = await _historyDao.getMostPlayed(limit: 100);
      final songMap = {for (var s in allSongs) s.id: s};
      return mostPlayedData
          .map((data) => songMap[data.songId])
          .whereType<SongModel>()
          .toList();
    }

    if (key == SmartPlaylistKeys.neverPlayed) {
      final allHistory = await _historyDao.watchRecent(limit: 100000).first;
      final playedIds = allHistory.map((h) => h.songId).toSet();
      return allSongs.where((s) => !playedIds.contains(s.id)).toList();
    }

    return [];
  }

  @override
  Future<Map<int, int>> getMostPlayedCounts({int limit = 100}) async {
    final rows = await _historyDao.getMostPlayed(limit: limit);
    return {for (final r in rows) r.songId: r.playCount};
  }

  @override
  Future<PlayStatsModel> getStats({DateTime? since}) async {
    final allHistory = await _historyDao.watchRecent(limit: 100000).first;
    final rows = since == null
        ? allHistory
        : allHistory.where((h) => h.playedAt.isAfter(since)).toList();
    final allSongs = await _libraryRepo.songs();
    final songMap = {for (var s in allSongs) s.id: s};

    final totalPlays = rows.length;
    final uniqueSongsPlayed = rows.map((h) => h.songId).toSet().length;

    final artistCounts = <String, int>{};
    final genreCounts = <String, int>{};
    final songCounts = <int, int>{};
    final weekly = List<int>.filled(7, 0);
    var listenMs = 0;

    for (final play in rows) {
      final song = songMap[play.songId];
      if (song != null) {
        if (song.artist != null) {
          artistCounts[song.artist!] = (artistCounts[song.artist!] ?? 0) + 1;
        }
        if (song.genre != null) {
          genreCounts[song.genre!] = (genreCounts[song.genre!] ?? 0) + 1;
        }
        songCounts[song.id] = (songCounts[song.id] ?? 0) + 1;
        listenMs += song.durationMs;
      }
      // Dart weekday: 1 = Pazartesi ... 7 = Pazar -> 0 tabanlı indeks.
      weekly[play.playedAt.weekday - 1]++;
    }

    final topArtists = _sortAndTakeTop(artistCounts, 5);
    final topGenres = _sortAndTakeTop(genreCounts, 5);

    final topSongEntries = songCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topSongs = <SongStatEntry>[];
    for (final e in topSongEntries.take(5)) {
      final song = songMap[e.key];
      if (song != null) {
        topSongs.add(SongStatEntry(song: song, playCount: e.value));
      }
    }

    return PlayStatsModel(
      totalPlays: totalPlays,
      uniqueSongsPlayed: uniqueSongsPlayed,
      topArtists: topArtists,
      topGenres: topGenres,
      totalListenMs: listenMs,
      weeklyCounts: weekly,
      topSongs: topSongs,
    );
  }

  @override
  Future<List<RecentPlay>> getRecentPlays({
    required Duration window,
    int limit = 20,
  }) async {
    final allHistory = await _historyDao.watchRecent(limit: limit * 3).first;
    final cutoff = DateTime.now().subtract(window);
    final songMap = <int, SongModel>{};
    final result = <RecentPlay>[];
    for (final row in allHistory) {
      if (row.playedAt.isBefore(cutoff)) continue;
      var song = songMap[row.songId];
      if (song == null) {
        final all = await _libraryRepo.songs();
        songMap.addAll({for (var s in all) s.id: s});
        song = songMap[row.songId];
      }
      if (song == null) continue;
      result.add(RecentPlay(song: song, playedAt: row.playedAt));
      if (result.length >= limit) break;
    }
    return result;
  }

  Map<String, int> _sortAndTakeTop(Map<String, int> counts, int limit) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries.take(limit));
  }
}
