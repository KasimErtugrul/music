import 'package:drift/drift.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/tables/play_history_table.dart';
import 'package:resonance/data/models/song_model.dart';

part 'history_dao.g.dart';

class SongPlayCount {
  const SongPlayCount({required this.songId, required this.playCount});
  final int songId;
  final int playCount;
}

@DriftAccessor(tables: [PlayHistory])
class HistoryDao extends DatabaseAccessor<AppDatabase> with _$HistoryDaoMixin {
  HistoryDao(super.db);

  Future<int> recordPlay(SongModel song) {
    return into(playHistory).insert(
      PlayHistoryCompanion.insert(
        songId: song.id,
        path: Value(song.path),
        title: Value(song.title),
        artist: Value(song.artist),
        durationMs: Value(song.durationMs),
      ),
    );
  }

  Stream<List<PlayHistoryData>> watchRecent({int limit = 100}) {
    return (select(playHistory)
          ..orderBy([(t) => OrderingTerm.desc(t.playedAt), (t) => OrderingTerm.desc(t.id)])
          ..limit(limit))
        .watch();
  }

  Future<List<SongPlayCount>> getMostPlayed({int limit = 100}) async {
    final count = playHistory.songId.count();
    final query = selectOnly(playHistory)
      ..addColumns([playHistory.songId, count])
      ..groupBy([playHistory.songId])
      ..orderBy([OrderingTerm.desc(count)])
      ..limit(limit);
    final rows = await query.get();
    return rows.map((row) => SongPlayCount(songId: row.read(playHistory.songId)!, playCount: row.read(count)!)).toList();
  }

  Future<void> clear() => delete(playHistory).go();

  /// [olderThan] öncesindeki çalma kayıtlarını siler. Geçmiş sınırsız
  /// büyümesin diye açılışta çağrılır.
  Future<int> pruneOlderThan(DateTime olderThan) {
    return (delete(playHistory)
          ..where((t) => t.playedAt.isSmallerThanValue(olderThan)))
        .go();
  }

  /// Hiç çalınmamış şarkı kimlikleri için: geçmişte geçen benzersiz
  /// songId kümesi (tüm satırlar Dart belleğine çekilmez).
  Future<Set<int>> getDistinctSongIds() async {
    final q = selectOnly(playHistory, distinct: true)
      ..addColumns([playHistory.songId]);
    final rows = await q.get();
    return {for (final r in rows) r.read(playHistory.songId)!};
  }

  /// [since] sonrası (null: hepsi) çalma sayıları: songId -> adet.
  Future<Map<int, int>> getPlayCountsBySong({DateTime? since}) async {
    final count = playHistory.id.count();
    final q = selectOnly(playHistory)
      ..addColumns([playHistory.songId, count])
      ..groupBy([playHistory.songId]);
    if (since != null) {
      q.where(playHistory.playedAt.isBiggerThanValue(since));
    }
    final rows = await q.get();
    return {
      for (final r in rows) r.read(playHistory.songId)!: r.read(count)!,
    };
  }

  /// [since] sonrası (null: hepsi) haftanın günü dağılımı için yalnızca
  /// zaman damgaları. Satır başına tek sütun çekilir.
  Future<List<DateTime>> getPlayTimes({DateTime? since}) async {
    final q = selectOnly(playHistory)..addColumns([playHistory.playedAt]);
    if (since != null) {
      q.where(playHistory.playedAt.isBiggerThanValue(since));
    }
    final rows = await q.get();
    return [for (final r in rows) r.read(playHistory.playedAt)!];
  }

  /// Gün 17 (Kasa): bir şarkının tüm çalma kayıtlarını siler. Kasaya alınan
  /// şarkının geçmişteki başlık/sanatçı anlık görüntüleri bilgi sızdırdığı
  /// için ban anında (kullanıcı onaylarsa) temizlenir. songId yeterli
  /// değildir: MediaStore yeniden taramasında kimlik değişen kayıtlar yol
  /// üzerinden de yakalanır.
  Future<void> deleteForSong(int songId, String? path) {
    return (delete(playHistory)
          ..where(
            (t) => path == null
                ? t.songId.equals(songId)
                : t.songId.equals(songId) | t.path.equals(path),
          ))
        .go();
  }
}