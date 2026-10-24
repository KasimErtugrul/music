import 'package:drift/drift.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/tables/favorites_table.dart';
import 'package:resonance/data/models/song_model.dart';

part 'favorite_dao.g.dart';

@DriftAccessor(tables: [Favorites])
class FavoriteDao extends DatabaseAccessor<AppDatabase> with _$FavoriteDaoMixin {
  FavoriteDao(super.db);

  Future<void> add(SongModel song) {
    return into(favorites).insert(
      FavoritesCompanion.insert(
        songId: song.id,
        path: Value(song.path),
        title: Value(song.title),
        artist: Value(song.artist),
        durationMs: Value(song.durationMs),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> remove(int songId) {
    return (delete(favorites)..where((t) => t.songId.equals(songId))).go();
  }

  Future<bool> isFavorite(int songId) async {
    final row = await (select(favorites)..where((t) => t.songId.equals(songId))..limit(1)).getSingleOrNull();
    return row != null;
  }

  Stream<List<int>> watchAllSongIds() {
    return (select(favorites)..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .watch()
        .map((rows) => rows.map((r) => r.songId).toList(growable: false));
  }

  Future<List<int>> getAllSongIds() async {
    final rows = await (select(favorites)..orderBy([(t) => OrderingTerm.desc(t.id)])).get();
    return rows.map((r) => r.songId).toList(growable: false);
  }
}