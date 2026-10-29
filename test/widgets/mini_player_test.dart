import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/models/library_settings_model.dart';
import 'package:resonance/data/models/playback_settings_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/history_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/player_repository.dart';
import 'package:resonance/data/repositories/preferences_repository.dart';
import 'package:resonance/data/repositories/queue_state_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/widgets/mini_player.dart';

class _MockPlayerRepository extends Mock implements PlayerRepository {}
class _MockLibraryRepository extends Mock implements LibraryRepository {}
class _MockQueueStateRepository extends Mock implements QueueStateRepository {}
class _MockHistoryRepository extends Mock implements HistoryRepository {}
class _MockPreferencesRepository extends Mock implements PreferencesRepository {}

SongModel _song(int id, String title) => SongModel(
      id: id,
      uri: 'content://media/external/audio/media/$id',
      path: '/music/$id.mp3',
      title: title,
      durationMs: 180000,
      sizeBytes: 4000000,
    );

/// Aşama 4: MiniPlayer kaydırma hareketleri widget testleri.
///  • aşağı kaydırma → kart ince tutamağa küçülür
///  • tutamağa dokunma / yukarı kaydırma → kart geri açılır
///  • sola fling → sonraki parça, sağa fling → önceki parça
void main() {
  late _MockPlayerRepository repo;
  late _MockLibraryRepository libRepo;
  late _MockQueueStateRepository stateRepo;
  late _MockHistoryRepository historyRepo;
  late PlayerController controller;

  setUpAll(() {
    registerFallbackValue(<SongModel>[]);
    registerFallbackValue(Duration.zero);
    // historyRepo.recordPlay(any()) SongModel tipinde parametre alır;
    // fallback yoksa ilk setUp'da "registerFallbackValue was not previously
    // called" fırlar ve mocktail state'i bozularak sonraki tüm when'ler
    // "Cannot call `when` within a stub response" ile düşer.
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
    Get.put<PreferencesController>(PreferencesController(prefRepo));

    when(() => repo.mediaItemStream).thenAnswer((_) => const Stream<MediaItem?>.empty());
    when(() => repo.queueStream).thenAnswer((_) => const Stream<List<MediaItem>>.empty());
    when(() => repo.playbackStateStream).thenAnswer((_) => const Stream<PlaybackState>.empty());
    when(() => repo.positionStream).thenAnswer((_) => const Stream<Duration>.empty());
    when(() => repo.durationStream).thenAnswer((_) => const Stream<Duration?>.empty());
    when(() => repo.errorStream).thenAnswer((_) => const Stream<PlayerException>.empty());
    when(() => repo.position).thenReturn(Duration.zero);
    when(() => repo.currentIndex).thenReturn(0);
    when(() => libRepo.songs(sort: any(named: 'sort'))).thenAnswer((_) async => <SongModel>[]);
    when(() => libRepo.artwork(any(), size: any(named: 'size'))).thenAnswer((_) async => null);
    when(() => stateRepo.loadState()).thenAnswer((_) async => null);
    when(() => historyRepo.recordPlay(any())).thenAnswer((_) async {});

    when(() => repo.loadQueue(any(), initialIndex: any(named: 'initialIndex'), initialPosition: any(named: 'initialPosition'))).thenAnswer((_) async {});
    when(repo.play).thenAnswer((_) async {});
    when(() => repo.setSpeed(any())).thenAnswer((_) async {});
    when(() => repo.setPitch(any())).thenAnswer((_) async {});
    when(() => repo.setSkipSilenceEnabled(any())).thenAnswer((_) async {});

    // ArtworkImage Get.find<LibraryRepository>() ile kapak çeker.
    Get.put<LibraryRepository>(libRepo);

    controller = PlayerController(repo, libRepo, stateRepo, historyRepo);
    controller.onInit();

    // Oynanmakta olan şarkı görünümü: currentItem + kuyruk + index 0.
    controller.currentItem.value = MediaItem(
      id: 'content://media/external/audio/media/1',
      album: 'Album',
      title: 'A',
    );
    controller.songQueue.assignAll(<SongModel>[_song(1, 'A')]);
  });

  tearDown(Get.reset);

  Future<void> pumpMini(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SizedBox.shrink(),
          bottomNavigationBar: MiniPlayer(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('aşağı kaydırma kartı ince tutamağa küçültür', (tester) async {
    await pumpMini(tester);

    expect(find.text('A'), findsOneWidget);
    expect(find.byTooltip('Show mini player'), findsNothing);

    await tester.fling(find.text('A'), const Offset(0, 80), 900);
    await tester.pumpAndSettle();

    expect(controller.miniPlayerHidden.value, isTrue);
    expect(find.byTooltip('Show mini player'), findsOneWidget);
    expect(find.text('A'), findsNothing);
  });

  testWidgets('tutamağa dokunmak kartı geri açar', (tester) async {
    await pumpMini(tester);

    controller.hideMiniPlayer();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Show mini player'), findsOneWidget);
    expect(find.text('A'), findsNothing);

    await tester.tap(find.byTooltip('Show mini player'));
    await tester.pumpAndSettle();

    expect(controller.miniPlayerHidden.value, isFalse);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('tutamağı yukarı kaydırmak da kartı geri açar', (tester) async {
    await pumpMini(tester);

    controller.hideMiniPlayer();
    await tester.pumpAndSettle();

    await tester.fling(find.byTooltip('Show mini player'), const Offset(0, -60), 900);
    await tester.pumpAndSettle();

    expect(controller.miniPlayerHidden.value, isFalse);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('sola fling sonraki, sağa fling önceki parçayı ister', (tester) async {
    when(repo.skipToNext).thenAnswer((_) async {});
    when(repo.skipToPrevious).thenAnswer((_) async {});
    await pumpMini(tester);

    // Sola hızlı kaydırma → sonraki parça.
    await tester.fling(find.text('A'), const Offset(-120, 0), 900);
    await tester.pumpAndSettle();
    verify(repo.skipToNext).called(1);

    // Sağa hızlı kaydırma → önceki parça.
    await tester.fling(find.text('A'), const Offset(120, 0), 900);
    await tester.pumpAndSettle();
    verify(repo.skipToPrevious).called(1);
  });

  testWidgets('yavaş yatay sürükleme parça atlatmaz (fling eşiği)', (tester) async {
    when(repo.skipToNext).thenAnswer((_) async {});
    when(repo.skipToPrevious).thenAnswer((_) async {});
    await pumpMini(tester);

    // Düşük hız: eşiği (±350) geçmez, parça atlanmamalı.
    await tester.fling(find.text('A'), const Offset(-120, 0), 120);
    await tester.pumpAndSettle();

    verifyNever(repo.skipToNext);
    verifyNever(repo.skipToPrevious);
  });

  testWidgets('şarkı yokken kart ve tutamak çizilmez', (tester) async {
    controller.currentItem.value = null;
    controller.songQueue.clear();
    await pumpMini(tester);

    expect(find.text('A'), findsNothing);
    expect(find.byTooltip('Show mini player'), findsNothing);
  });
}
