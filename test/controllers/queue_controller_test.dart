import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/models/library_settings_model.dart';
import 'package:resonance/data/models/playback_settings_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/history_repository.dart';
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
  late PreferencesController prefCtrl;
  late PlayerController controller;

  setUpAll(() {
    registerFallbackValue(<SongModel>[]);
    registerFallbackValue(Duration.zero);
    registerFallbackValue(_song(1));
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

    prefCtrl = PreferencesController(prefRepo);
    Get.put<PreferencesController>(prefCtrl);

    when(() => repo.mediaItemStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.queueStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.playbackStateStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.positionStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.durationStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.errorStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.position).thenReturn(Duration.zero);
    when(() => repo.currentIndex).thenReturn(0);

    when(() => libRepo.songs(sort: any(named: 'sort'))).thenAnswer((_) async => []);
    when(() => stateRepo.loadState()).thenAnswer((_) async => null);
    when(() => historyRepo.recordPlay(any())).thenAnswer((_) async {});

    when(() => repo.loadQueue(any(), initialIndex: any(named: 'initialIndex'), initialPosition: any(named: 'initialPosition'))).thenAnswer((_) async {});
    when(() => repo.insertSong(any(), any())).thenAnswer((_) async {});
    when(() => repo.removeSong(any())).thenAnswer((_) async {});
    when(() => repo.moveSong(any(), any())).thenAnswer((_) async {});
    when(repo.play).thenAnswer((_) async {});

    // Gün 23'te playSong'a eklendi → mock şart
    when(() => repo.setSpeed(any())).thenAnswer((_) async {});
    when(() => repo.setPitch(any())).thenAnswer((_) async {});
    when(() => repo.setSkipSilenceEnabled(any())).thenAnswer((_) async {});

    controller = PlayerController(repo, libRepo, stateRepo, historyRepo);
    controller.onInit();
  });

  tearDown(Get.reset);

  test('playNext uses insertSong', () async {
    final a = _song(1);
    final b = _song(2);
    final c = _song(3);

    await controller.playSong(a, queue: [a, b]);
    when(() => repo.currentIndex).thenReturn(0);

    await controller.playNext(c);

    expect(controller.songQueue.map((s) => s.id), [1, 3, 2]);
    verify(() => repo.insertSong(1, c)).called(1);
  });
}