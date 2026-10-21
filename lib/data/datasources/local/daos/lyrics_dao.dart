import 'package:drift/drift.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/tables/lyrics_table.dart';

part 'lyrics_dao.g.dart';

@DriftAccessor(tables: [Lyrics])
class LyricsDao extends DatabaseAccessor<AppDatabase>
    with _$LyricsDaoMixin {
  LyricsDao(super.db);

  Future<void> upsert(
    int songId,
    String content, {
    String source = 'manual',
  }) {
    return into(lyrics).insertOnConflictUpdate(
      LyricsCompanion.insert(
        songId: Value(songId),
        content: content,
        source: Value(source),
      ),
    );
  }

  Future<Lyric?> get(int songId) {
    return (select(lyrics)..where((t) => t.songId.equals(songId)))
        .getSingleOrNull();
  }

  Future<void> deleteFor(int songId) {
    return (delete(lyrics)..where((t) => t.songId.equals(songId))).go();
  }
}