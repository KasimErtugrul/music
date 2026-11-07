// Bulgu 3: istatistik denetleyicisi canlı senkron sözleşmesi.
//
// Sözleşme: StatsController tek seferlik yüklüyordu (onInit + setPeriod);
// çalma sırasında her ~30 sn'de bir recordPlay geçmişi değiştirdiği
// halde sayfa bayat kalıyordu. Artık watchRecentHistory yayını
// dinlenir: geçmiş değişince sönümlü SESSİZ yeniden hesap çalışır
// (isLoading'e dokunulmaz — sayfa görünürken spinner flaşı olmaz),
// dönem değişimi ise eski gibi spinner'lı loadStats'i kullanır.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/models/play_stats_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/history_repository.dart';
import 'package:resonance/data/repositories/stats_repository.dart';
import 'package:resonance/presentation/controllers/stats_controller.dart';

class _MockStatsRepository extends Mock implements StatsRepository {}
class _MockHistoryRepository extends Mock implements HistoryRepository {}

SongModel _song(int id) => SongModel(
      id: id,
      uri: 'content://media/external/audio/media/$id',
      path: '/music/$id.mp3',
      title: 'Şarkı $id',
      durationMs: 180000,
      sizeBytes: 4000000,
    );

void main() {
  late _MockStatsRepository statsRepo;
  late _MockHistoryRepository historyRepo;
  late StreamController<List<SongModel>> historyStream;

  setUpAll(() {
    registerFallbackValue(<SongModel>[]);
    registerFallbackValue('');
    registerFallbackValue(0);
    registerFallbackValue(Duration.zero);
    registerFallbackValue(DateTime(2020));
  });

  setUp(() {
    Get.testMode = true;
    statsRepo = _MockStatsRepository();
    historyRepo = _MockHistoryRepository();

    historyStream = StreamController<List<SongModel>>.broadcast();

    when(() => historyRepo.watchRecentHistory(limit: any(named: 'limit')))
        .thenAnswer((_) => historyStream.stream);
    when(() => statsRepo.getStats(since: any(named: 'since'))).thenAnswer(
      (_) async => const PlayStatsModel(
        totalPlays: 0,
        uniqueSongsPlayed: 0,
        topArtists: <String, int>{},
        topGenres: <String, int>{},
      ),
    );
    when(() => statsRepo.getRecentPlays(
          window: any(named: 'window'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => <RecentPlay>[]);
  });

  tearDown(() async {
    await historyStream.close();
    Get.reset();
  });

  Future<void> settle(StatsController ctrl) async {
    for (var i = 0; i < 500; i++) {
      if (!ctrl.isLoading.value) break;
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    // Bekleyen sıfır süreli sönüm zamanlayıcılarını boşalt.
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  StatsController build() => StatsController(
        statsRepo,
        historyRepo,
        historySyncDebounce: Duration.zero,
      )..onInit();

  group('Bulgu 3: canlı senkron', () {
    test('geçmiş yayını değişince SESSİZ yeniden hesaplar (spinner yok)',
        () async {
      final ctrl = build();
      addTearDown(ctrl.onClose);
      await settle(ctrl);
      clearInteractions(statsRepo);

      // Yeni çalma kaydı: istatistik 5, son çalmalar 1 kayıt oldu.
      final song = _song(1);
      when(() => statsRepo.getStats(since: any(named: 'since'))).thenAnswer(
        (_) async => const PlayStatsModel(
          totalPlays: 5,
          uniqueSongsPlayed: 1,
          topArtists: <String, int>{'Sanatçı': 5},
          topGenres: <String, int>{},
        ),
      );
      when(() => statsRepo.getRecentPlays(
            window: any(named: 'window'),
            limit: any(named: 'limit'),
          )).thenAnswer(
        (_) async => <RecentPlay>[
          RecentPlay(song: song, playedAt: DateTime(2026, 11, 7, 12)),
        ],
      );

      historyStream.add(<SongModel>[song]);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(ctrl.stats.value?.totalPlays, 5);
      expect(ctrl.recent.length, 1);
      // Spinner FLAŞI YOK: arka plan senkronu isLoading'e dokunmaz.
      expect(ctrl.isLoading.value, isFalse);
      // Varsayılan dönem «tüm zamanlar» → since null ile hesaplanır.
      verify(() => statsRepo.getStats(since: null)).called(1);
    });

    test('hızlı ardışık yayınlar tek hesapta birleşir (sönümleme)', () async {
      final ctrl = build();
      addTearDown(ctrl.onClose);
      await settle(ctrl);
      clearInteractions(statsRepo);

      final song = _song(1);
      // Aynı olay döngüsünde üç recordPlay yazımı.
      historyStream.add(<SongModel>[song]);
      historyStream.add(<SongModel>[song]);
      historyStream.add(<SongModel>[song]);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      verify(() => statsRepo.getStats(since: any(named: 'since'))).called(1);
      verify(() => statsRepo.getRecentPlays(
            window: any(named: 'window'),
            limit: any(named: 'limit'),
          )).called(1);
    });

    test('setPeriod pencereyi değiştirir ve spinner\'lı yüklemeyi kullanır',
        () async {
      final ctrl = build();
      addTearDown(ctrl.onClose);
      await settle(ctrl);
      clearInteractions(statsRepo);

      await ctrl.setPeriod(0); // Bu hafta

      expect(ctrl.period.value, 0);
      final captured = verify(() => statsRepo.getStats(
            since: captureAny(named: 'since'),
          )).captured.single as DateTime?;
      // Hafta başlangıcı takvim bazlı bir anlıktır, null değil.
      expect(captured, isNotNull);
    });

    test('yeniden hesap hatası sayfayı çökertmez (günlük + eski değerler)',
        () async {
      final ctrl = build();
      addTearDown(ctrl.onClose);
      await settle(ctrl);
      clearInteractions(statsRepo);

      final before = ctrl.stats.value;
      when(() => statsRepo.getStats(since: any(named: 'since')))
          .thenThrow(StateError('geçici'));

      historyStream.add(<SongModel>[_song(2)]);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Hata yutulur: eski değerler durur, sayfa yaşar.
      expect(ctrl.stats.value, same(before));
      expect(ctrl.isLoading.value, isFalse);
    });
  });

  group('Bulgu 13: dönem bayatlığı kilidi', () {
    test('yavaş hafta sorgusu, hızlı ay geçişinin sonucunu ezemez', () async {
      final ctrl = build();
      addTearDown(ctrl.onClose);
      await settle(ctrl);

      const weekStats = PlayStatsModel(
        totalPlays: 7,
        uniqueSongsPlayed: 3,
        topArtists: <String, int>{},
        topGenres: <String, int>{},
      );
      const monthStats = PlayStatsModel(
        totalPlays: 30,
        uniqueSongsPlayed: 9,
        topArtists: <String, int>{},
        topGenres: <String, int>{},
      );

      // İki getStats çağrısı sırayla iki kapıdan cevaplanır:
      // 1) hafta (yavaş — sonda tamamlanır), 2) ay (hızlı — önce biter).
      final pending = <Completer<PlayStatsModel>>[];
      var call = 0;
      when(() => statsRepo.getStats(since: any(named: 'since'))).thenAnswer(
        (_) {
          call++;
          if (call <= 2) {
            final c = Completer<PlayStatsModel>();
            pending.add(c);
            return c.future;
          }
          return Future<PlayStatsModel>.value(monthStats);
        },
      );

      final weekLoad = ctrl.setPeriod(0); // 1. çağrı: hafta, askıda kalır
      final monthLoad = ctrl.setPeriod(1); // 2. çağrı: ay, askıda kalır
      expect(pending.length, 2);

      pending[1].complete(monthStats); // ay sorgusu ÖNCE biter
      await monthLoad;
      expect(ctrl.stats.value?.totalPlays, 30);
      expect(ctrl.isLoading.value, isFalse);

      pending[0].complete(weekStats); // hafta sorgusu GEÇ biter — bayat
      await weekLoad;
      // Kilit: bayat dönem yazımı atılır, görünüm ay verisinde kalır.
      expect(ctrl.stats.value?.totalPlays, 30);
      // Spinner: bayat yükleme erken indiremez; güncel yükleme indirdi.
      expect(ctrl.isLoading.value, isFalse);
    });

    test('bekleyen loadStats varken gelen canlı senkron yazımı eskir',
        () async {
      final ctrl = build();
      addTearDown(ctrl.onClose);
      await settle(ctrl);

      // 1) Canlı senkron sorgusu askıda kalsın; 2) kullanıcının dönem
      // yüklemesi askıda kalsın; önce kullanıcı yüklensin.
      final syncGate = Completer<PlayStatsModel>();
      final monthGate = Completer<PlayStatsModel>();
      var call = 0;
      when(() => statsRepo.getStats(since: any(named: 'since'))).thenAnswer(
        (_) {
          call++;
          return call == 1 ? syncGate.future : monthGate.future;
        },
      );

      historyStream.add(<SongModel>[_song(1)]); // sönüm (0 sn) → _syncLive
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(call, 1); // canlı senkron sorgusu yolda

      final monthLoad = ctrl.setPeriod(1); // numara artar (kullanıcı kazanır)
      expect(call, 2);

      const monthStats = PlayStatsModel(
        totalPlays: 30,
        uniqueSongsPlayed: 0,
        topArtists: <String, int>{},
        topGenres: <String, int>{},
      );
      const staleSyncStats = PlayStatsModel(
        totalPlays: 7,
        uniqueSongsPlayed: 0,
        topArtists: <String, int>{},
        topGenres: <String, int>{},
      );

      monthGate.complete(monthStats);
      await monthLoad;
      expect(ctrl.stats.value?.totalPlays, 30);

      syncGate.complete(staleSyncStats); // canlı senkron GEÇ biter — bayat
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Kilit: arka plan yazımı atılır; kullanıcı döneminin verisi durur.
      expect(ctrl.stats.value?.totalPlays, 30);
    });
  });
}
