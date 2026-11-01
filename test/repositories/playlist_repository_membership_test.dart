// Gün 21: PlaylistRepositoryImpl.playlistNamesBySong üyelik haritası.
//
// Kütüphane kartındaki «hangi listelerde» rozetinin veri sözleşmesi:
// * Birden çok listeye giren şarkı tüm adları taşır.
// * Hiç listeye girmemiş şarkı haritada hiç yoktur.
// * Playlist silindikten sonra üyeliği haritada görünmez: cascade açık
//   kurulumlarda satır DB'den düşer, kapalı kurulumlarda ad çözülemez
//   ve repo katmanı hayalet satırı atlar. İki yol da aynı sonucu verir.
//
// Gerçek bellek-içi Drift (NativeDatabase.memory) kullanılır —
// playlist_controller_reorder_test ve playlist_dao_test düzeniyle aynı.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/playlist_repository.dart';

class _MockLibraryRepo extends Mock implements LibraryRepository {}

SongModel _song(int id) => SongModel(
      id: id,
      uri: 'content://media/external/audio/media/$id',
      path: '/music/$id.mp3',
      title: 'Song $id',
      durationMs: 180000,
      sizeBytes: 4000000,
    );

void main() {
  late AppDatabase db;
  late _MockLibraryRepo libraryRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    libraryRepo = _MockLibraryRepo();
  });

  tearDown(() async {
    await db.close();
  });

  test('üyelik haritası: çok listeli şarkı tüm adları, tek listeli tek adı',
      () async {
    final dao = db.playlistDao;
    final rock = await dao.create('Rock');
    final workout = await dao.create('Workout');
    final repo = PlaylistRepositoryImpl(dao, libraryRepo);

    await repo.addSong(rock, _song(1));
    await repo.addSong(workout, _song(1));
    await repo.addSong(rock, _song(2));

    final map = await repo.playlistNamesBySong();

    // Liste adlarının sırası getAll (updatedAt DESC) düzenini izler;
    // sözleşme sıra değil kümedir.
    expect(map[1], containsAll(<String>['Rock', 'Workout']));
    expect(map[1], hasLength(2));
    expect(map[2], <String>['Rock']);
  });

  test('hiç listeye girmemiş şarkı haritada görünmez', () async {
    final dao = db.playlistDao;
    final rock = await dao.create('Rock');
    final repo = PlaylistRepositoryImpl(dao, libraryRepo);

    await repo.addSong(rock, _song(1));
    // Song 3 hiçbir listeye eklenmedi.

    final map = await repo.playlistNamesBySong();

    expect(map.containsKey(3), isFalse);
    expect(map.keys, <int>[1]);
  });

  test('playlist silinince üyeliği haritadan düşer', () async {
    final dao = db.playlistDao;
    final rock = await dao.create('Rock');
    final repo = PlaylistRepositoryImpl(dao, libraryRepo);

    await repo.addSong(rock, _song(5));
    await dao.deletePlaylist(rock);

    final map = await repo.playlistNamesBySong();

    // Cascade açıkken satır DB'den silinir; kapalı kurulumlarda ad
    // çözülemez ve repo hayalet satırı atlar. İki durumda da harita boş.
    expect(map, isEmpty);
  });
}