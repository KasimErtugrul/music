// Zengin kütüphane kartı sözleşmesi (SongTile.detailed) — V3.
//
// V3 (kullanıcı şablonu): dört satırlık sütun — 1. şarkı adı,
// 2. ALBÜM adı (sanatçı satırı yok), 3. varsa çalma listesi rozeti
// (kendi satırında), 4. «MP3/128kbps» biçiminde format satırı.
// Kuyruk sayfası da AYNI şablonu kullanır (tek şablon ilkesi).
// «ÇALIYOR» etiketi zengin modda çizilmez (etiket başlığı yutuyordu).
//
// Kilitlenen davranışlar:
// * detailed: true → «MP3/128kbps» biçiminde TEK format satırı;
//   ikinci satır albüm; tür (genre) çizilmez; «PLAYING» çizilmez.
// * detailed: false (varsayılan) → format satırı çizilmez, «PLAYING»
//   etiketi çalınan şarkıda aynen korunur (diğer sayfalar etkilenmez).
// * Meta verisi hiç olmayan şarkıda (uzantısız yol, boyut 0) format
//   satırı çizilmez — taşma/istisna yok.
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/favorite_repository.dart';
import 'package:resonance/data/repositories/playlist_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/favorite_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/playlist_controller.dart';
import 'package:resonance/presentation/ui/widgets/song_tile.dart';

class _MockFavRepo extends Mock implements FavoriteRepository {}

class _MockPlaylistRepo extends Mock implements PlaylistRepository {}

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
  String? album,
  int durationMs = 200000,
  int sizeBytes = 3200000,
}) => SongModel(
  id: id,
  uri: 'content://media/external/audio/media/$id',
  path: path,
  title: 'Song $id',
  album: album,
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
          // Üretim paritesi: zengin kart 96dp, kompakt 72dp.
          body: SongTile(
            song: song,
            detailed: detailed,
            height: detailed ? 96 : 72,
          ),
        ),
      ),
    ),
  );

  testWidgets('V3 şablonu: ikinci satır ALBÜM adıdır, sanatçı çizilmez', (
    tester,
  ) async {
    putPlayerAndFavorites();

    await pumpTile(tester, _song(id: 0, album: 'Nightfall'), detailed: true);
    await tester.pumpAndSettle();

    expect(find.text('Nightfall'), findsOneWidget);
    // V3: sanatçı adı şablonda yer almaz.
    expect(find.text('Unknown artist'), findsNothing);
  });

  testWidgets('V3 şablonu: format satırı «MP3/128kbps» biçimindedir', (
    tester,
  ) async {
    putPlayerAndFavorites();

    await pumpTile(tester, _song(id: 1, genre: 'Rock'), detailed: true);
    await tester.pumpAndSettle();

    expect(find.text('MP3/128kbps'), findsOneWidget);
    // V3: tür hücresi yok, eski « · » ayraçlı biçim de yok.
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

    expect(find.text('FLAC/128kbps'), findsOneWidget);
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
    expect(find.text('MP3/128kbps'), findsNothing);
  });

  testWidgets('zengin kartta çalma listesi rozeti kendi satırında', (
    tester,
  ) async {
    final plRepo = _MockPlaylistRepo();
    when(() => plRepo.getPlaylists()).thenAnswer((_) async => []);
    when(() => plRepo.playlistNamesBySong()).thenAnswer(
      (_) async => {
        5: <String>['Rock', 'Workout'],
      },
    );
    putPlayerAndFavorites();
    Get.put<PlaylistController>(PlaylistController(plRepo));

    // Kütüphane/kuyruk paritesi: rozet bayrağı sayfalar tarafından
    // açılır; düzeneğimiz de aynı bayrağı geçer.
    await tester.pumpWidget(
      GetMaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SongTile(
            song: _song(id: 5, album: 'Nightfall'),
            height: 96,
            showPlaylistBadge: true,
            detailed: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Kullanıcı şablonu: albüm satırı ile format satırı AYRI; liste
    // rozeti kendi satırında («İlkAd +N» biçimi korunur).
    expect(find.text('Nightfall'), findsOneWidget);
    expect(find.text('Rock +1'), findsOneWidget);
    expect(find.text('MP3/128kbps'), findsOneWidget);
  });

  testWidgets('meta verisi olmayan şarkıda format satırı çizilmez', (
    tester,
  ) async {
    putPlayerAndFavorites();

    await pumpTile(
      tester,
      _song(id: 5, path: '/music/noextension', genre: null, sizeBytes: 0),
      detailed: true,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('kbps'), findsNothing);
    expect(find.textContaining('/'), findsNothing);
    expect(find.textContaining('MP3'), findsNothing);
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
