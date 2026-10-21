import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/player_repository.dart';
import 'package:resonance/data/repositories/queue_state_repository.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';

class _MockPlayerRepository extends Mock implements PlayerRepository {}
class _MockLibraryRepository extends Mock implements LibraryRepository {}
class _MockQueueStateRepository extends Mock implements QueueStateRepository {}

SongModel _song(int id, String title) => SongModel(
      id: id, uri: 'content://media/external/audio/media/$id', path: '/music/$id.mp3',
      title: title, durationMs: 180000, sizeBytes: 4000000,
    );

void main() {
  late _MockPlayerRepository repo;
  late _MockLibraryRepository libRepo;
  late _MockQueueStateRepository stateRepo;
  late PlayerController controller;

  setUpAll(() {
    registerFallbackValue(<SongModel>[]);
    registerFallbackValue(Duration.zero);
    registerFallbackValue(AudioServiceRepeatMode.none);
    registerFallbackValue(const SongSort());
  });

  setUp(() {
    Get.testMode = true;
    repo = _MockPlayerRepository();
    libRepo = _MockLibraryRepository();
    stateRepo = _MockQueueStateRepository();

    when(() => repo.mediaItemStream).thenAnswer((_) => const Stream<MediaItem?>.empty());
    when(() => repo.queueStream).thenAnswer((_) => const Stream<List<MediaItem>>.empty());
    when(() => repo.playbackStateStream).thenAnswer((_) => const Stream<PlaybackState>.empty());
    when(() => repo.positionStream).thenAnswer((_) => const Stream<Duration>.empty());
    when(() => repo.durationStream).thenAnswer((_) => const Stream<Duration?>.empty());
    when(() => repo.errorStream).thenAnswer((_) => const Stream<PlayerException>.empty());
    when(() => repo.position).thenReturn(Duration.zero);
    
    when(() => libRepo.songs(sort: any(named: 'sort'))).thenAnswer((_) async => <SongModel>[]);
    when(() => stateRepo.loadState()).thenAnswer((_) async => null);

    controller = PlayerController(repo, libRepo, stateRepo);
    controller.onInit();
  });

  tearDown(Get.reset);

  group('playSong', () {
    test('loads queue and plays at correct index', () async {
      final a = _song(1, 'A');
      final b = _song(2, 'B');

      when(() => repo.loadQueue(
            any(),
            initialIndex: any(named: 'initialIndex'),
          )).thenAnswer((_) async {});
      when(repo.play).thenAnswer((_) async {});

      await controller.playSong(b, queue: <SongModel>[a, b]);

      verify(() => repo.loadQueue(<SongModel>[a, b], initialIndex: 1))
          .called(1);
      verify(repo.play).called(1);
    });

    test('single song with null queue defaults to index 0', () async {
      final a = _song(1, 'A');

      when(() => repo.loadQueue(
            any(),
            initialIndex: any(named: 'initialIndex'),
          )).thenAnswer((_) async {});
      when(repo.play).thenAnswer((_) async {});

      await controller.playSong(a);

      verify(() => repo.loadQueue(<SongModel>[a], initialIndex: 0)).called(1);
    });

    test('unknown song falls back to index 0', () async {
      final a = _song(1, 'A');
      final stranger = _song(99, 'X');

      when(() => repo.loadQueue(
            any(),
            initialIndex: any(named: 'initialIndex'),
          )).thenAnswer((_) async {});
      when(repo.play).thenAnswer((_) async {});

      await controller.playSong(stranger, queue: <SongModel>[a]);

      verify(() => repo.loadQueue(<SongModel>[a], initialIndex: 0)).called(1);
    });
  });

  group('togglePlayPause', () {
    test('plays when paused', () async {
      when(repo.play).thenAnswer((_) async {});
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
}