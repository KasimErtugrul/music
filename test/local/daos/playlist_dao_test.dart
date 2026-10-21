import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/daos/playlist_dao.dart';

void main() {
  late AppDatabase db;
  late PlaylistDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.playlistDao;
  });

  tearDown(() async {
    await db.close();
  });

  test('create + getById', () async {
    final id = await dao.create('Road trip');
    final row = await dao.getById(id);
    expect(row, isNotNull);
    expect(row!.name, 'Road trip');
  });

  test('rename updates name', () async {
    final id = await dao.create('Old');
    await dao.rename(id, 'New');
    final row = await dao.getById(id);
    expect(row!.name, 'New');
  });

  test('deletePlaylist cascades playlist_songs', () async {
    final id = await dao.create('P');
    await dao.addSong(id, 10);
    await dao.addSong(id, 11);

    await dao.deletePlaylist(id);

    expect(await dao.getById(id), isNull);
    final remaining = await (db.select(db.playlistSongs)
          ..where((t) => t.playlistId.equals(id)))
        .get();
    expect(remaining, isEmpty);
  });

  test('addSong assigns sequential positions', () async {
    final id = await dao.create('P');
    await dao.addSong(id, 10);
    await dao.addSong(id, 20);
    await dao.addSong(id, 30);

    final songs = await dao.getSongsInPlaylist(id);
    expect(songs.map((s) => s.songId).toList(), <int>[10, 20, 30]);
    expect(songs.map((s) => s.position).toList(), <int>[0, 1, 2]);
  });

  test('addSong rejects duplicate song in same playlist', () async {
    final id = await dao.create('P');
    await dao.addSong(id, 10);

    await expectLater(() => dao.addSong(id, 10), throwsA(anything));
    expect((await dao.getSongsInPlaylist(id)).length, 1);
  });

  test('removeSong compacts positions', () async {
    final id = await dao.create('P');
    await dao.addSong(id, 10);
    await dao.addSong(id, 20);
    await dao.addSong(id, 30);

    await dao.removeSong(id, 20);

    final songs = await dao.getSongsInPlaylist(id);
    expect(songs.map((s) => s.songId).toList(), <int>[10, 30]);
    expect(songs.map((s) => s.position).toList(), <int>[0, 1]);
  });

  test('reorderSongs applies requested order', () async {
    final id = await dao.create('P');
    await dao.addSong(id, 10);
    await dao.addSong(id, 20);
    await dao.addSong(id, 30);

    await dao.reorderSongs(id, <int>[30, 10, 20]);

    final songs = await dao.getSongsInPlaylist(id);
    expect(songs.map((s) => s.songId).toList(), <int>[30, 10, 20]);
  });

  test('isSongInPlaylist', () async {
    final id = await dao.create('P');
    await dao.addSong(id, 10);
    expect(await dao.isSongInPlaylist(id, 10), isTrue);
    expect(await dao.isSongInPlaylist(id, 99), isFalse);
  });
}