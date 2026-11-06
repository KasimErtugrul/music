import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/datasources/audio_effects_datasource.dart';
import 'package:resonance/data/datasources/metadata_datasource.dart';
import 'package:resonance/data/models/banned_song_model.dart';
import 'package:resonance/data/models/library_settings_model.dart';
import 'package:resonance/data/models/playback_settings_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/history_repository.dart';
import 'package:resonance/data/repositories/equalizer_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/player_repository.dart';
import 'package:resonance/data/repositories/preferences_repository.dart';
import 'package:resonance/data/repositories/queue_state_repository.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/vault_controller.dart';

class _MockPlayerRepository extends Mock implements PlayerRepository {}
class _MockLibraryRepository extends Mock implements LibraryRepository {}
class _MockQueueStateRepository extends Mock implements QueueStateRepository {}
class _MockHistoryRepository extends Mock implements HistoryRepository {}
class _MockPreferencesRepository extends Mock implements PreferencesRepository {}
class _MockAudioEffectsDatasource extends Mock implements AudioEffectsDatasource {}
class _MockMetadataDatasource extends Mock implements MetadataDatasource {}
class _MockEqualizerRepository extends Mock implements EqualizerRepository {}

SongModel _song(int id, String title) => SongModel(
      id: id,
      uri: 'content://media/external/audio/media/$id',
      path: '/music/$id.mp3',
      title: title,
      durationMs: 180000,
      sizeBytes: 4000000,
    );

void main() {
  late _MockPlayerRepository repo;
  late _MockLibraryRepository libRepo;
  late _MockQueueStateRepository stateRepo;
  late _MockHistoryRepository historyRepo;
  // Gün 15: setSpeed/setPitch kalıcılık testi için alan seviyesine alındı.
  late _MockPreferencesRepository prefRepo;
  late PreferencesController prefCtrl;
  late PlayerController controller;

  setUpAll(() {
    registerFallbackValue(<SongModel>[]);
    registerFallbackValue(Duration.zero);
    registerFallbackValue(AudioServiceRepeatMode.none);
    registerFallbackValue(_song(1, 'Fallback'));
    registerFallbackValue(const SongSort());
    registerFallbackValue(const PlaybackSettingsModel());
    registerFallbackValue(const LibrarySettingsModel());
  });

  setUp(() {
    Get.testMode = true;
    repo = _MockPlayerRepository();
    libRepo = _MockLibraryRepository();
    stateRepo = _MockQueueStateRepository();
    historyRepo = _MockHistoryRepository();
    prefRepo = _MockPreferencesRepository();

    when(() => prefRepo.loadPlayback()).thenAnswer((_) async => const PlaybackSettingsModel());
    when(() => prefRepo.loadLibrary()).thenAnswer((_) async => const LibrarySettingsModel());
    // Gün 2 testleri prefCtrl setter'larını kullanıyor → kalıcılık stub'u şart
    when(() => prefRepo.savePlayback(any())).thenAnswer((_) async {});

    prefCtrl = PreferencesController(prefRepo);
    Get.put<PreferencesController>(prefCtrl);

    when(() => repo.mediaItemStream).thenAnswer((_) => const Stream<MediaItem?>.empty());
    when(() => repo.queueStream).thenAnswer((_) => const Stream<List<MediaItem>>.empty());
    when(() => repo.playbackStateStream).thenAnswer((_) => const Stream<PlaybackState>.empty());
    when(() => repo.positionStream).thenAnswer((_) => const Stream<Duration>.empty());
    when(() => repo.durationStream).thenAnswer((_) => const Stream<Duration?>.empty());
    when(() => repo.errorStream).thenAnswer((_) => const Stream<PlayerException>.empty());
    when(() => repo.position).thenReturn(Duration.zero);
    when(() => repo.currentIndex).thenReturn(0);

    when(() => libRepo.songs(sort: any(named: 'sort'))).thenAnswer((_) async => <SongModel>[]);
    when(() => stateRepo.loadState()).thenAnswer((_) async => null);
    when(() => historyRepo.recordPlay(any())).thenAnswer((_) async {});

    when(() => repo.loadQueue(any(), initialIndex: any(named: 'initialIndex'), initialPosition: any(named: 'initialPosition'))).thenAnswer((_) async {});
    when(repo.play).thenAnswer((_) async {});

    // Gün 23'te playSong'a eklendi → mock şart
    when(() => repo.setSpeed(any())).thenAnswer((_) async {});
    when(() => repo.setPitch(any())).thenAnswer((_) async {});
    when(() => repo.setSkipSilenceEnabled(any())).thenAnswer((_) async {});
    // Gün 2: playSong artık varsayılan shuffle/tekrarı da uyguluyor → mock şart
    when(() => repo.setShuffleMode(any())).thenAnswer((_) async {});
    when(() => repo.setRepeatMode(any())).thenAnswer((_) async {});

    controller = PlayerController(repo, libRepo, stateRepo, historyRepo);
    controller.onInit();
  });

  tearDown(Get.reset);

  group('playSong', () {
    test('loads queue and plays at correct index', () async {
      final a = _song(1, 'A');
      final b = _song(2, 'B');

      await controller.playSong(b, queue: <SongModel>[a, b]);

      verify(() => repo.loadQueue(<SongModel>[a, b], initialIndex: 1, initialPosition: any(named: 'initialPosition'))).called(1);
      verify(repo.play).called(1);
    });

    test('single song with null queue defaults to index 0', () async {
      final a = _song(1, 'A');

      await controller.playSong(a);

      verify(() => repo.loadQueue(<SongModel>[a], initialIndex: 0, initialPosition: any(named: 'initialPosition'))).called(1);
    });
  });

  group('togglePlayPause', () {
    test('plays when paused', () async {
      controller.isPlaying.value = false;
      await controller.togglePlayPause();
      verify(repo.play).called(1);
      verifyNever(repo.pause);
    });

    test('pauses when playing', () async {
      when(repo.pause).thenAnswer((_) async {});
      controller.isPlaying.value = true;
      await controller.togglePlayPause();
      verify(repo.pause).called(1);
      verifyNever(repo.play);
    });
  });

  group('shuffle / repeat', () {
    test('toggleShuffle calls setShuffleMode', () async {
      when(() => repo.setShuffleMode(any())).thenAnswer((_) async {});
      expect(controller.shuffleEnabled.value, isFalse);

      await controller.toggleShuffle();

      verify(() => repo.setShuffleMode(true)).called(1);
      expect(controller.shuffleEnabled.value, isTrue);
    });

    test('cycleRepeatMode: none → all → one → none', () async {
      when(() => repo.setRepeatMode(any())).thenAnswer((_) async {});

      expect(controller.repeatMode.value, AudioServiceRepeatMode.none);

      await controller.cycleRepeatMode();
      expect(controller.repeatMode.value, AudioServiceRepeatMode.all);

      await controller.cycleRepeatMode();
      expect(controller.repeatMode.value, AudioServiceRepeatMode.one);

      await controller.cycleRepeatMode();
      expect(controller.repeatMode.value, AudioServiceRepeatMode.none);
    });
  });

  group('mini player kaydırma hareketleri (Aşama 4)', () {
    test('varsayılan görünür; hideMiniPlayer gizler, showMiniPlayer getirir', () {
      // Kalıcı tercih değildir: her yeni controller (oturum) görünür başlar.
      expect(controller.miniPlayerHidden.value, isFalse);

      controller.hideMiniPlayer();
      expect(controller.miniPlayerHidden.value, isTrue);

      controller.showMiniPlayer();
      expect(controller.miniPlayerHidden.value, isFalse);
    });
  });

  group('Gün 2: canlı tercih uygulaması', () {
    // Test başlamadan disk yüklemesi ve _restoreQueue tamamen bitsin;
    // aksi halde _isRestoring koruması yarış yapar.
    Future<void> settle() async {
      await prefCtrl.ready;
      await Future<void>.delayed(Duration.zero);
    }

    test('skipSilence alanı değişince çalan oynatıcıya canlı uygulanır', () async {
      await settle();
      clearInteractions(repo);

      prefCtrl.setSkipSilence(true);
      await Future<void>.delayed(Duration.zero);

      verify(() => repo.setSkipSilenceEnabled(true)).called(1);
    });

    test('alakasız alan değişimi (seekInterval) skipSilence uygulamasını tetiklemez', () async {
      await settle();
      clearInteractions(repo);

      prefCtrl.setSeekInterval(30);
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => repo.setSkipSilenceEnabled(any()));
      expect(prefCtrl.playback.value.seekIntervalSeconds, 30);
    });

    test('replayGain açılınca çalan parçaya anında uygulanır', () async {
      await settle();
      final song = _song(1, 'A');
      controller.songQueue.assignAll([song]);
      controller.currentItem.value = MediaItem(id: song.uri, title: 'A');

      final effects = _MockAudioEffectsDatasource();
      final meta = _MockMetadataDatasource();
      Get.put<AudioEffectsDatasource>(effects);
      Get.put<MetadataDatasource>(meta);
      when(() => meta.replayGainDb(any())).thenAnswer((_) async => 3.0);
      when(() => effects.setLoudnessEnabled(any())).thenAnswer((_) async {});
      when(() => effects.setLoudnessGain(any())).thenAnswer((_) async {});

      prefCtrl.setReplayGain(true);
      await Future<void>.delayed(Duration.zero);

      verify(() => meta.replayGainDb(song)).called(1);
      verify(() => effects.setLoudnessEnabled(true)).called(1);
      verify(() => effects.setLoudnessGain(3.0)).called(1);
    });

    test('replayGain kapatılınca manuel loudness kanalına döner', () async {
      await settle();
      final song = _song(2, 'B');
      controller.songQueue.assignAll([song]);
      controller.currentItem.value = MediaItem(id: song.uri, title: 'B');

      final effects = _MockAudioEffectsDatasource();
      final meta = _MockMetadataDatasource();
      final eqRepo = _MockEqualizerRepository();
      Get.put<AudioEffectsDatasource>(effects);
      Get.put<MetadataDatasource>(meta);
      Get.put<EqualizerRepository>(eqRepo);
      when(() => meta.replayGainDb(any())).thenAnswer((_) async => 2.0);
      when(() => effects.setLoudnessEnabled(any())).thenAnswer((_) async {});
      when(() => effects.setLoudnessGain(any())).thenAnswer((_) async {});
      when(() => eqRepo.loadLoudness()).thenReturn(null);
      when(() => eqRepo.isEnabled()).thenAnswer((_) async => false);

      // Önce açık (başlangıç değeri false), sonra kapat: kapalı yolu izole etmek için
      // ikinci geçişten önceki etkileşimler temizlenir.
      prefCtrl.setReplayGain(true);
      await Future<void>.delayed(Duration.zero);
      clearInteractions(effects);

      prefCtrl.setReplayGain(false);
      await Future<void>.delayed(Duration.zero);

      verify(() => effects.setLoudnessEnabled(false)).called(1);
      verify(() => effects.setLoudnessGain(0.0)).called(1);
    });

    test('çalan parça yokken replayGain değişimi hiçbir şeye dokunmaz', () async {
      await settle();
      final effects = _MockAudioEffectsDatasource();
      final meta = _MockMetadataDatasource();
      Get.put<AudioEffectsDatasource>(effects);
      Get.put<MetadataDatasource>(meta);
      when(() => meta.replayGainDb(any())).thenAnswer((_) async => 1.0);

      prefCtrl.setReplayGain(true);
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => meta.replayGainDb(any()));
      verifyNever(() => effects.setLoudnessEnabled(any()));
    });

    test('playSong yeni kuyrukta varsayılan shuffle/tekrarı uygular ve Rx senkronlar', () async {
      await settle();
      prefCtrl.setDefaultShuffle(true);
      prefCtrl.setDefaultRepeat(2);
      clearInteractions(repo);

      await controller.playSong(_song(5, 'E'));

      verify(() => repo.setShuffleMode(true)).called(1);
      verify(() => repo.setRepeatMode(AudioServiceRepeatMode.one)).called(1);
      expect(controller.shuffleEnabled.value, isTrue);
      expect(controller.repeatMode.value, AudioServiceRepeatMode.one);
    });

    test('yeni kuyruk önceki manuel shuffle durumunu varsayılanla ezer', () async {
      await settle();
      expect(controller.shuffleEnabled.value, isFalse);

      await controller.toggleShuffle(); // kullanıcının manuel tercihi
      expect(controller.shuffleEnabled.value, isTrue);

      // Geri yükleme düşüşü (fallback) ve toggle de desteği işaretledi;
      // yalnız playSong'un kendi çağrısını izole etmek için temizle.
      clearInteractions(repo);

      // defaultShuffle=false: yeni kuyruk manuel durumu varsayılanla değiştirir.
      await controller.playSong(_song(6, 'F'));

      verify(() => repo.setShuffleMode(false)).called(1);
      expect(controller.shuffleEnabled.value, isFalse);
    });
  });

  // Gün 15: hız/perde kalıcılığı tek doğruluk kaynağına taşındı. Eskiden
  // harici oynatıcının hız döngüsü yalnız canlı depo çağrısı yapıyor,
  // kalıcı tercihe yazmıyordu; SpeedPitchSheet ise iki controller'a birden
  // dokunuyordu. Yeni sözleşme: PlayerController.setSpeed/setPitch hem
  // canlı depoya hem kalıcı tercihe yazar.
  group('Gün 15: hız/perde kalıcılığı', () {
    test('setSpeed canlı depoyu ve kalıcı tercihi birlikte yazar', () async {
      await controller.setSpeed(1.25);

      verify(() => repo.setSpeed(1.25)).called(1);
      verify(() => prefRepo.savePlayback(any())).called(1);
      expect(prefCtrl.playback.value.speed, 1.25);
    });

    test('setPitch canlı depoyu ve kalıcı tercihi birlikte yazar', () async {
      await controller.setPitch(0.9);

      verify(() => repo.setPitch(0.9)).called(1);
      verify(() => prefRepo.savePlayback(any())).called(1);
      expect(prefCtrl.playback.value.pitch, 0.9);
    });

    test('quickSpeeds, SpeedPitchSheet\'in eski sabitiyle aynı adımlardır', () {
      expect(PlayerController.quickSpeeds, <double>[0.8, 1.0, 1.25, 1.5]);
    });
  });

  group('Gün 17: kasa koruması', () {
    test('kasadaki şarkı playSong ile çalınamaz (depo hiç dokunulmaz)',
        () async {
      final v = _StubVault(bannedPaths: {'/music/7.mp3'});
      final guarded = PlayerController(repo, libRepo, stateRepo, historyRepo,
          vault: v);
      guarded.onInit();

      final ok = await guarded.playSong(_song(7, 'Yasaklı'));

      expect(ok, isFalse);
      verifyNever(() => repo.loadQueue(any(),
          initialIndex: any(named: 'initialIndex'),
          initialPosition: any(named: 'initialPosition')));
      verifyNever(repo.play);
      verifyNever(() => historyRepo.recordPlay(any()));
    });

    test('kasadaki şarkı kuyruğa da eklenemez', () async {
      final v = _StubVault(bannedPaths: {'/music/8.mp3'});
      final guarded = PlayerController(repo, libRepo, stateRepo, historyRepo,
          vault: v);
      guarded.onInit();

      await guarded.addToQueue(_song(8, 'Yasaklı 2'));

      expect(guarded.songQueue, isEmpty);
      verifyNever(() => repo.insertSong(any(), any()));
    });

    test('kasada olmayan şarkı normal çalar (koruma saydamdır)', () async {
      final v = _StubVault(bannedPaths: {'/music/8.mp3'});
      final guarded = PlayerController(repo, libRepo, stateRepo, historyRepo,
          vault: v);
      guarded.onInit();

      final ok = await guarded.playSong(_song(9, 'Serbest'));

      expect(ok, isTrue);
      verify(() => repo.loadQueue(any(),
          initialIndex: any(named: 'initialIndex'),
          initialPosition: any(named: 'initialPosition'))).called(1);
      verify(repo.play).called(1);
    });
  });
  // Bulgu 1: karıştırma/tekrar iki yönlü senkron. Medya oturumu
  // (bildirim kartı, Bluetooth/AVRCP, sesli asistan, Android Auto)
  // handler.setShuffleMode/setRepeatMode çağırdığında handler yeni
  // PlaybackState yayınlar; denetleyici bu alanları okumazsa tüm mod
  // rozetleri bayat kalır ve _saveQueueState yanlış modu diske yazar.
  group('Bulgu 1: medya oturumu ters-yönlü senkron', () {
    test('yayındaki shuffle/tekrar alanları Rx\'leri canlı günceller', () async {
      final states = StreamController<PlaybackState>.broadcast();
      addTearDown(states.close);
      when(() => repo.playbackStateStream).thenAnswer((_) => states.stream);
      when(() => stateRepo.clearState()).thenAnswer((_) async {});

      final synced = PlayerController(repo, libRepo, stateRepo, historyRepo);
      synced.onInit();
      await Future<void>.delayed(Duration.zero);

      // Kurulum/geri yükleme çağrılarını izole et; yalnız yayın sürüklü
      // etkileşimleri ölç.
      clearInteractions(repo);

      expect(synced.shuffleEnabled.value, isFalse);
      expect(synced.repeatMode.value, AudioServiceRepeatMode.none);

      // Dış dünyadan «karıştır'ı aç + tekrarı bir'e al» (asistan/ARB davranışı).
      states.add(PlaybackState(
        shuffleMode: AudioServiceShuffleMode.all,
        repeatMode: AudioServiceRepeatMode.one,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(synced.shuffleEnabled.value, isTrue);
      expect(synced.repeatMode.value, AudioServiceRepeatMode.one);

      // Dış dünyadan kapatma: Rx'ler geri döner (yayın tek doğruluk kaynağı).
      states.add(PlaybackState(
        shuffleMode: AudioServiceShuffleMode.none,
        repeatMode: AudioServiceRepeatMode.none,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(synced.shuffleEnabled.value, isFalse);
      expect(synced.repeatMode.value, AudioServiceRepeatMode.none);

      // Yayın dinleyicisi depoya GERİ YAZMAZ (döngü riski yok);
      // geri yazma yalnız kullanıcı eylemlerinde (toggle*) olur.
      verifyNever(() => repo.setShuffleMode(any()));
      verifyNever(() => repo.setRepeatMode(any()));
    });

    test('toggleShuffle sonrası yayın aynı değere yakınsar (çift yazım yok)', () async {
      final states = StreamController<PlaybackState>.broadcast();
      addTearDown(states.close);
      when(() => repo.playbackStateStream).thenAnswer((_) => states.stream);

      final synced = PlayerController(repo, libRepo, stateRepo, historyRepo);
      synced.onInit();
      await Future<void>.delayed(Duration.zero);
      clearInteractions(repo);

      // Kullanıcı eylemi: iyimser Rx yazımı + depo çağrısı.
      await synced.toggleShuffle();
      expect(synced.shuffleEnabled.value, isTrue);
      verify(() => repo.setShuffleMode(true)).called(1);
      clearInteractions(repo);

      // Depodan dönen yayın aynı değeri taşır: Rx değişmez, depo dokunulmaz.
      states.add(PlaybackState(shuffleMode: AudioServiceShuffleMode.all));
      await Future<void>.delayed(Duration.zero);

      expect(synced.shuffleEnabled.value, isTrue);
      verifyNever(() => repo.setShuffleMode(any()));
    });
  });

  // Bulgu 4: kasa kümesi değiştiğinde ÇALAN kuyruk da reaktif arınmalı.
  // Eski davranışta kuyruk «anlık kopya» olarak bayat kalıyordu; kuyrukta
  // duran yasaklı şarkı parça bitiminde (doğal geçiş) veya next() ile
  // ÇALIYORDU. Yeni değişmez: «canlı kuyrukta yasaklı kayıt bulunamaz.»
  group('Bulgu 4: kasa değişiminde canlı kuyruk temizliği', () {
    Future<void> pump() async {
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('kuyruktaki yasaklı şarkı, kasa kümesi değişince kuyruktan düşer',
        () async {
      final a = _song(1, 'A');
      final b = _song(2, 'B');
      final c = _song(3, 'C');
      final v = _StubVault();
      final guarded = PlayerController(
        repo,
        libRepo,
        stateRepo,
        historyRepo,
        vault: v,
      );
      guarded.onInit();
      await pump();

      when(() => repo.removeSong(any())).thenAnswer((_) async {});
      clearInteractions(repo);

      guarded.songQueue.assignAll([a, b, c]); // çalan: index 0 (A)
      v.publishBan(b); // VaultController._syncFrom sözleşmesi: küme+entries
      await pump();

      expect(guarded.songQueue, [a, c]);
      verify(() => repo.removeSong(1)).called(1);
      // Çalan korunur: kuyruk boşalmadıysa stop YOK.
      verifyNever(repo.stop);
    });

    test('çalan parça kasaya alınırsa kuyruk sonraki kayda ilerler',
        () async {
      final a = _song(1, 'A');
      final b = _song(2, 'B');
      final c = _song(3, 'C');
      final v = _StubVault();
      final guarded = PlayerController(
        repo,
        libRepo,
        stateRepo,
        historyRepo,
        vault: v,
      );
      guarded.onInit();
      await pump();

      when(() => repo.currentIndex).thenReturn(1); // çalan: B
      when(() => repo.removeSong(any())).thenAnswer((_) async {});
      clearInteractions(repo);

      guarded.songQueue.assignAll([a, b, c]);
      v.publishBan(b);
      await pump();

      expect(guarded.songQueue, [a, c]);
      verify(() => repo.removeSong(1)).called(1);
      verifyNever(repo.stop);
    });

    test('çoklu yasak: alttan silme motor indisini kaydırır, çalan korunur',
        () async {
      final a = _song(1, 'A');
      final b = _song(2, 'B');
      final c = _song(3, 'C');
      final d = _song(4, 'D');
      final v = _StubVault();
      final guarded = PlayerController(
        repo,
        libRepo,
        stateRepo,
        historyRepo,
        vault: v,
      );
      guarded.onInit();
      await pump();

      // Motor taklidi: çalanın ALTINDAKİ kayıt silinirse indis kayar
      // (just_audio semantiği); temizlik motorun GÜNCEL indisini okur.
      var engineIndex = 1; // çalan: B
      when(() => repo.currentIndex).thenAnswer((_) => engineIndex);
      when(() => repo.removeSong(any())).thenAnswer((inv) async {
        final i = inv.positionalArguments[0] as int;
        if (i < engineIndex) engineIndex--;
      });
      clearInteractions(repo);

      guarded.songQueue.assignAll([a, b, c, d]);
      v.publishBan(a);
      v.publishBan(c); // üst üste iki olay: koşular serileştirip birleşmeli
      await pump();

      // a ve c düşer; çalan b ve yasaksız d kalır.
      expect(guarded.songQueue, [b, d]);
      // 1. koşu: a (indis 0, çalanın altı → motor indisini kaydırır).
      // 2. koşu BAYAT İNDESLERLE DEĞİL, küçülmüş kuyrukta yeniden hesaplar:
      // c artık indis 2 değil 1'dedir.
      verifyInOrder([
        () => repo.removeSong(0),
        () => repo.removeSong(1),
      ]);
      expect(engineIndex, 0); // çalan hâlâ B (indis 1→0 kaydı)
    });

    test('kuyrukta yasaklı yoksa temizlik hiçbir depo çağrısı yapmaz',
        () async {
      final a = _song(1, 'A');
      final v = _StubVault();
      final guarded = PlayerController(
        repo,
        libRepo,
        stateRepo,
        historyRepo,
        vault: v,
      );
      guarded.onInit();
      await pump();
      clearInteractions(repo);

      guarded.songQueue.assignAll([a]);
      v.publishBan(_song(9, 'Kuyrukta yok')); // alakasız ban → no-op
      await pump();

      expect(guarded.songQueue, [a]);
      verifyNever(() => repo.removeSong(any()));
      verifyNever(repo.stop);
    });

    test('tek kayıtlı kuyrukta çalan kasaya alınırsa çalma durur',
        () async {
      final a = _song(1, 'A');
      final v = _StubVault();
      final guarded = PlayerController(
        repo,
        libRepo,
        stateRepo,
        historyRepo,
        vault: v,
      );
      guarded.onInit();
      await pump();

      when(() => repo.currentIndex).thenReturn(0);
      when(() => repo.removeSong(any())).thenAnswer((_) async {});
      when(repo.stop).thenAnswer((_) async {});
      clearInteractions(repo);

      guarded.songQueue.assignAll([a]);
      v.publishBan(a);
      await pump();

      expect(guarded.songQueue, isEmpty);
      verify(() => repo.removeSong(0)).called(1);
      verify(repo.stop).called(1);
    });

    test('yeni kuyruk kasaya göre filtrelenir (son savunma hattı)',
        () async {
      final a = _song(1, 'A');
      final banned = _song(2, 'Yasak');
      final b = _song(3, 'C');
      final v = _StubVault(bannedPaths: {'/music/2.mp3'});
      final guarded = PlayerController(
        repo,
        libRepo,
        stateRepo,
        historyRepo,
        vault: v,
      );
      guarded.onInit();
      await pump();
      clearInteractions(repo);

      final ok = await guarded.playSong(a, queue: [a, banned, b]);

      expect(ok, isTrue);
      expect(guarded.songQueue, [a, b]);
      verify(() => repo.loadQueue(
            <SongModel>[a, b],
            initialIndex: 0,
            initialPosition: any(named: 'initialPosition'),
          )).called(1);
    });
  });
}

/// Gün 17: yol bazlı sahte kasa — isBanned sözleşmesi + Bulgu 4 canlı
/// entries bildirimi taşır.
///
/// [publishBan], VaultController._syncFrom sözleşmesinin aynısıdır:
/// kümler ÖNCE, entries SONRA güncellenir (aksi hâlde abone bir tur
/// bayat küme okurdu).
class _StubVault implements VaultController {
  _StubVault({Set<String> bannedPaths = const <String>{}})
      : bannedPaths = Set<String>.of(bannedPaths);

  final Set<String> bannedPaths;

  @override
  final entries = <BannedSongModel>[].obs;

  /// Testte «ban» eylemi: küme + entries aynı sözleşmeyle yayına girer.
  void publishBan(SongModel song) {
    bannedPaths.add(song.path);
    entries.add(
      BannedSongModel(
        id: entries.length + 1,
        songId: song.id,
        path: song.path,
        title: song.title,
        createdAt: DateTime(2026),
      ),
    );
  }

  @override
  bool isBanned(SongModel song) => bannedPaths.contains(song.path);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}