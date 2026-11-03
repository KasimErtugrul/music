// Bulgu 2: aynı playliste ikinci ekleme engeli + arayüz sözleşmesi.
//
// Kapsam:
// * addSongToPlaylist ilk çağrıda true döner, DB'ye tek satır yazar.
// * Aynı şarkıyı aynı listeye ikinci çağrı FALSE döndürür (sessiz
//   başarısızlık kapanır; çağıran sheet snackbar gösterir), DB'de
//   kopya birikmez, diğer listeye ekleme yine serbesttir.
// * loadPlaylists tetiklendiği için üyelik haritası taze kalır.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/daos/playlist_dao.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/playlist_repository.dart';
import 'package:resonance/presentation/controllers/playlist_controller.dart';

class _MockLibraryRepo implements LibraryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

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
  late PlaylistController controller;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    final repo = PlaylistRepositoryImpl(
      PlaylistDao(db),
      _MockLibraryRepo(),
    );
    controller = PlaylistController(repo);
  });

  tearDown(() async {
    await db.close();
  });

  test('ikinci ekleme false döner ve kopya birikmez', () async {
    final dao = PlaylistDao(db);
    final pid = await dao.create('Rock');

    expect(await controller.addSongToPlaylist(pid, _song(1)), isTrue);
    // İkinci deneme: zaten üye → false (Bulgu 2).
    expect(await controller.addSongToPlaylist(pid, _song(1)), isFalse);

    final rows = await dao.getSongsInPlaylist(pid);
    expect(rows.map((s) => s.id), <int>[1]); // tek kayıt

    // Aynı şarkı BAŞKA listeye eklenebilir (kısıt liste bazlıdır).
    final pid2 = await dao.create('Workout');
    expect(await controller.addSongToPlaylist(pid2, _song(1)), isTrue);
  });

  test('ekleme sonrası üyelik haritası tazelenir', () async {
    final dao = PlaylistDao(db);
    final pid = await dao.create('Rock');
    await controller.addSongToPlaylist(pid, _song(7));

    expect(controller.listNamesOf(7), <String>['Rock']);
    expect(controller.listNamesOf(8), isEmpty);
  });
}
