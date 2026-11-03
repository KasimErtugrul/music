// Zengin kütüphane kartı sözleşmesi (SongTile.detailed).
//
// SongTile PlayerController + FavoriteController'ı Get.find ile zorunlu
// bulur; düzenek ikisini de kurar. Kilitlenen davranışlar:
// * detailed: true → codec (uzantıdan), ortalama bit hızı (boyut/süre)
//   ve tür künye şeridi çizilir; kayıpsız uzantı (FLAC) da etiket olur.
// * detailed: false (varsayılan) → künye şeridi çizilmez; favoriler,
//   arama, klasör, kuyruk gibi sayfaların kompakt görünümü korunur.
// * Meta verisi hiç olmayan şarkıda (uzantısız yol, boyut 0, tür yok)
//   şerit boş küçülür — taşma/istisna yok.
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/favorite_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/favorite_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/widgets/song_tile.dart';

class _MockFavRepo extends Mock implements FavoriteRepository {}

/// GetX 4.7 yaşam döngüsü düzeltmesi (song_tile_playlist_badge_test'teki
/// düzenin aynısı): mock yaşam döngüsü no-op olur.
class _FakePlayerController extends Mock implements PlayerController {
  @override
  final InternalFinalCallback<void> onStart =
      InternalFinalCallback<void>(callback: () {});

  @override
  final InternalFinalCallback<void> onDelete =
      InternalFinalCallback<void>(callback: () {});
}

/// 3.200.000 bayt / 200 s → 8 × 3.200.000 / 200.000 = 128.000 bit/s =
/// tam 128 kbps: yuvarlamaya dayanmayan, elle doğrulanabilir değer.
SongModel _song({
  required int id,
  String path = '/music/song.mp3',
  String? genre,
  int durationMs = 200000,
  int sizeBytes = 3200000,
}) =>
    SongModel(
      id: id,
      uri: 'content://media/external/audio/media/$id',
      path: path,
      title: 'Song $id',
      genre: genre,
      durationMs: durationMs,
      sizeBytes: sizeBytes,
    );

void main() {
  late _MockFavRepo favRepo;

  setUp(() {
    Get.testMode = true;
    favRepo = _MockFavRepo();
    when(() => favRepo.watchFavoriteIds())
        .thenAnswer((_) => const Stream<List<int>>.empty());
  });

  tearDown(Get.reset);

  void putPlayerAndFavorites() {
    final player = _FakePlayerController();
    when(() => player.currentItem).thenReturn(Rxn<MediaItem>());
    when(() => player.isPlaying).thenReturn(false.obs);
    Get
      ..put<PlayerController>(player)
      ..put<FavoriteController>(FavoriteController(favRepo));
  }

  Future<void> pumpTile(
    WidgetTester tester,
    SongModel song, {
    bool detailed = false,
  }) =>
      tester.pumpWidget(
        GetMaterialApp(
          // Alt başlıkta l10n («Bilinmeyen sanatçı/album») okunur.
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SongTile(song: song, detailed: detailed),
          ),
        ),
      );

  testWidgets('zengin kart codec, bit hızı ve türü çizer', (tester) async {
    putPlayerAndFavorites();

    await pumpTile(
      tester,
      _song(id: 1, genre: 'Rock'),
      detailed: true,
    );
    await tester.pumpAndSettle();

    expect(find.text('MP3'), findsOneWidget);
    expect(find.text('128 kbps'), findsOneWidget);
    expect(find.text('Rock'), findsOneWidget);
  });

  testWidgets('kayıpsız uzantı da codec etiketi olarak görünür',
      (tester) async {
    putPlayerAndFavorites();

    await pumpTile(
      tester,
      _song(id: 2, path: '/music/song.flac'),
      detailed: true,
    );
    await tester.pumpAndSettle();

    expect(find.text('FLAC'), findsOneWidget);
  });

  testWidgets('kompakt modda künye şeridi çizilmez (diğer sayfalar korunur)',
      (tester) async {
    putPlayerAndFavorites();

    await pumpTile(
      tester,
      _song(id: 3, genre: 'Rock'),
      // detailed: false (varsayılan)
    );
    await tester.pumpAndSettle();

    expect(find.text('MP3'), findsNothing);
    expect(find.text('128 kbps'), findsNothing);
    expect(find.text('Rock'), findsNothing);
  });

  testWidgets('meta verisi olmayan şarkıda şerit boş küçülür', (tester) async {
    putPlayerAndFavorites();

    await pumpTile(
      tester,
      _song(
        id: 4,
        path: '/music/noextension',
        genre: null,
        sizeBytes: 0,
      ),
      detailed: true,
    );
    await tester.pumpAndSettle();

    expect(find.text(' kbps'), findsNothing);
    expect(find.text('Rock'), findsNothing);
  });
}
