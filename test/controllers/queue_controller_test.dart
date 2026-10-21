import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/player_repository.dart';
import 'package:resonance/data/repositories/queue_state_repository.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';

class _MockPlayerRepository extends Mock implements PlayerRepository {}
class _MockLibraryRepository extends Mock implements LibraryRepository {}
class _MockQueueStateRepository extends Mock implements QueueStateRepository {}

SongModel _song(int id) => SongModel(
      id: id, uri: 'uri/$id', path: '/path/$id.mp3', title: 'Song $id', durationMs: 1000, sizeBytes: 100,
    );

void main() {
  late _MockPlayerRepository repo;
  late _MockLibraryRepository libRepo;
  late _MockQueueStateRepository stateRepo;
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

    when(() => repo.mediaItemStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.queueStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.playbackStateStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.positionStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.durationStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.errorStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.position).thenReturn(Duration.zero);
    
    when(() => libRepo.songs(sort: any(named: 'sort'))).thenAnswer((_) async => <SongModel>[]);
    when(() => stateRepo.loadState()).thenAnswer((_) async => null);

    when(() => repo.loadQueue(any(), initialIndex: any(named: 'initialIndex'), initialPosition: any(named: 'initialPosition')))
        .thenAnswer((_) async {});
    when(repo.play).thenAnswer((_) async {});

    controller = PlayerController(repo, libRepo, stateRepo);
    controller.onInit();
  });

  tearDown(Get.reset);

  test('playNext adds to queue at correct position', () async {
    final a = _song(1);
    final b = _song(2);
    final c = _song(3);

    await controller.playSong(a, queue: [a, b]);
    expect(controller.songQueue.map((s) => s.id), [1, 2]);

    // Simüle et: a çalıyor
    controller.currentItem.value = MediaItem(id: a.uri, title: a.title);

    // ÖNEMLİ: Önceki `playSong` çağrısının tetiklediği loadQueue'yu
    // saymamak için mock geçmişini temizle.
    clearInteractions(repo);

    await controller.playNext(c);

    expect(controller.songQueue.map((s) => s.id), [1, 3, 2]);
    verify(() => repo.loadQueue(
          any(),
          initialIndex: 0,
          initialPosition: any(named: 'initialPosition'),
        )).called(1);
  });

  test('addToQueue appends to end', () async {
    final a = _song(1);
    final b = _song(2);

    await controller.playSong(a, queue: [a]);
    controller.currentItem.value = MediaItem(id: a.uri, title: a.title);

    clearInteractions(repo);

    await controller.addToQueue(b);

    expect(controller.songQueue.map((s) => s.id), [1, 2]);
    verify(() => repo.loadQueue(
          any(),
          initialIndex: 0,
          initialPosition: any(named: 'initialPosition'),
        )).called(1);
  });
}