// Gün 11: PlaylistController.reorderSongs sıralama bütünlüğü testleri.
//
// Kapsam (Gün 9 raporu Ek bulgu 3'ün ele alınışı):
// * Normal akış: UI hamlesi yerel duruma uygulanır, DB'ye yazılır ve
//   detay DB gerçeğinden yeniden okunur; DAO konumları 0..n-1 bitişiktir.
// * Bayat detay: controller devre dışı bırakılarak DB'den satır silinir
//   (başka bir yüzeyin değişikliğini simüle eder); sonraki sıralamadan
//   sonra görünüm DB gerçeğine yakınsar — bayat şarkı görünümden düşer.
// * Repo hatası: yerel durum DB'deki eski sıraya geri sarılır (Gün 11
//   öncesinde görünüm diskten sessizce sapardı); hata yukarı fırlamaya
//   devam eder (davranış korunur), yutulmaz.
//
// Gerçek bellek-içi Drift (NativeDatabase.memory) kullanılır —
// playlist_dao_test (DAO katmanı) ve favorite_controller_test (Gün 9)
// düzeniyle aynı. Repo hatası yolu mock repo ile izole edilir.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/models/playlist_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/playlist_repository.dart';
import 'package:resonance/presentation/controllers/playlist_controller.dart';

class _MockLibraryRepo extends Mock implements LibraryRepository {}

class _MockPlaylistRepo extends Mock implements PlaylistRepository {}

/// Test için minimal SongModel üretir (playlist_dao_test düzeni).
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
    // getSongs, playlist satırlarını kütüphaneyle çözer (id → path sırası).
    when(() => libraryRepo.songs()).thenAnswer(
      (_) async => <SongModel>[_song(1), _song(2), _song(3)],
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('sıralama DB\'ye yansır; detay DB gerçeğiyle örtüşür', () async {
    final dao = db.playlistDao;
    final pid = await dao.create('P');
    final repo = PlaylistRepositoryImpl(dao, libraryRepo);
    await repo.addSong(pid, _song(1));
    await repo.addSong(pid, _song(2));
    await repo.addSong(pid, _song(3));

    final c = PlaylistController(repo);
    await c.loadPlaylistDetail(pid);
    expect(c.currentSongs.map((s) => s.id), <int>[1, 2, 3]);

    // İlk şarkıyı üçüncü sıraya sürükle: [1,2,3] → [2,1,3]
    // (ReorderableListView sözleşmesi: newIndex > oldIndex ise -1).
    await c.reorderSongs(pid, 0, 2);

    // Görünüm, DB gerçeğinden yeniden okundu.
    expect(c.currentSongs.map((s) => s.id), <int>[2, 1, 3]);

    final rows = await dao.getSongsInPlaylist(pid);
    expect(rows.map((r) => r.songId), <int>[2, 1, 3]);
    expect(rows.map((r) => r.position), <int>[0, 1, 2]); // bitişik konumlar
  });

  test('bayat detay: DB\'den silinen şarkı sıralama sonrası görünümden düşer',
      () async {
    final dao = db.playlistDao;
    final pid = await dao.create('P');
    final repo = PlaylistRepositoryImpl(dao, libraryRepo);
    await repo.addSong(pid, _song(1));
    await repo.addSong(pid, _song(2));
    await repo.addSong(pid, _song(3));

    final c = PlaylistController(repo);
    await c.loadPlaylistDetail(pid);

    // Controller'ı devre dışı bırakarak DB'den 2 numaralı satırı sil:
    // detay hâlâ [1,2,3] gösterir (bayat).
    await (db.delete(db.playlistSongs)
          ..where((t) => t.playlistId.equals(pid) & t.songId.equals(2)))
        .go();
    expect(c.currentSongs.map((s) => s.id), <int>[1, 2, 3]);

    await c.reorderSongs(pid, 0, 2);

    // Yazım bayat yerel listeden türetildi ([2,1,3]); 2 numaralı satır DB'de
    // olmadığı için güncelleme onu bulamaz. DB gerçeği [1,3] olur; akış
    // sonunda detay DB'den tazelendiği için bayat şarkı görünümden düşer.
    expect(c.currentSongs.map((s) => s.id), <int>[1, 3]);
  });

  test('repo hatasında yerel durum DB\'deki eski sıraya geri sarılır',
      () async {
    final repo = _MockPlaylistRepo();
    final model = PlaylistModel(
      id: 7,
      name: 'P',
      songCount: 3,
      updatedAt: DateTime(2026, 10, 31),
    );
    when(() => repo.getPlaylist(7)).thenAnswer((_) async => model);
    when(() => repo.getSongs(7)).thenAnswer(
      (_) async => <SongModel>[_song(1), _song(2), _song(3)],
    );
    when(() => repo.reorderSongs(7, any())).thenThrow(Exception('disk hatası'));

    final c = PlaylistController(repo);
    await c.loadPlaylistDetail(7);
    expect(c.currentSongs.map((s) => s.id), <int>[1, 2, 3]);

    // Repo hatası yukarı fırlar (Gün 11 öncesi davranış korunur)...
    await expectLater(c.reorderSongs(7, 0, 1), throwsA(anything));

    // ...ama finally'deki tazeleme yerel durumu DB gerçeğine geri sarar.
    // Gün 11 öncesinde görünüm [2,1,3]'te kalıyor ve diskten sessizce
    // sapıyordu.
    expect(c.currentSongs.map((s) => s.id), <int>[1, 2, 3]);
  });
}