import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/playlist_repository.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/playlist_controller.dart';

/// Gün 19: playlist'i LİSTE olarak çalma sözleşmesi.
///
/// Hata kaydı: detay sayfası salt bir düzenleyiciydi; playlist hiçbir
/// yoldan liste olarak çalınamıyordu. `playPlaylist` ile kuyruk artık
/// playlist'in tamamıdır; bu testler o sözleşmeyi sabitler.
class _MockPlaylistRepository extends Mock implements PlaylistRepository {}

class _MockPlayerController extends Mock implements PlayerController {
  // GetX 4.7 yaşam döngüsü düzeltmesi: `Get.put` → `_startController`
  // denetleyiciye `i.onStart()` der; `Get.reset` → `delete` ise `i.onDelete()`.
  // Bu iki üye GetLifeCycleBase'de `final InternalFinalCallback<void>`
  // alanlarıdır; `extends Mock implements PlayerController` yazımı temel
  // sınıf alanlarını DEVRALMADIĞI için bu okumalar noSuchMethod'a düşer ve
  // mocktail null döndürür → «Null is not a subtype of
  // InternalFinalCallback<void>» TypeError'ı. Alanları boş geri çağrılı
  // gerçek örneklerle eziyoruz: mock'un yaşam döngüsü no-op olur (davranış
  // tamamen stub'lardan gelir); gerçek PlaylistController etkilenmez.
  @override
  final InternalFinalCallback<void> onStart =
      InternalFinalCallback<void>(callback: () {});

  @override
  final InternalFinalCallback<void> onDelete =
      InternalFinalCallback<void>(callback: () {});
}

SongModel _song(int id) => SongModel(
      id: id,
      uri: 'content://media/external/audio/media/$id',
      path: '/storage/emulated/0/Music/song$id.mp3',
      title: 'Song $id',
      durationMs: 180000,
      sizeBytes: 1024,
    );

void main() {
  late _MockPlaylistRepository repo;
  late _MockPlayerController player;

  setUpAll(() {
    // playSong(any()) için fallbackler: SongModel somut sınıftır, kuyruk
    // parametresi de List<SongModel> tipinde — ikisi de kayıtsızsa mocktail
    // «Missing registered fallback value» ile fırlatır.
    registerFallbackValue(_song(0));
    registerFallbackValue(<SongModel>[]);
  });

  setUp(() {
    repo = _MockPlaylistRepository();
    player = _MockPlayerController();

    // PlaylistController.onInit → loadPlaylists; Get.put bu çağrıyı
    // tetikler, stub'sız mocktail Future dönen çağrıda fırlatır.
    when(() => repo.getPlaylists()).thenAnswer((_) async => []);
    // Gün 21: loadPlaylists artık üyelik haritasını da ister.
    when(() => repo.playlistNamesBySong())
        .thenAnswer((_) async => <int, List<String>>{});

    when(() => player.playSong(any(), queue: any(named: 'queue')))
        .thenAnswer((_) async => true);
    // DİKKAT: `false.obs()` DEĞİL `false.obs`. Parantezli yazım RxBool'u
    // çağırıp bool döndürür; thenReturn(bool) tip hatası verir ve — daha
    // kötüsü — mocktail'in when kaydını yarım bırakır (_whenCall yalnız
    // thenReturn/thenAnswer'da temizlenir). Yarım kayıt, aynı izolasyondaki
    // TÜM sonraki when() çağrılarını «Cannot call `when` within a stub
    // response» ile düşürür.
    when(() => player.shuffleEnabled).thenReturn(false.obs);
    when(() => player.toggleShuffle()).thenAnswer((_) async {});

    Get
      ..put<PlayerController>(player)
      ..put<PlaylistController>(PlaylistController(repo));
  });

  tearDown(Get.reset);

  group('PlaylistController.playPlaylist', () {
    test('boş playlist çalmaz, false döner, kuyruğa dokunmaz', () async {
      when(() => repo.getSongs(1)).thenAnswer((_) async => []);

      final started = await Get.find<PlaylistController>().playPlaylist(1);

      expect(started, isFalse);
      verifyNever(() => player.playSong(any(), queue: any(named: 'queue')));
      verifyNever(() => player.toggleShuffle());
    });

    test('sırayla: kuyruk playlistin tamamı, başlangıç ilk parça', () async {
      final songs = [_song(3), _song(1), _song(2)];
      when(() => repo.getSongs(7)).thenAnswer((_) async => songs);

      final started = await Get.find<PlaylistController>().playPlaylist(7);

      expect(started, isTrue);
      final captured = verify(
        () => player.playSong(
          captureAny(),
          queue: captureAny(named: 'queue'),
        ),
      ).captured;
      expect(captured, hasLength(2));
      expect(captured[0] as SongModel, songs.first);
      expect(captured[1] as List<SongModel>, songs);
      verifyNever(() => player.toggleShuffle());
    });

    test('karıştır: mod kapalıysa toggle açılır, rastgele başlangıç', () async {
      final songs = [_song(1), _song(2), _song(3), _song(4)];
      when(() => repo.getSongs(9)).thenAnswer((_) async => songs);

      final started =
          await Get.find<PlaylistController>().playPlaylist(9, shuffled: true);

      expect(started, isTrue);
      verify(() => player.toggleShuffle()).called(1);
      // Başlangıç parçası listenin BİR üyesi olmalı; kuyruk tamamı.
      final captured = verify(
        () => player.playSong(
          captureAny(),
          queue: captureAny(named: 'queue'),
        ),
      ).captured;
      expect(songs.contains(captured[0] as SongModel), isTrue);
      expect(captured[1] as List<SongModel>, songs);
    });

    test('karıştır: mod zaten açıksa toggle çağrılmaz', () async {
      when(() => player.shuffleEnabled).thenReturn(true.obs);
      final songs = [_song(1), _song(2)];
      when(() => repo.getSongs(9)).thenAnswer((_) async => songs);

      await Get.find<PlaylistController>().playPlaylist(9, shuffled: true);

      verifyNever(() => player.toggleShuffle());
      verify(() => player.playSong(any(), queue: any(named: 'queue')))
          .called(1);
    });
  });
}