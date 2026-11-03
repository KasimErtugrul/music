// Kuyruk sayfası V3 TEK ŞABLON sözleşmesi.
//
// Kullanıcı isteği: kütüphane kartındaki dört satırlık sütun (şarkı
// adı / albüm / varsa listeler / «MP3/144kbps») kuyrukta da AYNI olsun.
// Bu test kilitler:
// * «Sıradakiler» satırı SongTile(detailed) şablonunu kullanır: albüm
//   satırı ve format satırı kuyrukta da görünür; sürükleme tutamacı
//   (drag_indicator) şablonun dışında korunur.
// * «Son çalınanlar» bölümü de aynı şablonu kullanır (sönük çizilir).
// * Şu anki kayda dokunma playFromQueue'ya gider (kuyruk yeniden
//   kurulmaz) — davranış Bulgu 3'ten beri sabittir.
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
import 'package:resonance/presentation/ui/pages/queue_page.dart';

class _MockFavRepo extends Mock implements FavoriteRepository {}

/// GetX 4.7 yaşam döngüsü düzeltmesi + QueuePage/MiniPlayer/SongTile'ın
/// okuduğu reaktif alanların gerçek (Rx) örnekleri. Yöntemler mock
/// no-op kalır; sayfa yalnız okuma yapar.
class _FakePlayerController extends Mock implements PlayerController {
  @override
  final InternalFinalCallback<void> onStart = InternalFinalCallback<void>(
    callback: () {},
  );

  @override
  final InternalFinalCallback<void> onDelete = InternalFinalCallback<void>(
    callback: () {},
  );

  @override
  final songQueue = <SongModel>[].obs;

  @override
  final isPlaying = false.obs;

  @override
  final currentItem = Rxn<MediaItem>();

  @override
  final position = Duration.zero.obs;

  @override
  final duration = Duration.zero.obs;

  @override
  final miniPlayerHidden = false.obs;

  // MiniPlayer kartı (PlayerControls) bu alanları da okur — stub'suz
  // mock Null döndürür ve Obx içinde tip hatası fırlar.
  @override
  final shuffleEnabled = false.obs;

  @override
  final repeatMode = AudioServiceRepeatMode.none.obs;

  int _index = -1;

  @override
  int? get currentQueueIndex => _index;

  set currentIndex(int value) => _index = value;

  /// Gerçek denetleyiciyle aynı türetme; ÜSTELİK songQueue[idx] üzerinden
  /// OKUR — MiniPlayer'ın Obx'i böylece reaktif abone olur (mock getter
  /// reaktifsiz kaldığı için GetX «improper use» hatası fırlatıyordu).
  @override
  SongModel? get currentSong {
    final idx = currentQueueIndex;
    if (idx == null || idx < 0 || idx >= songQueue.length) return null;
    return songQueue[idx];
  }
}

/// 3.600.000 bayt / 200 s → 8 × 3.600.000 / 200.000 = 144.000 bit/s =
/// tam 144 kbps: yuvarlamaya dayanmayan, elle doğrulanabilir değer.
SongModel _song(
  int id, {
  required String title,
  String? album,
  int durationMs = 200000,
  int sizeBytes = 3600000,
}) => SongModel(
  id: id,
  uri: 'content://media/external/audio/media/$id',
  path: '/music/$id.mp3',
  title: title,
  album: album,
  durationMs: durationMs,
  sizeBytes: sizeBytes,
);

void main() {
  late _MockFavRepo favRepo;
  late _FakePlayerController player;

  setUp(() {
    Get.testMode = true;
    favRepo = _MockFavRepo();
    when(() => favRepo.watchFavoriteIds())
        .thenAnswer((_) => const Stream<List<int>>.empty());

    player = _FakePlayerController();
    // Kuyruk: [0] geçmiş, [1] şu an çalan, [2] sıradaki.
    player.songQueue.addAll([
      _song(0, title: 'Past Song', album: '80s Classics'),
      _song(1, title: 'Now Song'),
      _song(2, title: 'Next Song', album: 'Nightfall'),
    ]);
    player.currentIndex = 1;
    // QueuePage, «şu an çalan»ı kuyruk URI'siyle doğrular (Bulgu 3
    // sözleşmesi): MediaItem id'si kuyruğun 1. elemanının uri'sidir.
    player.currentItem.value = MediaItem(
      id: player.songQueue[1].uri,
      title: 'Now Song',
    );

    Get
      ..put<PlayerController>(player)
      ..put<FavoriteController>(FavoriteController(favRepo));
  });

  tearDown(Get.reset);

  Future<void> pumpPage(WidgetTester tester) => tester.pumpWidget(
    GetMaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const QueuePage(),
    ),
  );

  testWidgets('kuyruk satırları V3 şablonunu kullanır: albüm + format '
      'satırı görünür, tutamaç korunur', (tester) async {
    await pumpPage(tester);
    await tester.pumpAndSettle();

    // «Sıradakiler» satırı (Next Song): V3 şablon satırları —
    // albüm adı kuyrukta da çizilir; format satırı İKİ şablon satırında
    // da vardır (geçmiş + sıradaki), aşağıda toplam sayılmış.
    expect(find.text('Next Song'), findsOneWidget);
    expect(find.text('Nightfall'), findsOneWidget);
    expect(find.text('MP3/144kbps'), findsNWidgets(2));
    // Şablonun dışındaki kuyruk jesti: sürükleme tutamacı.
    expect(find.byIcon(Icons.drag_indicator), findsOneWidget);

    // «Son çalınanlar» bölümü de aynı şablonu kullanır (sönük).
    expect(find.text('Past Song'), findsOneWidget);
    expect(find.text('80s Classics'), findsOneWidget);

    // Şu an çalan başlığı İKİ yerde: vurgulu kart + alttaki mini
    // oynatıcı (aynı controller.currentSong'tan beslenir).
    expect(find.text('Now Song'), findsNWidgets(2));
  });

  testWidgets('sıradaki kayda dokunma playFromQueue çağırır', (tester) async {
    var calledWith = -1;
    when(() => player.playFromQueue(any())).thenAnswer((inv) async {
      calledWith = inv.positionalArguments.first as int;
      return true;
    });

    await pumpPage(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next Song'));
    await tester.pumpAndSettle();

    // Kuyruk paritesi: şablon satırının dokunması Bulgu 3 sözleşmesini
    // korur — yalnız o kayda atlama (index 2).
    expect(calledWith, 2);
  });
}
