import 'package:drift/drift.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/tables/playlist_songs_table.dart';
import 'package:resonance/data/datasources/local/tables/playlists_table.dart';

part 'playlist_dao.g.dart';

@DriftAccessor(tables: [Playlists, PlaylistSongs])
class PlaylistDao extends DatabaseAccessor<AppDatabase>
    with _$PlaylistDaoMixin {
  PlaylistDao(super.db);

  /// En son güncellenen önce; eşitlikte `id DESC`.
  Stream<List<Playlist>> watchAll() {
    return (select(playlists)
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  Future<List<Playlist>> getAll() {
    return (select(playlists)
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
  }

  Future<Playlist?> getById(int id) {
    return (select(playlists)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> create(String name) {
    return into(playlists).insert(PlaylistsCompanion.insert(name: name));
  }

  Future<void> rename(int id, String name) async {
    await (update(playlists)..where((t) => t.id.equals(id))).write(
      PlaylistsCompanion(
        name: Value(name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// NOT: `delete` adı `DatabaseAccessor.delete(TableInfo)` ile çakışır.
  Future<void> deletePlaylist(int id) async {
    await (delete(playlists)..where((t) => t.id.equals(id))).go();
  }

  Future<void> addSong(int playlistId, int songId) async {
    final maxPos = await (selectOnly(playlistSongs)
          ..addColumns([playlistSongs.position.max()])
          ..where(playlistSongs.playlistId.equals(playlistId)))
        .map((row) => row.read(playlistSongs.position.max()))
        .getSingleOrNull();

    final next = (maxPos ?? -1) + 1;

    await transaction(() async {
      await into(playlistSongs).insert(
        PlaylistSongsCompanion.insert(
          playlistId: playlistId,
          songId: songId,
          position: next,
        ),
      );
      await (update(playlists)..where((t) => t.id.equals(playlistId))).write(
        PlaylistsCompanion(updatedAt: Value(DateTime.now())),
      );
    });
  }

  Future<bool> isSongInPlaylist(int playlistId, int songId) async {
    final row = await (select(playlistSongs)
          ..where((t) =>
              t.playlistId.equals(playlistId) & t.songId.equals(songId))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> removeSong(int playlistId, int songId) async {
    await transaction(() async {
      await (delete(playlistSongs)
            ..where((t) =>
                t.playlistId.equals(playlistId) & t.songId.equals(songId)))
          .go();
      final remaining = await getSongsInPlaylist(playlistId);
      for (var i = 0; i < remaining.length; i++) {
        await (update(playlistSongs)
              ..where((t) => t.id.equals(remaining[i].id)))
            .write(PlaylistSongsCompanion(position: Value(i)));
      }
      await (update(playlists)..where((t) => t.id.equals(playlistId))).write(
        PlaylistsCompanion(updatedAt: Value(DateTime.now())),
      );
    });
  }

  Future<List<PlaylistSong>> getSongsInPlaylist(int playlistId) {
    return (select(playlistSongs)
          ..where((t) => t.playlistId.equals(playlistId))
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
  }

  Future<void> reorderSongs(int playlistId, List<int> songIdsInOrder) async {
    await transaction(() async {
      for (var i = 0; i < songIdsInOrder.length; i++) {
        await (update(playlistSongs)
              ..where((t) =>
                  t.playlistId.equals(playlistId) &
                  t.songId.equals(songIdsInOrder[i])))
            .write(PlaylistSongsCompanion(position: Value(i)));
      }
      await (update(playlists)..where((t) => t.id.equals(playlistId))).write(
        PlaylistsCompanion(updatedAt: Value(DateTime.now())),
      );
    });
  }
}