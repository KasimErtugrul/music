/* // FAZ 7 (Bulgu 1/2/3/10/17 + düşük öncelik): kalan tutarlılık ailesi.
//
// * Bulgu 10 — LibraryController.loadAll/_reloadLists sıralama yarışı
//   (setSongSort:123 korumasının kardeşi) + refresh() isAutoScanning
//   kapsamı ve _lastScanAt güncellemesi.
// * Bulgu 1 — ExcludedFoldersController klasör değişimi artık
//   LibraryController'ın Rx listelerini tazeler (Vault _applyFilterChange
//   deseni: isRegistered + loadAll).
// * Bulgu 2 — PlaylistController.addSongToPlaylist TOCTOU: _adding guard
//   ikinci hızlı dokunuşu pencereye girmeden false ile döndürür.
// * Bulgu 3 — ExternalOpenController izin/rota kapısı: splash/permission/
  // onboarding ekranlarının üstüne offAllNamed basılmaz; niyet pendingUri
//   olarak saklanır ve PermissionController.media granted olduğunda
//   oynatılır.
// * Bulgu 17 — reloadLivePlaylistControllers açık detayı da tazeler.
// * Düşük öncelik — SettingsController._load hata sözleşmesi (spinner
//   sonsuza dek dönmez), SleepTimer.handleEnd temizliği (pause patlarsa
//   bile bayraklar iner, abonelikler iptal).
import 'dart:async';

import 'package:audio_service/audio_service.dart'
    show AudioProcessingState, AudioServiceRepeatMode, MediaItem;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/utils/permission_helper.dart';
import 'package:resonance/data/models/excluded_folder_model.dart';
import 'package:resonance/data/models/playlist_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/excluded_folder_repository.dart';
import 'package:resonance/data/repositories/external_intent_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/playlist_repository.dart';
import 'package:resonance/data/repositories/settings_repository.dart';
import 'package:resonance/presentation/controllers/excluded_folders_controller.dart';
import 'package:resonance/presentation/controllers/external_open_controller.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/controllers/live_settings_reload.dart';
import 'package:resonance/presentation/controllers/permission_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/playlist_controller.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';
import 'package:resonance/presentation/controllers/sleep_timer_controller.dart';

class _MockLibraryRepository extends Mock implements LibraryRepository {}
class _MockExcludedFolderRepository extends Mock
    implements ExcludedFolderRepository {}
class _MockPlaylistRepository extends Mock implements PlaylistRepository {}
class _MockExternalIntentRepository extends Mock
    implements ExternalIntentRepository {}
class _MockPermissionHelper extends Mock implements PermissionHelper {}
class _MockSettingsRepository extends Mock implements SettingsRepository {}

/// GetX 4.7.3 kaynak zorunluluğu (Kural 2; sleep_timer_controller_test
/// deseninin aynısı): Get.put → _startController → i.onStart() mock'ta
/// null döner → TypeError. GetLifeCycle callback'leri ve SleepTimer'ın
/// abone olduğu Rx üyeleri GERÇEK örneklerle somut override edilir.
class _MockPlayerController extends Mock implements PlayerController {
  @override
  final onStart = InternalFinalCallback<void>(callback: () {});
  @override
  final onDelete = InternalFinalCallback<void>(callback: () {});
  @override
  final processingState = AudioProcessingState.idle.obs;
  @override
  final currentItem = Rxn<MediaItem>();
  @override
  final repeatMode = AudioServiceRepeatMode.none.obs;
  @override
  final position = Duration.zero.obs;
  @override
  final duration = Duration.zero.obs;
}

SongModel _song(int id) => SongModel(
      id: id,
      uri: 'content://media/external/audio/media/$id',
      path: '/music/$id.mp3',
      title: 'Şarkı $id',
      durationMs: 180000,
      sizeBytes: 4000000,
    );

PlaylistModel _playlist(int id) => PlaylistModel(
      id: id,
      name: 'Liste $id',
      songCount: 0,
      updatedAt: DateTime(2026),
    );

void main() {
  setUpAll(() {
    Get.testMode = true;
    registerFallbackValue(const SongSort());
    registerFallbackValue(<SongModel>[]);
    registerFallbackValue(_song(1));
    registerFallbackValue('');
    registerFallbackValue(const LibraryScanDelta(changed: false));
  });

  tearDown(Get.reset);

  Future<void> pump() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  group('Bulgu 10: LibraryController sıralama yarışı + refresh kapsamı', () {
    test('loadAll sürerken setSongSort yapılırsa bayat sıra yeniyi EZMEZ',
        () async {
      final repo = _MockLibraryRepository();
      final oldSort = const SongSort();
      final newSort =
          const SongSort(field: SongSortField.artist);
      final gate = Completer<List<SongModel>>();
      when(() => repo.songs(sort: oldSort)).thenAnswer((_) => gate.future);
      when(() => repo.songs(sort: newSort))
          .thenAnswer((_) async => <SongModel>[_song(2)]);
      when(() => repo.letterOffsets(any()))
          .thenAnswer((_) async => const <String, int>{});
      when(repo.albums).thenAnswer((_) async => []);
      when(repo.artists).thenAnswer((_) async => []);
      when(repo.genres).thenAnswer((_) async => []);
      when(repo.folders).thenAnswer((_) async => []);

      final controller = LibraryController(repo);
      controller.onInit();
      await pump(); // loadAll gate'te bekliyor

      // Kullanıcı yükleme sürerken sıralamayı değiştirir: kendi sonucunu
      // yazar (şarkı 2). setSongSort Rx'i kendisi yazar.
      await controller.setSongSort(newSort);
      expect(controller.songs.map((s) => s.id), contains(2));

      // Eski yükleme biter: BAYAT sıralı sonuç (şarkı 1) yazılmamalı.
      gate.complete(<SongModel>[_song(1)]);
      await controller.loadAll();
      expect(controller.songs.map((s) => s.id), contains(2));
      expect(controller.songs.map((s) => s.id), isNot(contains(1)));
    });

    test('refresh() otomatik tarama alanına girer; sürerken autoScan koşmaz',
        () async {
      final repo = _MockLibraryRepository();
      final gate = Completer<void>();
      when(() => repo.rescan()).thenAnswer((_) => gate.future);
      when(() => repo.songs(sort: any(named: 'sort')))
          .thenAnswer((_) async => []);
      when(() => repo.letterOffsets(any()))
          .thenAnswer((_) async => const <String, int>{});
      when(repo.albums).thenAnswer((_) async => []);
      when(repo.artists).thenAnswer((_) async => []);
      when(repo.genres).thenAnswer((_) async => []);
      when(repo.folders).thenAnswer((_) async => []);
      when(() => repo.incrementalScan(
            triggerPlatformScan: any(named: 'triggerPlatformScan'),
          )).thenAnswer((_) async => const LibraryScanDelta(changed: false));

      final controller = LibraryController(repo);
      // onInit'in açılış yüklemesini bekle; etkileşimleri izole et.
      controller.onInit();
      await pump();
      clearInteractions(repo);

      final refreshing = controller.refresh();
      expect(controller.isAutoScanning.value, isTrue);

      // Manuel yenileme sürerken otomatik tarama koşMAZ (Bulgu 10).
      await controller.autoScan();
      verifyNever(() => repo.incrementalScan(
            triggerPlatformScan: any(named: 'triggerPlatformScan'),
          ));

      gate.complete();
      await refreshing;
      expect(controller.isAutoScanning.value, isFalse);
    });
  });

  group('Bulgu 1: hariç tutulan klasör → kütüphane tazelemesi', () {
    test('addFolder sonrası LibraryController.loadAll çalışır', () async {
      final repo = _MockLibraryRepository();
      final excludedRepo = _MockExcludedFolderRepository();
      when(() => excludedRepo.getExcludedFolders())
          .thenAnswer((_) async => const <ExcludedFolderModel>[]);
      when(() => excludedRepo.addFolder(any())).thenAnswer((_) async {});
      when(() => repo.rescan()).thenAnswer((_) async {});
      when(() => repo.songs(sort: any(named: 'sort')))
          .thenAnswer((_) async => <SongModel>[_song(9)]);
      when(() => repo.letterOffsets(any()))
          .thenAnswer((_) async => const <String, int>{});
      when(repo.albums).thenAnswer((_) async => []);
      when(repo.artists).thenAnswer((_) async => []);
      when(repo.genres).thenAnswer((_) async => []);
      when(repo.folders).thenAnswer((_) async => []);
      when(() => repo.incrementalScan(
            triggerPlatformScan: any(named: 'triggerPlatformScan'),
          )).thenAnswer((_) async => const LibraryScanDelta(changed: false));

      final library = Get.put<LibraryController>(LibraryController(repo));
      library.onInit();
      await pump();
      clearInteractions(repo); // açılış etkileşimlerini izole et

      final ctrl = ExcludedFoldersController(excludedRepo, repo);
      await ctrl.addFolder('/music/yasak');

      // Kütüphane sekmesi pull-to-refresh BEKLEMEDEN güncel listeyi görür
      // ve rescan + loadAll zinciri çalışır (Bulgu 1 öncesi yalnız rescan).
      expect(library.songs.map((s) => s.id), contains(9));
      verify(() => repo.rescan()).called(1);
      verify(() => repo.songs(sort: any(named: 'sort'))).called(1);
    });
  });

  group('Bulgu 2: playlist ekleme TOCTOU', () {
    test('çift hızlı dokunuşta ikinci çağrı pencereye girmeden false döner; '
        'add bir kez çağrılır', () async {
      final repo = _MockPlaylistRepository();
      final gate = Completer<bool>();
      when(() => repo.isSongInPlaylist(any(), any()))
          .thenAnswer((_) => gate.future);
      when(() => repo.addSong(any(), any())).thenAnswer((_) async {});
      when(() => repo.getPlaylists())
          .thenAnswer((_) async => const <PlaylistModel>[]);
      when(() => repo.playlistNamesBySong())
          .thenAnswer((_) async => const <int, List<String>>{});
      when(() => repo.getPlaylist(any())).thenAnswer((_) async => null);
      when(() => repo.getSongs(any())).thenAnswer((_) async => []);

      final controller = PlaylistController(repo);
      controller.onInit();
      await pump();

      final first = controller.addSongToPlaylist(5, _song(1));
      await pump(); // ilk çağrı isSongInPlaylist gate'inde
      final second = controller.addSongToPlaylist(5, _song(1));

      expect(await second, isFalse); // Bulgu 2: pencereye girmeden reddedildi
      gate.complete(false); // şarkı listede yok → ilk çağrı ekler
      expect(await first, isTrue);
      verify(() => repo.addSong(any(), any())).called(1);
    });
  });

  group('Bulgu 3: harici dosya niyeti izin/rota kapısı', () {
    Future<PermissionController> makePermission(AppPermissionStatus status) async {
      final helper = _MockPermissionHelper();
      when(helper.mediaStatus).thenAnswer((_) async => status);
      when(helper.notificationPermissionRequired).thenAnswer((_) async => false);
      when(helper.notificationStatus).thenAnswer((_) async => status);
      final ctrl = PermissionController(helper);
      ctrl.onInit();
      await pump();
      return ctrl;
    }

    PlayerController makePlayer() {
      final player = _MockPlayerController();
      when(() => player.playSong(any(), queue: any(named: 'queue')))
          .thenAnswer((_) async => true);
      return player;
    }

    test('izin sayfasındayken niyet OYNATILMAZ; izin gelince oynatılır',
        () async {
      final perm = await makePermission(AppPermissionStatus.denied);
      final repo = _MockExternalIntentRepository();
      const uri = 'content://media/external/audio/media/777';
      when(() => repo.getInitialUri()).thenAnswer((_) async => uri);
      when(() => repo.listenForNewIntents(any())).thenReturn(null);

      final player = makePlayer();
      final navigated = <String>[];
      final controller = ExternalOpenController(
        repo,
        player,
        permission: perm,
        initialDelay: Duration.zero,
        playDelay: Duration.zero,
        currentRoute: () => AppRoutes.permission,
        navigate: navigated.add,
      );
      controller.onInit();
      await pump();

      // Kapı kapalı: playSong hiç çağrılmaz, niyet bekler.
      expect(controller.pendingUri.value, uri);
      verifyNever(() => player.playSong(any(), queue: any(named: 'queue')));

      // İzin verilir (onboarding sayfa 3 / izin sayfası tamamlandı):
      // ever(media) bekleyen niyeti oynatır.
      perm.media.value = AppPermissionStatus.granted;
      await pump();

      verify(() => player.playSong(any(), queue: any(named: 'queue')))
          .called(1);
      expect(navigated, contains(AppRoutes.externalPlayer));
      expect(controller.pendingUri.value, isNull);
    });

    test('kapı açıksa (izin + home) niyet hemen oynatılır', () async {
      final perm = await makePermission(AppPermissionStatus.granted);
      final repo = _MockExternalIntentRepository();
      const uri = 'content://media/external/audio/media/888';
      when(() => repo.getInitialUri()).thenAnswer((_) async => uri);
      when(() => repo.listenForNewIntents(any())).thenReturn(null);

      final player = makePlayer();
      final navigated = <String>[];
      final controller = ExternalOpenController(
        repo,
        player,
        permission: perm,
        initialDelay: Duration.zero,
        playDelay: Duration.zero,
        currentRoute: () => AppRoutes.home,
        navigate: navigated.add,
      );
      controller.onInit();
      await pump();

      verify(() => player.playSong(any(), queue: any(named: 'queue')))
          .called(1);
      expect(navigated, contains(AppRoutes.externalPlayer));
      expect(controller.pendingUri.value, isNull);
    });
  });

  group('Bulgu 17: yedek içe aktarmada açık detay tazelenir', () {
    test('currentPlaylist doluysa loadPlaylistDetail yeniden çalışır',
        () async {
      final repo = _MockPlaylistRepository();
      when(() => repo.getPlaylists())
          .thenAnswer((_) async => <PlaylistModel>[_playlist(5)]);
      when(() => repo.playlistNamesBySong())
          .thenAnswer((_) async => const <int, List<String>>{});
      when(() => repo.getPlaylist(any()))
          .thenAnswer((_) async => _playlist(5));
      when(() => repo.getSongs(any())).thenAnswer((_) async => []);

      final controller = Get.put<PlaylistController>(PlaylistController(repo));
      controller.onInit();
      await pump();
      await controller.loadPlaylistDetail(5);
      clearInteractions(repo);

      await reloadLivePlaylistControllers();

      // Liste VE açık detay tazelendi (Bulgu 17 öncesi yalnız liste).
      verify(() => repo.getPlaylists()).called(1);
      verify(() => repo.getPlaylist(5)).called(1);
      verify(() => repo.getSongs(5)).called(1);
    });
  });

  group('Düşük öncelik sağlamlaştırmalar', () {
    test('SettingsController._load hatada spinner sonsuza dek dönmez',
        () async {
      final repo = _MockSettingsRepository();
      when(() => repo.load()).thenThrow(Exception('platform hatası'));

      final controller = SettingsController(repo);
      controller.onInit();
      await pump();

      expect(controller.isLoading.value, isFalse); // kök kapı açılır
      expect(controller.settings.value, isNull); // varsayılanlarla devam
    });

    test('SleepTimer.handleEnd: pause patlarsa bile temizlik yapılır',
        () async {
      final player = _MockPlayerController();
      when(player.pause).thenThrow(Exception('rampa hatası'));
      when(() => player.setSleepDamping(any())).thenReturn(null);

      Get.put<PlayerController>(player);
      final ctrl = SleepTimerController();
      ctrl.onInit();
      await pump();

      ctrl.startEndOfTrack();
      expect(ctrl.isEndOfTrackMode.value, isTrue);

      // Parça sonu olayı gelir; pause() HATA ATAR — bayraklar yine iner,
      // abonelikler iptal edilir (denetim düşük öncelik kalemi).
      player.processingState.value = AudioProcessingState.completed;
      await pump();

      expect(ctrl.isEndOfTrackMode.value, isFalse);
      expect(ctrl.isActive.value, isFalse);
    });
  });
}
 */