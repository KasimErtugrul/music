import 'package:drift/drift.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/tables/play_history_table.dart';

part 'history_dao.g.dart';

/// "En çok çalınanlar" sorgusunun sonucu.
class SongPlayCount {
  const SongPlayCount({required this.songId, required this.playCount});

  final int songId;
  final int playCount;
}

@DriftAccessor(tables: [PlayHistory])
class HistoryDao extends DatabaseAccessor<AppDatabase>
    with _$HistoryDaoMixin {
  HistoryDao(super.db);

  Future<int> recordPlay(int songId) {
    return into(playHistory).insert(
      PlayHistoryCompanion.insert(songId: songId),
    );
  }

  /// En yeni önce. `id DESC` ikincil sıralaması, `CURRENT_TIMESTAMP`'ın
  /// saniye çözünürlüğünden bağımsız kararlı sıra sağlar.
  Stream<List<PlayHistoryData>> watchRecent({int limit = 100}) {
    return (select(playHistory)
          ..orderBy([
            (t) => OrderingTerm.desc(t.playedAt),
            (t) => OrderingTerm.desc(t.id),
          ])
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
    return rows
        .map(
          (row) => SongPlayCount(
            songId: row.read(playHistory.songId)!,
            playCount: row.read(count)!,
          ),
        )
        .toList(growable: false);
  }

  Future<void> clear() => delete(playHistory).go();
}