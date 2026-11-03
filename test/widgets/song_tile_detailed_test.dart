// Zengin kütüphane kartı sözleşmesi (SongTile.detailed) — V2.
//
// V2 (kullanıcı geri bildirimi): ilk sürümdeki dört ayrı künye hücesi
// (codec, bit hızı, tür) dar satırda üç noktaya dönüşüyordu; codec ve
// bit hızı tek hücrede birleştirildi, tür hücresi kaldırıldı. «ÇALIYOR»
// etiketi de zengin modda çizilmez (etiket başlığı yutuyordu).
//
// Kilitlenen davranışlar:
// * detailed: true → «MP3 · 128 kbps» biçiminde TEK format hücesi;
//   tür (genre) çizilmez; «PLAYING» etiketi çizilmez.
// * detailed: false (varsayılan) → künye hücesi çizilmez, «PLAYING»
//   etiketi çalınan şarkıda aynen korunur (diğer sayfalar etkilenmez).
// * Meta verisi hiç olmayan şarkıda (uzantısız yol, boyut 0) hüce
//   çizilmez — taşma/istisna yok.
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
  final InternalFinalCallback<void> onStart = InternalFinalCallback<void>(
    callback: () {},
  );

  @override
  final InternalFinalCallback<void> onDelete = InternalFinalCallback<void>(
    callback: () {},
  );
}

/// 3.200.000 bayt / 200 s → 8 × 3.200.000 / 200.000 = 128.000 bit/s =
/// tam 128 kbps: yuvarlamaya dayanmayan, elle doğrulanabilir değer.
SongModel _song({
  required int id,
  String path = '/music/song.mp3',
  String? genre,
  int durationMs = 200000,
  int sizeBytes = 3200000,
}) => SongModel(
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

  void putPlayerAndFavorites({MediaItem? current}) {
    final player = _FakePlayerController();
    when(() => player.currentItem).thenReturn(Rxn<MediaItem>(current));
    when(() => player.isPlaying).thenReturn(false.obs);
    Get
      ..put<PlayerController>(player)
      ..put<FavoriteController>(FavoriteController(favRepo));
  }

  Future<void> pumpTile(
    WidgetTester tester,
    SongModel song, {
    bool detailed = false,
    double textScale = 1.0,
  }) => tester.pumpWidget(
    GetMaterialApp(
      // Alt başlıkta l10n («Bilinmeyen sanatçı/album») okunur.
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData().copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: SongTile(song: song, detailed: detailed),
        ),
      ),
    ),
  );

  testWidgets('zengin kartta codec ve bit hızı TEK hücede', (tester) async {
    putPlayerAndFavorites();

    await pumpTile(tester, _song(id: 1, genre: 'Rock'), detailed: true);
    await tester.pumpAndSettle();

    expect(find.text('MP3 · 128 kbps'), findsOneWidget);
    // V2: tür hücresi kaldırıldı.
    expect(find.text('Rock'), findsNothing);
    expect(find.text('MP3'), findsNothing);
    expect(find.text('128 kbps'), findsNothing);
  });

  testWidgets('kayıpsız uzantı da tek formatta görünür', (tester) async {
    putPlayerAndFavorites();

    await pumpTile(
      tester,
      _song(id: 2, path: '/music/song.flac'),
      detailed: true,
    );
    await tester.pumpAndSettle();

    expect(find.text('FLAC · 128 kbps'), findsOneWidget);
  });

  testWidgets('zengin kartta «PLAYING» etiketi çizilmez', (tester) async {
    final song = _song(id: 3);
    putPlayerAndFavorites(
      current: MediaItem(id: song.uri, title: song.title),
    );

    await pumpTile(tester, song, detailed: true);
    await tester.pumpAndSettle();

    expect(find.text('PLAYING'), findsNothing);
  });

  testWidgets('kompakt modda «PLAYING» etiketi korunur', (tester) async {
    final song = _song(id: 4);
    putPlayerAndFavorites(
      current: MediaItem(id: song.uri, title: song.title),
    );

    await pumpTile(tester, song); // detailed: false (varsayılan)
    await tester.pumpAndSettle();

    expect(find.text('PLAYING'), findsOneWidget);
    expect(find.text('MP3 · 128 kbps'), findsNothing);
  });

  testWidgets('meta verisi olmayan şarkıda hüce çizilmez', (tester) async {
    putPlayerAndFavorites();

    await pumpTile(
      tester,
      _song(id: 5, path: '/music/noextension', genre: null, sizeBytes: 0),
      detailed: true,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('kbps'), findsNothing);
    expect(find.textContaining('·'), findsNothing);
  });

  testWidgets('sistem yazı tipi ölçeği 2.0x iken kart taşmaz', (tester) async {
    // Erişilebilirlik sözleşmesi: kullanıcı sistem ölçeğini abartılı
    // büyüttüğünde kartın kepenk (1.3x) devreye girer ve layout
    // «RenderFlex overflowed» hatası FIRLATMAZ. Zengin ve kompakt
    // modun ikisi de denetlenir.
    putPlayerAndFavorites();

    await pumpTile(
      tester,
      _song(id: 6, genre: null),
      detailed: true,
      textScale: 2.0,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await pumpTile(tester, _song(id: 7, genre: null), textScale: 2.0);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
