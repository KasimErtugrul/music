// Gün 21: SongTile üyelik rozeti sözleşmesi.
//
// SongTile PlayerController + FavoriteController'ı Get.find ile zorunlu
// bulur; düzenek üç denetleyiciyi de kurar. Kilitlenen davranışlar:
// * showPlaylistBadge: true + PlaylistController kayıtlı → şarkının
//   listeleri rozette görünür; iki liste varsa «İlkAd +1» biçimi.
// * Bayrak kapalı → ad çizilmez (albüm/sanatçı/arama sayfalarının
//   bugünkü görünümü korunur).
// * PlaylistController kayıtlı DEĞİL → rozet sessizce atlanır
//   («not found» patlaması yok — Gün 20.1'in isRegistered sözleşmesi).
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

/// GetX 4.7 yaşam döngüsü düzeltmesi (playlist_controller_play_test'teki
/// düzenin aynısı): `extends Mock implements` temel sınıfın final
/// InternalFinalCallback alanlarını devralmadığı için boş geri çağrılı
/// gerçek örneklerle ezilir; mock yaşam döngüsü no-op olur.
class _FakePlayerController extends Mock implements PlayerController {
  @override
  final InternalFinalCallback<void> onStart =
      InternalFinalCallback<void>(callback: () {});

  @override
  final InternalFinalCallback<void> onDelete =
      InternalFinalCallback<void>(callback: () {});
}

SongModel _song(int id) => SongModel(
      id: id,
      uri: 'content://media/external/audio/media/$id',
      path: '/music/$id.mp3',
      title: 'Song $id',
      durationMs: 180000,
      sizeBytes: 4000000,
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

  /// Ortak düzenek: oynatıcı + favori her testte, playlist yalnız
  /// isteyen testlerde kurulur. SongTile isPlaying/currentItem okur;
  /// ikisi de boş/çalmıyor stub'lanır.
  void putPlayerAndFavorites() {
    final player = _FakePlayerController();
    when(() => player.currentItem).thenReturn(Rxn<MediaItem>());
    when(() => player.isPlaying).thenReturn(false.obs);
    Get
      ..put<PlayerController>(player)
      ..put<FavoriteController>(FavoriteController(favRepo));
  }

  Future<void> pumpTile(WidgetTester tester, SongModel song,
          {bool badge = false}) =>
      tester.pumpWidget(
        GetMaterialApp(
          // SongTile alt başlıkta l10n («Bilinmeyen sanatçı/album»)
          // okur: düzenek yerelleştirmeyi sağlamalı.
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SongTile(song: song, showPlaylistBadge: badge),
          ),
        ),
      );

  testWidgets('iki listedeki şarkı «İlkAd +1» rozeti çizer', (tester) async {
    final plRepo = _MockPlaylistRepo();
    when(() => plRepo.getPlaylists()).thenAnswer((_) async => []);
    when(() => plRepo.playlistNamesBySong()).thenAnswer((_) async => {
          1: <String>['Rock', 'Workout'],
        });
    putPlayerAndFavorites();
    Get.put<PlaylistController>(PlaylistController(plRepo));

    await pumpTile(tester, _song(1), badge: true);
    await tester.pumpAndSettle();

    expect(find.text('Rock +1'), findsOneWidget);
    expect(find.byIcon(Icons.queue_music), findsOneWidget);
  });

  testWidgets('tek listedeki şarkı yalnız liste adını gösterir',
      (tester) async {
    final plRepo = _MockPlaylistRepo();
    when(() => plRepo.getPlaylists()).thenAnswer((_) async => []);
    when(() => plRepo.playlistNamesBySong())
        .thenAnswer((_) async => {2: <String>['Rock']});
    putPlayerAndFavorites();
    Get.put<PlaylistController>(PlaylistController(plRepo));

    await pumpTile(tester, _song(2), badge: true);
    await tester.pumpAndSettle();

    expect(find.text('Rock'), findsOneWidget);
  });

  testWidgets('bayrak kapalıyken ad çizilmez (diğer sayfalar korunur)',
      (tester) async {
    final plRepo = _MockPlaylistRepo();
    when(() => plRepo.getPlaylists()).thenAnswer((_) async => []);
    when(() => plRepo.playlistNamesBySong())
        .thenAnswer((_) async => {2: <String>['Rock']});
    putPlayerAndFavorites();
    Get.put<PlaylistController>(PlaylistController(plRepo));

    await pumpTile(tester, _song(2)); // badge: false (varsayılan)
    await tester.pumpAndSettle();

    expect(find.text('Rock'), findsNothing);
    expect(find.byIcon(Icons.queue_music), findsNothing);
  });

  testWidgets('PlaylistController kayıtlı değilse rozet sessizce atlanır',
      (tester) async {
    putPlayerAndFavorites();
    // PlaylistController KASITLI olarak kurulmaz.

    await pumpTile(tester, _song(2), badge: true);
    await tester.pumpAndSettle();

    expect(find.text('Rock'), findsNothing);
    expect(find.byIcon(Icons.queue_music), findsNothing);
  });

  testWidgets('hiç listeye girmemiş şarkıda rozet yok', (tester) async {
    final plRepo = _MockPlaylistRepo();
    when(() => plRepo.getPlaylists()).thenAnswer((_) async => []);
    when(() => plRepo.playlistNamesBySong())
        .thenAnswer((_) async => <int, List<String>>{});
    putPlayerAndFavorites();
    Get.put<PlaylistController>(PlaylistController(plRepo));

    await pumpTile(tester, _song(9), badge: true);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.queue_music), findsNothing);
  });
}