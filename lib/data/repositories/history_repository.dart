import 'package:resonance/data/datasources/local/daos/history_dao.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/library_repository.dart';

abstract class HistoryRepository {
  Future<void> recordPlay(SongModel song);
  Stream<List<SongModel>> watchRecentHistory({int limit = 100});
  Future<void> clearHistory();
}

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._dao, this._libraryRepo);
  final HistoryDao _dao;
  final LibraryRepository _libraryRepo;

  @override
  Future<void> recordPlay(SongModel song) => _dao.recordPlay(song);

  @override
  Future<void> clearHistory() => _dao.clear();

  @override
  Stream<List<SongModel>> watchRecentHistory({int limit = 100}) {
    return _dao.watchRecent(limit: limit).asyncMap((rows) async {
      final allSongs = await _libraryRepo.songs();
      final songMap = {for (var s in allSongs) s.id: s};
      final result = <SongModel>[];
      for (final row in rows) {
        final song = songMap[row.songId];
        if (song != null) result.add(song);
      }
      return result;
    });
  }
}