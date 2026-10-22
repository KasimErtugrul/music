import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/history_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/player_repository.dart';
import 'package:resonance/data/repositories/queue_state_repository.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';

class _MockPlayerRepository extends Mock implements PlayerRepository {}
class _MockLibraryRepository extends Mock implements LibraryRepository {}
class _MockQueueStateRepository extends Mock implements QueueStateRepository {}
class _MockHistoryRepository extends Mock implements HistoryRepository {}

SongModel _song(int id) => SongModel(
      id: id,
      uri: 'uri/$id',
      path: '/path/$id.mp3',
      title: 'Song $id',
      durationMs: 1000,
      sizeBytes: 100,
    );

void main() {
  late _MockPlayerRepository repo;
  late _MockLibraryRepository libRepo;
  late _MockQueueStateRepository stateRepo;
  late _MockHistoryRepository historyRepo;
  late PlayerController controller;

  setUpAll(() {
    registerFallbackValue(<SongModel>[]);
    registerFallbackValue(Duration.zero);
    registerFallbackValue(const SongSort());
  });

  setUp(() {
    Get.testMode = true;
    repo = _MockPlayerRepository();
    libRepo = _MockLibraryRepository();
    stateRepo = _MockQueueStateRepository();
    historyRepo = _MockHistoryRepository();

    when(() => repo.mediaItemStream)
        .thenAnswer((_) => const Stream<MediaItem?>.empty());
    when(() => repo.queueStream)
        .thenAnswer((_) => const Stream<List<MediaItem>>.empty());
    when(() => repo.playbackStateStream)
        .thenAnswer((_) => const Stream<PlaybackState>.empty());
    when(() => repo.positionStream)
        .thenAnswer((_) => const Stream<Duration>.empty());
    when(() => repo.durationStream)
        .thenAnswer((_) => const Stream<Duration?>.empty());
    when(() => repo.errorStream)
        .thenAnswer((_) => const Stream<PlayerException>.empty());
    when(() => repo.position).thenReturn(Duration.zero);

    when(() => libRepo.songs(sort: any(named: 'sort')))
        .thenAnswer((_) async => <SongModel>[]);
    when(() => stateRepo.loadState()).thenAnswer((_) async => null);
    when(() => historyRepo.recordPlay(any())).thenAnswer((_) async {});

    when(() => repo.loadQueue(
          any(),
          initialIndex: any(named: 'initialIndex'),
          initialPosition: any(named: 'initialPosition'),
        )).thenAnswer((_) async {});
    when(repo.play).thenAnswer((_) async {});

    controller = PlayerController(repo, libRepo, stateRepo, historyRepo);
    controller.onInit();
  });

  tearDown(Get.reset);

  test('playNext adds to queue at correct position', () async {
    final a = _song(1);
    final b = _song(2);
    final c = _song(3);

    await controller.playSong(a, queue: <SongModel>[a, b]);
    expect(controller.songQueue.map((s) => s.id), <int>[1, 2]);

    controller.currentItem.value = MediaItem(id: a.uri, title: a.title);

    clearInteractions(repo);

    await controller.playNext(c);

    expect(controller.songQueue.map((s) => s.id), <int>[1, 3, 2]);
    verify(() => repo.loadQueue(
          any(),
          initialIndex: 0,
          initialPosition: any(named: 'initialPosition'),
        )).called(1);
  });

  test('addToQueue appends to end', () async {
    final a = _song(1);
    final b = _song(2);

    await controller.playSong(a, queue: <SongModel>[a]);
    controller.currentItem.value = MediaItem(id: a.uri, title: a.title);

    clearInteractions(repo);

    await controller.addToQueue(b);

    expect(controller.songQueue.map((s) => s.id), <int>[1, 2]);
    verify(() => repo.loadQueue(
          any(),
          initialIndex: 0,
          initialPosition: any(named: 'initialPosition'),
        )).called(1);
  });
}