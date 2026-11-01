import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/daos/banned_song_dao.dart';

/// Gün 17 (Kasa): yasaklı şarkı DAO'su.
///
/// Sözleşmenin kalbi: yol (path) kalıcı kimliktir ve UNIQUE'tir; aynı
/// dosyayı iki kez banlamak idempotenttir (insertOnConflictUpdate).
void main() {
  late AppDatabase db;
  late BannedSongDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.bannedSongDao;
  });

  tearDown(() async => await db.close());

  Future<void> seed() async {
    await dao.ban(
      songId: 1,
      path: '/storage/emulated/0/Music/a.mp3',
      title: 'Şarkı A',
      artist: 'Sanatçı',
      album: 'Albüm',
    );
  }

  test('ban + getAll + count', () async {
    expect(await dao.count(), 0);
    await seed();
    expect(await dao.count(), 1);
    final rows = await dao.getAll();
    expect(rows.single.songId, 1);
    expect(rows.single.path, '/storage/emulated/0/Music/a.mp3');
    expect(rows.single.titleSnapshot, 'Şarkı A');
    expect(rows.single.artistSnapshot, 'Sanatçı');
  });

  test('aynı yolu iki kez banlamak idempotenttir (UNIQUE path)', () async {
    await seed();
    await dao.ban(
      songId: 99, // songId değişse bile yol aynı: satır güncellenir.
      path: '/storage/emulated/0/Music/a.mp3',
      title: 'Şarkı A',
    );
    expect(await dao.count(), 1);
    expect((await dao.getAll()).single.songId, 99);
  });

  test('unbanByPath kaydı siler', () async {
    await seed();
    await dao.unbanByPath('/storage/emulated/0/Music/a.mp3');
    expect(await dao.count(), 0);
  });

  test('watchAll canlı güncelleme yapar', () async {
    await seed();
    final first = await dao.watchAll().first;
    expect(first.single.path, '/storage/emulated/0/Music/a.mp3');
  });
}
