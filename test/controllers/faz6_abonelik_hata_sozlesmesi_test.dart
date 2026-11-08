/* // FAZ 6 (Bulgu 8/15/16): abonelik hijyeni + hata sözleşmesi ailesi.
//
// Kapsam:
// * Bulgu 8a — PlayerController._bind()'teki altı depo akışı aboneliği
//   artık _subs listesinde; onClose iptal eder. Kanıt: denetim öncesi
//   dinleyiciler saklanmıyordu (player_controller.dart:152-246); permanent:
//   true normal ömürde sorunu gizliyordu, Get.reset()/test/hot-restart'ta
//   denetleyici öldüğü halde dinleyiciler Rx'lere «ghost update» yazıyordu.
// * Bulgu 8b — _saveQueueState üç çağrı noktasından üst üste binen yazımlar
//   başlatıyordu; HomeWidgetController._requestSync'teki _running/_dirty
//   coalescing döngüsü birebir uygulandı. Bayat pozisyonun yeni pozisyonun
//   üstüne yazması (restore'da «5 sn geri sıçrama») kapatılır.
// * Bulgu 15 — PlaylistController.loadPlaylists / SmartPlaylistController.load
//   / StatsController.loadStats: LibraryController'daki hasError sözleşmesi
//   (library_controller.dart loadAll:78-94 deseni).
// * Bulgu 16 — history/favorite watch akışlarına onError; vault'un boş
//   onError'ı günlüğe bağlandı. Abonelikler saklanıp onClose'ta iptal edilir.
import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart' show PlayerException;
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/models/library_settings_model.dart';
import 'package:resonance/data/models/play_stats_model.dart';
import 'package:resonance/data/models/playback_settings_model.dart';
import 'package:resonance/data/models/playlist_model.dart';
import 'package:resonance/data/models/queue_state_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/favorite_repository.dart';
import 'package:resonance/data/repositories/history_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/player_repository.dart';
import 'package:resonance/data/repositories/preferences_repository.dart';
import 'package:resonance/data/repositories/playlist_repository.dart';
import 'package:resonance/data/repositories/queue_state_repository.dart';
import 'package:resonance/data/repositories/stats_repository.dart';
import 'package:resonance/presentation/controllers/favorite_controller.dart';
import 'package:resonance/presentation/controllers/history_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/controllers/playlist_controller.dart';
import 'package:resonance/presentation/controllers/smart_playlist_controller.dart';
import 'package:resonance/presentation/controllers/stats_controller.dart';

class _MockPlayerRepository extends Mock implements PlayerRepository {}
class _MockLibraryRepository extends Mock implements LibraryRepository {}
class _MockQueueStateRepository extends Mock implements QueueStateRepository {}
class _MockHistoryRepository extends Mock implements HistoryRepository {}
class _MockPreferencesRepository extends Mock implements PreferencesRepository {}
class _MockPlaylistRepository extends Mock implements PlaylistRepository {}
class _MockStatsRepository extends Mock implements StatsRepository {}
class _MockFavoriteRepository extends Mock implements FavoriteRepository {}

QueueStateModel _fallbackState() => QueueStateModel(
      songUris: const <String>[],
      currentIndex: 0,
      position: Duration.zero,
      shuffleEnabled: false,
      repeatMode: AudioServiceRepeatMode.none,
    );

SongModel _song(int id) => SongModel(
      id: id,
      uri: 'content://media/external/audio/media/$id',
      path: '/music/$id.mp3',
      title: 'Şarkı $id',
      durationMs: 180000,
      sizeBytes: 4000000,
    );

void main() {
  setUpAll(() {
    Get.testMode = true;
    registerFallbackValue(_fallbackState());
    registerFallbackValue(<SongModel>[]);
    registerFallbackValue('');
    registerFallbackValue(_song(1));
    registerFallbackValue(Duration.zero);
    registerFallbackValue(DateTime(2020));
    registerFallbackValue(const PlaybackSettingsModel());
  });

  tearDown(Get.reset);

  Future<void> pump() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  group('Bulgu 8a: PlayerController abonelik hijyeni', () {
    test('onClose sonrası akış olayları Rx\u2019lere yazmaz (ghost update yok)',
        () async {
      final repo = _MockPlayerRepository();
      final stateRepo = _MockQueueStateRepository();
      final historyRepo = _MockHistoryRepository();
      final prefRepo = _MockPreferencesRepository();
      final positions = StreamController<Duration>.broadcast();
      addTearDown(positions.close);

      when(() => prefRepo.loadPlayback())
          .thenAnswer((_) async => const PlaybackSettingsModel());
      when(() => prefRepo.loadLibrary())
          .thenAnswer((_) async => const LibrarySettingsModel());
      when(() => prefRepo.savePlayback(any())).thenAnswer((_) async {});
      Get.put<PreferencesController>(PreferencesController(prefRepo));

      when(() => repo.mediaItemStream)
          .thenAnswer((_) => const Stream<MediaItem?>.empty());
      when(() => repo.queueStream)
          .thenAnswer((_) => const Stream<List<MediaItem>>.empty());
      when(() => repo.playbackStateStream)
          .thenAnswer((_) => const Stream<PlaybackState>.empty());
      when(() => repo.positionStream).thenAnswer((_) => positions.stream);
      when(() => repo.durationStream)
          .thenAnswer((_) => const Stream<Duration?>.empty());
      when(() => repo.errorStream)
          .thenAnswer((_) => const Stream<PlayerException>.empty());
      when(() => repo.position).thenReturn(Duration.zero);
      when(() => repo.currentIndex).thenReturn(0);
      when(() => historyRepo.recordPlay(any())).thenAnswer((_) async {});

      final controller = PlayerController(
          repo, _MockLibraryRepository(), stateRepo, historyRepo);
      Get.put<PlayerController>(controller);
      await pump();

      positions.add(const Duration(seconds: 10));
      await pump();
      expect(controller.position.value, const Duration(seconds: 10));

      // Bulgu 8: silme yaşam döngüsü abonelikleri iptal eder; sonra gelen
      // olay artık ölü denetleyiciye yazılamaz. Kanıt: GetX 4.7.3
      // get_instance.dart:382 Get.delete → i.onDelete() → lifecycle.dart:79
      // onClose(). (Get.reset() bunu YAPMAZ: get_reset.dart:4-5 +
      // get_instance.dart:323-330 yalnız _singl.clear().)
      expect(await Get.delete<PlayerController>(), isTrue);
      await pump();
      positions.add(const Duration(seconds: 20));
      await pump();
      expect(Get.isRegistered<PlayerController>(), isFalse);
      // Ghost update kilidi: değer onClose'tan önceki 10 sn'de kalır.
      expect(controller.position.value, const Duration(seconds: 10));
    });
  });

  group('Bulgu 8b: _saveQueueState coalescing', () {
    test('çalışan yazım bitmeden yenisi başlamaz; son tur GÜNCEL konumu yazar',
        () async {
      final repo = _MockPlayerRepository();
      final stateRepo = _MockQueueStateRepository();
      final historyRepo = _MockHistoryRepository();
      final prefRepo = _MockPreferencesRepository();
      final items = StreamController<MediaItem?>.broadcast();
      addTearDown(items.close);

      when(() => prefRepo.loadPlayback())
          .thenAnswer((_) async => const PlaybackSettingsModel());
      when(() => prefRepo.loadLibrary())
          .thenAnswer((_) async => const LibrarySettingsModel());
      Get.put<PreferencesController>(PreferencesController(prefRepo));

      when(() => repo.mediaItemStream).thenAnswer((_) => items.stream);
      when(() => repo.queueStream)
          .thenAnswer((_) => const Stream<List<MediaItem>>.empty());
      when(() => repo.playbackStateStream)
          .thenAnswer((_) => const Stream<PlaybackState>.empty());
      when(() => repo.positionStream)
          .thenAnswer((_) => const Stream<Duration>.empty());
      when(() => repo.durationStream)
          .thenAnswer((_) => const Stream<Duration?>.empty());
      when(() => repo.errorStream).thenAnswer((_) => const Stream.empty());
      when(() => repo.currentIndex).thenReturn(0);

      var position = Duration.zero;
      when(() => repo.position).thenAnswer((_) => position);

      var saveCalls = 0;
      final gate = Completer<void>();
      when(() => stateRepo.saveState(any())).thenAnswer((_) async {
        saveCalls++;
        if (saveCalls == 1) await gate.future;
      });

      final controller =
          PlayerController(repo, _MockLibraryRepository(), stateRepo, historyRepo);
      controller.onInit();
      await pump();

      // Kuyruğu doldur: yazım saveState dalından geçsin.
      controller.songQueue.assignAll(<SongModel>[_song(1), _song(2)]);

      // 1. istek: yazım başlar, gate'te bekler.
      items.add(const MediaItem(id: 'other-1', title: 'x'));
      await pump();
      expect(saveCalls, 1);

      // 2. istek: çalışırken geldi → _saveDirty'ye düşer, YENİ yazım
      // başlamaz. Bu turda pozisyon da ilerledi; döngünün SON turu bunu
      // okumak zorunda (bayat anlık görüntü yok).
      position = const Duration(seconds: 42);
      items.add(const MediaItem(id: 'other-2', title: 'y'));
      await pump();
      expect(saveCalls, 1);

      gate.complete();
      await pump();

      expect(saveCalls, 2);
      final saved = verify(() => stateRepo.saveState(captureAny()))
          .captured
          .cast<QueueStateModel>();
      expect(saved, hasLength(2));
      expect(saved.last.position, const Duration(seconds: 42));
    });
  });

  group('Bulgu 15: yükleyici hata sözleşmesi (hasError)', () {
    test('PlaylistController.loadPlaylists DB hatası: hasError + spinner iner',
        () async {
      final repo = _MockPlaylistRepository();
      when(() => repo.getPlaylists()).thenThrow(Exception('db kapalı'));

      final controller = PlaylistController(repo);
      controller.onInit();
      await pump();

      expect(controller.hasError.value, isTrue);
      expect(controller.isLoading.value, isFalse);
      expect(controller.playlists, isEmpty);

      // Sonraki başarılı yükleme hatayı temizler (sözleşme: her yükleme
      // başında hasError sıfırlanır).
      when(() => repo.getPlaylists())
          .thenAnswer((_) async => const <PlaylistModel>[]);
      when(() => repo.playlistNamesBySong())
          .thenAnswer((_) async => const <int, List<String>>{});
      await controller.loadPlaylists();
      expect(controller.hasError.value, isFalse);
      expect(controller.isLoading.value, isFalse);
    });

    test('SmartPlaylistController.load DB hatası: hasError + spinner iner',
        () async {
      final repo = _MockStatsRepository();
      when(() => repo.getSmartPlaylist(any())).thenThrow(Exception('db kapalı'));

      final controller = SmartPlaylistController(repo);
      await controller.load('recent');

      expect(controller.hasError.value, isTrue);
      expect(controller.isLoading.value, isFalse);
      expect(controller.songs, isEmpty);
    });

    test('StatsController.loadStats DB hatası: hasError + spinner iner; '
        'başarılı yükleme hatayı temizler', () async {
      final statsRepo = _MockStatsRepository();
      final historyRepo = _MockHistoryRepository();
      when(() => historyRepo.watchRecentHistory(limit: any(named: 'limit')))
          .thenAnswer((_) => const Stream<List<SongModel>>.empty());
      when(() => statsRepo.getStats(since: any(named: 'since')))
          .thenThrow(Exception('db kapalı'));

      final controller = StatsController(
        statsRepo,
        historyRepo,
        historySyncDebounce: Duration.zero,
      );
      controller.onInit();
      await pump();

      expect(controller.hasError.value, isTrue);
      expect(controller.isLoading.value, isFalse);

      when(() => statsRepo.getStats(since: any(named: 'since'))).thenAnswer(
        (_) async => const PlayStatsModel(
          totalPlays: 0,
          uniqueSongsPlayed: 0,
          topArtists: <String, int>{},
          topGenres: <String, int>{},
        ),
      );
      when(() => statsRepo.getRecentPlays(window: any(named: 'window')))
          .thenAnswer((_) async => const <RecentPlay>[]);
      await controller.loadStats();
      expect(controller.hasError.value, isFalse);
      expect(controller.isLoading.value, isFalse);
    });
  });

  group('Bulgu 16: watch aboneliklerine onError', () {
    test('HistoryController akış hatası: hasError + spinner iner; abonelik '
        'yaşar ve sonraki veriyi işler', () async {
      final historyRepo = _MockHistoryRepository();
      final historyStream = StreamController<List<SongModel>>();
      addTearDown(historyStream.close);
      when(() => historyRepo.watchRecentHistory(limit: any(named: 'limit')))
          .thenAnswer((_) => historyStream.stream);

      final controller = HistoryController(historyRepo);
      controller.onInit();
      await pump();

      historyStream.addError(Exception('db kapalı'));
      await pump();
      expect(controller.hasError.value, isTrue);
      expect(controller.isLoading.value, isFalse);

      // Abonelik ÖLMEDİ: Drift sonraki tablo olayında yeniden sorgular;
      // onError ile dinleyici o veriyi yine işler (dönem bulgusu).
      historyStream.add(<SongModel>[_song(5)]);
      await pump();
      expect(controller.history.map((s) => s.id), contains(5));
      expect(controller.hasError.value, isTrue);
    });

    test('FavoriteController akış hatası: abonelik yaşar, sonraki veriyi '
        'işler', () async {
      final favRepo = _MockFavoriteRepository();
      final favStream = StreamController<List<int>>();
      addTearDown(favStream.close);
      when(() => favRepo.watchFavoriteIds()).thenAnswer((_) => favStream.stream);

      final controller = FavoriteController(favRepo);
      controller.onInit();
      await pump();

      favStream.addError(Exception('db kapalı'));
      await pump();

      favStream.add(<int>[7]);
      await pump();
      expect(controller.favoriteIds, contains(7));
    });

    test('FavoriteController onClose: abonelik iptal edilir (ghost update yok)',
        () async {
      final favRepo = _MockFavoriteRepository();
      final favStream = StreamController<List<int>>.broadcast();
      addTearDown(favStream.close);
      when(() => favRepo.watchFavoriteIds()).thenAnswer((_) => favStream.stream);

      final controller = Get.put<FavoriteController>(FavoriteController(favRepo));
      await pump();

      // GetX silme yolu (Get.delete → onDelete → onClose) aboneliği
      // iptal eder; sonraki olay ölü denetleyiciye yazılamaz.
      expect(await Get.delete<FavoriteController>(), isTrue);
      await pump();
      favStream.add(<int>[9]);
      await pump();
      expect(Get.isRegistered<FavoriteController>(), isFalse);
      expect(controller.favoriteIds, isEmpty);
    });
  });
}
 */