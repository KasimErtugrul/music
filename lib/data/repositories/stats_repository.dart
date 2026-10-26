import 'package:resonance/core/constants/smart_playlist_keys.dart';
import 'package:resonance/data/datasources/local/daos/history_dao.dart';
import 'package:resonance/data/models/play_stats_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/library_repository.dart';

abstract class StatsRepository {
  Future<List<SongModel>> getSmartPlaylist(String key);

  /// Her şarkı için çalınma sayısı. `songId -> playCount`.
  Future<Map<int, int>> getMostPlayedCounts({int limit = 100});

  Future<PlayStatsModel> getStats();
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
  Future<PlayStatsModel> getStats() async {
    final allHistory = await _historyDao.watchRecent(limit: 100000).first;
    final allSongs = await _libraryRepo.songs();
    final songMap = {for (var s in allSongs) s.id: s};

    final totalPlays = allHistory.length;
    final uniqueSongsPlayed = allHistory.map((h) => h.songId).toSet().length;

    final artistCounts = <String, int>{};
    final genreCounts = <String, int>{};

    for (final play in allHistory) {
      final song = songMap[play.songId];
      if (song != null) {
        if (song.artist != null) {
          artistCounts[song.artist!] = (artistCounts[song.artist!] ?? 0) + 1;
        }
        if (song.genre != null) {
          genreCounts[song.genre!] = (genreCounts[song.genre!] ?? 0) + 1;
        }
      }
    }

    final topArtists = _sortAndTakeTop(artistCounts, 5);
    final topGenres = _sortAndTakeTop(genreCounts, 5);

    return PlayStatsModel(
      totalPlays: totalPlays,
      uniqueSongsPlayed: uniqueSongsPlayed,
      topArtists: topArtists,
      topGenres: topGenres,
    );
  }

  Map<String, int> _sortAndTakeTop(Map<String, int> counts, int limit) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries.take(limit));
  }
}