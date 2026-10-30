import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/datasources/audio_effects_datasource.dart';
import 'package:resonance/data/datasources/metadata_datasource.dart';
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
    final prefRepo = _MockPreferencesRepository();

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
}