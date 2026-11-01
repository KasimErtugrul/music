import 'package:drift/drift.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/tables/banned_songs_table.dart';

part 'banned_song_dao.g.dart';

@DriftAccessor(tables: [BannedSongs])
class BannedSongDao extends DatabaseAccessor<AppDatabase>
    with _$BannedSongDaoMixin {
  BannedSongDao(super.db);

  Stream<List<BannedSong>> watchAll() => select(bannedSongs).watch();

  Future<List<BannedSong>> getAll() => select(bannedSongs).get();

  /// Yolu zaten yasaklı olan dosyayı yeniden banlamak hataya düşmez;
  /// satır güncellenir (path UNIQUE kısıtı hedefli upsert). idempotenttir.
  Future<void> ban({
    required int songId,
    required String path,
    required String title,
    String? artist,
    String? album,
  }) {
    return into(bannedSongs).insert(
      BannedSongsCompanion.insert(
        songId: songId,
        path: path,
        titleSnapshot: title,
        artistSnapshot: Value(artist),
        albumSnapshot: Value(album),
      ),
      onConflict: DoUpdate(
        (_) => BannedSongsCompanion(
          songId: Value(songId),
          titleSnapshot: Value(title),
          artistSnapshot: Value(artist),
          albumSnapshot: Value(album),
        ),
        target: [bannedSongs.path],
      ),
    );
  }

  Future<void> unbanByPath(String path) {
    return (delete(bannedSongs)..where((t) => t.path.equals(path))).go();
  }

  Future<int> count() async {
    final c = bannedSongs.id.count();
    final query = selectOnly(bannedSongs)..addColumns([c]);
    return await query.getSingle().then((row) => row.read(c) ?? 0);
  }
}
